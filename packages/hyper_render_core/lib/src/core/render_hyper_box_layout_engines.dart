part of 'render_hyper_box.dart';

/// Integration layer for new refactored layout engines
///
/// This extension provides:
/// - Conversion between old (_FloatArea) and new (FloatArea) types
/// - New layout implementation using LineBreakingEngine
/// - Production monitoring and metrics collection
///
/// Part of God Object refactoring - Week 2 Integration + Week 3-4 Production Monitoring
/// See: doc/ARCHITECTURE_DEBT_GOD_OBJECT.md
extension _RenderHyperBoxLayoutEngines on RenderHyperBox {
  /// Perform line layout using NEW refactored engines
  ///
  /// This is the new implementation that delegates to:
  /// - LineBreakingEngine (pure Dart, 100% testable)
  /// - FloatLayoutCalculator (pure Dart, 100% testable)
  /// - FragmentMeasurer (abstraction over TextPainter)
  ///
  /// Returns true if successful, false if should fallback to legacy code.
  /// Week 3-4: Now includes production monitoring and metrics collection.
  bool _performLineLayoutWithNewEngines() {
    _lines.clear();
    _leftFloats.clear();
    _rightFloats.clear();

    if (_fragments.isEmpty) return true;

    // Week 3-4: Start timing for production metrics
    final timer = LayoutTimer();
    timer.start();

    // Create instances of new engines
    final lineBreaker = LineBreakingEngine(
      measurer: const FragmentMeasurer(),
      // Note: Kinsoku processing is built into the engine
    );

    // Convert fragments: Replace private fragment types with public ones
    final convertedFragments = _convertFragmentsForNewEngine();

    try {
      // Call pure Dart engine - NO Flutter dependencies in this call!
      final result = lineBreaker.breakLines(
        fragments: convertedFragments,
        maxWidth: _maxWidth,
      );

      // Convert results back to RenderHyperBox internal types
      _convertResultsFromNewEngine(result);

      // Week 3-4: Record successful layout with production monitor
      final elapsedUs = timer.stop();
      ProductionMonitor.instance.recordLayout(LayoutMetrics(
        engineType: LayoutEngineType.newEngines,
        layoutTimeUs: elapsedUs,
        fragmentCount: _fragments.length,
        lineCount: _lines.length,
        maxWidth: _maxWidth,
      ));

      return true; // Success!
    } catch (e, stackTrace) {
      // If new engine fails, log and fallback to legacy
      final elapsedUs = timer.stop();

      // Week 3-4: Record fallback event with production monitor
      ProductionMonitor.instance.recordLayout(LayoutMetrics(
        engineType: LayoutEngineType.legacyFallback,
        layoutTimeUs: elapsedUs,
        fragmentCount: _fragments.length,
        lineCount: 0, // Failed before creating lines
        maxWidth: _maxWidth,
        fallbackReason: e.toString(),
        fallbackStackTrace: stackTrace,
      ));

      debugPrint('⚠️  New layout engine failed: $e');
      debugPrint('Stack trace: $stackTrace');
      debugPrint('Falling back to legacy layout code...');
      return false; // Fallback to legacy
    }
  }

  /// Convert fragments from RenderHyperBox internal types to public types
  ///
  /// Maps:
  /// - _BlockStartFragment → BlockStartFragment
  /// - _BlockEndFragment → BlockEndFragment
  /// - _InlineStartFragment → InlineStartFragment
  /// - _InlineEndFragment → InlineEndFragment
  /// - Regular fragments → kept as-is
  List<Fragment> _convertFragmentsForNewEngine() {
    final converted = <Fragment>[];

    for (final frag in _fragments) {
      if (frag is _BlockStartFragment) {
        // Convert to public BlockStartFragment
        converted.add(BlockStartFragment(
          sourceNode: frag.sourceNode,
          style: frag.style,
          marginTop: frag.marginTop,
          paddingTop: frag.paddingTop,
          paddingLeft: frag.paddingLeft,
          paddingRight: frag.paddingRight,
        ));
      } else if (frag is _BlockEndFragment) {
        // Convert to public BlockEndFragment
        converted.add(BlockEndFragment(
          sourceNode: frag.sourceNode,
          style: frag.style,
          paddingBottom: frag.paddingBottom,
        ));
      } else if (frag is _InlineStartFragment) {
        // Convert to public InlineStartFragment
        converted.add(InlineStartFragment(
          sourceNode: frag.sourceNode,
          style: frag.style,
        ));
      } else if (frag is _InlineEndFragment) {
        // Convert to public InlineEndFragment
        converted.add(InlineEndFragment(
          sourceNode: frag.sourceNode,
          style: frag.style,
        ));
      } else {
        // Regular fragment - keep as-is
        converted.add(frag);
      }
    }

    return converted;
  }

  /// Convert results from new engine back to RenderHyperBox internal format
  ///
  /// Maps:
  /// - BreakingLineInfo → LineInfo (RenderHyperBox internal)
  /// - FloatArea (new) → _FloatArea (RenderHyperBox internal)
  void _convertResultsFromNewEngine(LineBreakingResult result) {
    // Convert lines
    for (final breakingLine in result.lines) {
      final lineInfo = LineInfo(
        top: breakingLine.top,
        baseline: breakingLine.baseline,
        leftInset: breakingLine.leftInset,
        rightInset: breakingLine.rightInset,
      );

      // Copy fragments to line
      for (final frag in breakingLine.fragments) {
        lineInfo.add(frag);
      }

      // Set bounds
      lineInfo.bounds = breakingLine.bounds;

      _lines.add(lineInfo);
    }

    // Convert left floats
    for (final floatArea in result.leftFloats) {
      _leftFloats.add(_FloatArea(
        rect: floatArea.rect,
        direction: HyperFloat.left,
      ));
    }

    // Convert right floats
    for (final floatArea in result.rightFloats) {
      _rightFloats.add(_FloatArea(
        rect: floatArea.rect,
        direction: HyperFloat.right,
      ));
    }
  }
}
