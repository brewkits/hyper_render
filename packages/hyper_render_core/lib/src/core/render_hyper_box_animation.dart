part of 'render_hyper_box.dart';

/// Runtime progress for a single node's canvas-painted CSS `animation-name`.
///
/// Progress is tracked as elapsed wall-clock time rather than mirroring
/// [AnimationController] (which the widget-tier [HyperAnimatedWidget] uses)
/// because a [RenderObject] cannot own a [TickerProvider] without an
/// API-breaking change to [RenderHyperBox] — see the "Shimmer Animation"
/// section of render_hyper_box.dart for the same trade-off already accepted
/// for the image-loading shimmer. [_currentKeyframe] derives the interpolated
/// frame purely from `now - epoch + accumulated`, so pausing/resuming is just
/// freezing/unfreezing that clock — no separate iteration bookkeeping needed.
class _BlockAnimationState {
  HyperKeyframes keyframes;
  int durationMs;
  int delayMs;
  int? iterationCount; // null = infinite
  HyperAnimationDirection direction;
  HyperTimingFunction timingFunction;
  HyperTimingParams? timingParams;
  HyperAnimationPlayState playState;

  /// Frame timestamp when the current running segment began; `null` while
  /// paused or before the animation has ever started running.
  Duration? epoch;

  /// Elapsed time banked from previous running segments — frozen the moment
  /// [playState] becomes paused, resumed by re-stamping [epoch]. Always
  /// starts at zero for a freshly-created state; mutated afterwards by
  /// [_RenderHyperBoxAnimation._syncBlockAnimation].
  Duration accumulated = Duration.zero;

  /// Set once a finite (`iterationCount != null`) animation has played all
  /// its iterations. The block then holds its final frame indefinitely
  /// (matches the existing widget-tier [HyperAnimatedWidget] behaviour,
  /// which also parks at the end value rather than reverting to the
  /// unanimated style). Always starts `false`; mutated by [_currentKeyframe].
  bool finished = false;

  _BlockAnimationState({
    required this.keyframes,
    required this.durationMs,
    required this.delayMs,
    required this.iterationCount,
    required this.direction,
    required this.timingFunction,
    required this.timingParams,
    required this.playState,
    this.epoch,
  });

  /// Whether the animation *definition* (everything except play state and
  /// runtime progress) is unchanged, so in-flight progress should carry over
  /// across a [performLayout] rebuild instead of restarting from zero.
  bool sameDefinitionAs({
    required HyperKeyframes keyframes,
    required int durationMs,
    required int delayMs,
    required int? iterationCount,
    required HyperAnimationDirection direction,
    required HyperTimingFunction timingFunction,
    required HyperTimingParams? timingParams,
  }) {
    return this.keyframes == keyframes &&
        this.durationMs == durationMs &&
        this.delayMs == delayMs &&
        this.iterationCount == iterationCount &&
        this.direction == direction &&
        this.timingFunction == timingFunction &&
        this.timingParams == timingParams;
  }
}

extension _RenderHyperBoxAnimation on RenderHyperBox {
  /// Walks the document for nodes with a resolvable `animation-name` and
  /// syncs [_blockAnimations] to match. Cheap relative to the rest of
  /// [performLayout] (one tree walk, same cost class as tokenization) and
  /// only runs on layout — not on every animation-driven paint frame.
  void _rebuildBlockAnimations() {
    if (_document == null) {
      if (_blockAnimations.isNotEmpty) _blockAnimations.clear();
      _animatedAncestorCache.clear();
      return;
    }

    final registry = _config.keyframeRegistry;
    final now = SchedulerBinding.instance.currentFrameTimeStamp;
    final seen = <UDTNode>{};

    void visit(UDTNode node) {
      final resolved =
          resolveHyperKeyframes(node.style.animationName, registry);
      if (resolved != null) {
        seen.add(node);
        _syncBlockAnimation(node, resolved, now);
      }
      for (final child in node.children) {
        visit(child);
      }
    }

    visit(_document!);

    _blockAnimations.removeWhere((node, _) => !seen.contains(node));
    _animatedAncestorCache.clear();

    // Gate on "anything actually running", not just "map non-empty" — a
    // block that is entirely paused (or already finished) must not re-arm
    // the frame loop just because performLayout happened to run again for
    // an unrelated reason (e.g. a sibling's text reflowing).
    if (_hasActiveBlockAnimations) {
      _ensureBlockAnimationsRunning();
    }
  }

  bool get _hasActiveBlockAnimations => _blockAnimations.values.any(
      (s) => s.playState == HyperAnimationPlayState.running && !s.finished);

  void _syncBlockAnimation(
      UDTNode node, HyperKeyframes resolved, Duration now) {
    final style = node.style;
    // Unset animation-duration defaults to 300ms (not the CSS-spec 0s) to
    // match HyperAnimatedWidget.fromStyle's existing widget-tier default —
    // otherwise the same markup would visibly animate at the widget tier but
    // snap instantly on the canvas tier.
    final durationMs = style.animationDuration ?? 300;
    final delayMs = style.animationDelay ?? 0;
    final iterationCount = style.animationIterationCount;
    final direction = style.animationDirection;
    final timingFunction = style.animationTimingFunction;
    final timingParams = style.animationTimingParams;
    final playState = style.animationPlayState;

    final existing = _blockAnimations[node];
    if (existing != null &&
        existing.sameDefinitionAs(
          keyframes: resolved,
          durationMs: durationMs,
          delayMs: delayMs,
          iterationCount: iterationCount,
          direction: direction,
          timingFunction: timingFunction,
          timingParams: timingParams,
        )) {
      if (existing.playState != playState) {
        if (playState == HyperAnimationPlayState.paused) {
          if (existing.epoch != null) {
            existing.accumulated += now - existing.epoch!;
            existing.epoch = null;
          }
        } else {
          existing.epoch ??= now;
        }
        existing.playState = playState;
      }
      return;
    }

    // New node, or its animation definition changed underneath it — fresh
    // runtime state (mirrors HyperAnimatedWidget.didUpdateWidget rebuilding
    // its AnimationController when the definition changes).
    _blockAnimations[node] = _BlockAnimationState(
      keyframes: resolved,
      durationMs: durationMs,
      delayMs: delayMs,
      iterationCount: iterationCount,
      direction: direction,
      timingFunction: timingFunction,
      timingParams: timingParams,
      playState: playState,
      epoch: playState == HyperAnimationPlayState.running ? now : null,
    );
  }

  /// Computes the currently-interpolated [HyperKeyframe] for [state], or
  /// `null` while still within the `animation-delay` window — the caller
  /// should paint the block with its normal static style in that case.
  HyperKeyframe? _currentKeyframe(_BlockAnimationState state, Duration now) {
    final runningElapsed = state.playState == HyperAnimationPlayState.running &&
            state.epoch != null
        ? now - state.epoch!
        : Duration.zero;
    final totalElapsedMs =
        state.accumulated.inMilliseconds + runningElapsed.inMilliseconds;

    if (totalElapsedMs < state.delayMs) return null;

    final durationMs = state.durationMs > 0 ? state.durationMs : 1;
    final activeMs = totalElapsedMs - state.delayMs;

    int iterationIndex = activeMs ~/ durationMs;
    double localT;
    final maxIterations = state.iterationCount;
    if (maxIterations != null && iterationIndex >= maxIterations) {
      state.finished = true;
      iterationIndex = maxIterations - 1;
      localT = 1.0;
    } else {
      localT =
          state.durationMs > 0 ? (activeMs % durationMs) / durationMs : 1.0;
    }

    final reversedIteration = switch (state.direction) {
      HyperAnimationDirection.normal => false,
      HyperAnimationDirection.reverse => true,
      HyperAnimationDirection.alternate => iterationIndex.isOdd,
      HyperAnimationDirection.alternateReverse => iterationIndex.isEven,
    };
    final effectiveT =
        (reversedIteration ? 1.0 - localT : localT).clamp(0.0, 1.0).toDouble();

    final curve =
        curveFromHyperTiming(state.timingFunction, state.timingParams);
    return state.keyframes.interpolate(curve.transform(effectiveT));
  }

  /// Returns the nearest ancestor (including [node] itself) that currently
  /// has an entry in [_blockAnimations], or `null` if none. Memoized per
  /// layout in [_animatedAncestorCache] — a document with N animated blocks
  /// out of M total nodes would otherwise re-walk `.parent` chains for every
  /// fragment on every paint frame.
  UDTNode? _nearestAnimatedAncestor(UDTNode node) {
    final cached = _animatedAncestorCache[node];
    if (cached != null || _animatedAncestorCache.containsKey(node)) {
      return cached;
    }
    UDTNode? result;
    if (_blockAnimations.containsKey(node)) {
      result = node;
    } else {
      final parent = node.parent;
      result = parent == null ? null : _nearestAnimatedAncestor(parent);
    }
    _animatedAncestorCache[node] = result;
    return result;
  }

  /// Precomputes, once per layout pass, each animated block's paint rect and
  /// the fragments it owns. Called after line layout/positioning so
  /// [_blockDecorations] and fragment offsets are current; paint frames then
  /// reuse these lists instead of re-scanning [_lines] every tick.
  void _recomputeAnimatedBlockGeometry() {
    _animatedBlockRects.clear();
    _animatedBlockFragments.clear();
    _animatedBlockDecorations.clear();
    if (_blockAnimations.isEmpty) return;

    for (final decoration in _blockDecorations) {
      if (_blockAnimations.containsKey(decoration.node)) {
        _animatedBlockRects[decoration.node] = decoration.rect;
        _animatedBlockDecorations[decoration.node] = decoration;
      }
    }

    for (final line in _lines) {
      for (final fragment in line.fragments) {
        final owner = _nearestAnimatedAncestor(fragment.sourceNode);
        if (owner == null) continue;
        (_animatedBlockFragments[owner] ??= []).add(fragment);
        final r = fragment.rect;
        if (r == null) continue;
        final existing = _animatedBlockRects[owner];
        _animatedBlockRects[owner] =
            existing == null ? r : existing.expandToInclude(r);
      }
    }
  }

  // ============================================
  // Block Animation Frame Loop
  // ============================================
  //
  // Mirrors the shimmer loop's architecture (SchedulerBinding frame callback,
  // no TickerProvider) but its stop condition is harder: shimmer terminates
  // itself once every image finishes loading, while `animation-iteration-
  // count: infinite` never terminates on its own. The loop below keeps
  // scheduling as long as any block is both `running` and not yet
  // `finished`; it stops ticking for paused or exhausted-finite animations
  // without needing an explicit unsubscribe from the caller.

  void _ensureBlockAnimationsRunning() {
    if (_animCallbackId != null) return;
    _animCallbackId =
        SchedulerBinding.instance.scheduleFrameCallback(_onBlockAnimationTick);
  }

  void _onBlockAnimationTick(Duration timestamp) {
    _animCallbackId = null;
    if (!attached) return;
    markNeedsPaint();

    if (_hasActiveBlockAnimations) {
      _animCallbackId = SchedulerBinding.instance
          .scheduleFrameCallback(_onBlockAnimationTick);
    }
  }

  void _cancelBlockAnimationLoop() {
    if (_animCallbackId != null) {
      SchedulerBinding.instance.cancelFrameCallbackWithId(_animCallbackId!);
      _animCallbackId = null;
    }
  }
}
