part of 'render_hyper_box.dart';

extension _RenderHyperBoxPaint on RenderHyperBox {
  /// Paints every currently-animating block (CSS `animation-name` resolved
  /// via [_blockAnimations]) as a single composited unit: its own decoration
  /// plus the text fragments it owns, transformed and faded together.
  ///
  /// Painting decoration and text as one unit — rather than fading each
  /// separately in the normal per-pass painting below — matters for
  /// `opacity`: fading a block's background and its text independently
  /// double-blends wherever they overlap (the half-transparent text would
  /// show the half-transparent background showing through it a second
  /// time). `saveLayer` with a single alpha-only [Paint] composites this
  /// block's content first, then applies the fade once to the result.
  ///
  /// V1 scope: only this node's own block decoration and its directly-owned
  /// text/ruby fragments participate. List markers, inline decorations
  /// (backgrounds/borders on inline `<span>`-like elements), floated images,
  /// and a *nested* animated descendant's own animation do not compose with
  /// an animating ancestor's transform/opacity — each still paints via the
  /// normal per-pass logic below, which is documented behaviour for now
  /// rather than an oversight (see ROADMAP.md).
  ///
  /// One consequence worth calling out explicitly rather than leaving
  /// implicit: this pass runs *before* [_paintInlineDecorations] (step 1 in
  /// [paint]), so an inline `<span style="background:...">` inside an
  /// animated block paints its background on top of this pass's
  /// already-painted animated text — not just "un-animated", but visibly
  /// covering it. Avoid combining `animation-name` on a block with inline
  /// decorations on its descendants until a future pass folds inline
  /// decorations into this same composited layer.
  void _paintAnimatedBlocks(Canvas canvas, Offset offset) {
    _paintedThisFrameByAnimation.clear();
    if (_blockAnimations.isEmpty) return;

    final now = SchedulerBinding.instance.currentFrameTimeStamp;

    for (final entry in _blockAnimations.entries) {
      final node = entry.key;
      final keyframe = _currentKeyframe(entry.value, now);
      // Still within animation-delay — fall through to normal static paint.
      if (keyframe == null) continue;

      final rect = _animatedBlockRects[node];
      // Nothing laid out for this node this pass (e.g. display:none, or a
      // node with no decoration and no text content of its own).
      if (rect == null) continue;

      _paintedThisFrameByAnimation.add(node);

      final paintRect = rect.shift(offset);
      final opacity = (keyframe.opacity ?? 1.0).clamp(0.0, 1.0);
      final needsOpacityLayer = opacity < 1.0;
      final transform = matrix4FromHyperKeyframe(keyframe);
      final needsTransform = !transform.isIdentity();

      final decoration = _animatedBlockDecorations[node];

      canvas.save();
      // ORDER MATTERS: the transform is applied BEFORE saveLayer, so the
      // layer bounds below can be this block's own rect.
      //
      // saveLayer bounds are interpreted in the CURRENT coordinate space. Once
      // the transform is in effect, the content coordinates (paintRect and the
      // fragment offsets) live in that same space, so `paintRect` covers the
      // content exactly — and the offscreen buffer Skia allocates is only the
      // area this block actually occupies on screen.
      //
      // Doing it the other way round (saveLayer first) forces bounds of `null`,
      // because a pre-transform rect would clip a translated/scaled block to
      // where it *used* to be. `null` means "current clip" — i.e. the whole
      // RenderHyperBox — so a single small `animation: fade … infinite` block
      // in a long document allocated a document-sized buffer every frame.
      if (needsTransform) {
        final pivot = paintRect.center;
        canvas.translate(pivot.dx, pivot.dy);
        canvas.transform(transform.storage);
        canvas.translate(-pivot.dx, -pivot.dy);
      }
      if (needsOpacityLayer) {
        canvas.saveLayer(
          _animatedLayerBounds(paintRect, decoration),
          Paint()..color = Color.fromRGBO(0, 0, 0, opacity),
        );
      }

      if (decoration != null) {
        _paintOneBlockDecoration(canvas, offset, decoration,
            backgroundColorOverride: keyframe.backgroundColor);
      }

      final fragments = _animatedBlockFragments[node];
      if (fragments != null) {
        for (final fragment in fragments) {
          if (fragment.type == FragmentType.text && fragment.text != null) {
            _paintTextFragment(canvas, offset, fragment,
                colorOverride: keyframe.color);
          } else if (fragment.type == FragmentType.ruby) {
            _paintRubyFragment(canvas, offset, fragment,
                colorOverride: keyframe.color);
          }
        }
      }

      if (needsOpacityLayer) canvas.restore(); // matches saveLayer
      canvas.restore(); // matches outer save
    }
  }

  /// Paint bounds for an animated block's opacity layer.
  ///
  /// Starts from the block's content rect and grows it to cover anything drawn
  /// outside that rect — currently `box-shadow`, whose offset/spread/blur can
  /// extend well past the box. Clipping those away would be a visible
  /// regression, so they are measured rather than guessed at.
  ///
  /// The final small inflate absorbs antialiasing and glyph overhang (italics,
  /// underlines, text shadows) that can bleed a fraction of a pixel past the
  /// measured text rect.
  Rect _animatedLayerBounds(Rect paintRect, _BlockDecoration? decoration) {
    var bounds = paintRect;
    final shadows = decoration?.boxShadow;
    if (shadows != null) {
      for (final s in shadows) {
        bounds = bounds.expandToInclude(
          paintRect.shift(s.offset).inflate(s.spreadRadius + s.blurRadius),
        );
      }
    }
    return bounds.inflate(2.0);
  }

  void _paintBlockDecorations(Canvas canvas, Offset offset) {
    for (final decoration in _blockDecorations) {
      // Animated blocks are painted (with their interpolated keyframe
      // overrides) by _paintAnimatedBlocks instead — skip here so they're
      // not drawn twice at their static style.
      if (_paintedThisFrameByAnimation.contains(decoration.node)) continue;
      _paintOneBlockDecoration(canvas, offset, decoration);
    }
  }

  /// Paints a single block decoration (background, border, shadow, filters).
  /// Factored out of [_paintBlockDecorations] so [_paintAnimatedBlocks] can
  /// reuse the exact same drawing logic with a keyframe-overridden
  /// [backgroundColorOverride] instead of duplicating ~90 lines of
  /// border/shadow/gradient handling.
  void _paintOneBlockDecoration(
    Canvas canvas,
    Offset offset,
    _BlockDecoration decoration, {
    Color? backgroundColorOverride,
  }) {
    // PIXEL SNAPPING: Rounding coordinates to physical pixel boundaries ensures
    // perfectly sharp edges on high-DPI displays (Retina/Amoled).
    // This eliminates the 'blurry border' effect common in custom renderers.
    final rawRect = decoration.rect.shift(offset);
    final adjustedRect = Rect.fromLTRB(
      rawRect.left.roundToDouble(),
      rawRect.top.roundToDouble(),
      rawRect.right.roundToDouble(),
      rawRect.bottom.roundToDouble(),
    );

    // 1. Backdrop Filter (Glassmorphism) - Paints BEFORE background
    if (decoration.backdropFilter != null && enableComplexFilters) {
      canvas.saveLayer(adjustedRect, _sLayerPaint);
      _filterPaint
        ..imageFilter = decoration.backdropFilter
        ..blendMode = BlendMode.srcOver;
      canvas.drawRect(adjustedRect, _filterPaint);
      _filterPaint
        ..imageFilter = null
        ..blendMode = BlendMode.srcOver;
      canvas.restore();
    }

    // 2. Filter (blur, etc.)
    if (decoration.filter != null && enableComplexFilters) {
      _filterPaint.imageFilter = decoration.filter;
      canvas.saveLayer(adjustedRect, _filterPaint);
      _filterPaint.imageFilter = null;
    }

    // 3. Box shadows
    if (decoration.boxShadow != null) {
      for (final shadow in decoration.boxShadow!) {
        final shadowPaint = shadow.toPaint();
        // Shadow rects don't need strict snapping as they are naturally blurred
        final shadowRect =
            adjustedRect.shift(shadow.offset).inflate(shadow.spreadRadius);

        if (decoration.borderRadius != null) {
          canvas.drawRRect(
            RRect.fromRectAndCorners(
              shadowRect,
              topLeft: decoration.borderRadius!.topLeft,
              topRight: decoration.borderRadius!.topRight,
              bottomLeft: decoration.borderRadius!.bottomLeft,
              bottomRight: decoration.borderRadius!.bottomRight,
            ),
            shadowPaint,
          );
        } else {
          canvas.drawRect(shadowRect, shadowPaint);
        }
      }
    }

    // Paint background or gradient if specified
    final backgroundColor =
        backgroundColorOverride ?? decoration.backgroundColor;
    if (backgroundColor != null || decoration.backgroundGradient != null) {
      // An animated background-color override always wins over a gradient —
      // matches the widget-tier HyperAnimatedWidget, which also only
      // animates a flat background-color, never a gradient.
      if (decoration.backgroundGradient != null &&
          backgroundColorOverride == null) {
        _fillPaint.shader =
            decoration.backgroundGradient!.createShader(adjustedRect);
        _fillPaint.color =
            const Color(0x00000000); // reset color (unused when shader set)
      } else {
        _fillPaint.shader = null;
        _fillPaint.color = backgroundColor!;
      }

      if (decoration.borderRadius != null) {
        canvas.drawRRect(
          RRect.fromRectAndCorners(
            adjustedRect,
            topLeft: decoration.borderRadius!.topLeft,
            topRight: decoration.borderRadius!.topRight,
            bottomLeft: decoration.borderRadius!.bottomLeft,
            bottomRight: decoration.borderRadius!.bottomRight,
          ),
          _fillPaint,
        );
      } else {
        canvas.drawRect(adjustedRect, _fillPaint);
      }
      _fillPaint.shader = null; // reset shader so next fill uses color
    }

    // Paint border — either full-box (all 4 sides) or left-only (blockquote)
    if (decoration.borderLeftColor != null && decoration.borderLeftWidth > 0) {
      if (decoration.fullBorder) {
        _paintFullBoxBorder(
          canvas,
          adjustedRect,
          decoration.borderLeftColor!,
          decoration.borderLeftWidth,
          decoration.borderStyle,
          decoration.borderRadius,
        );
      } else {
        // Left-only border (blockquote style) — draw as filled rect for precision.
        _fillPaint.color = decoration.borderLeftColor!;
        canvas.drawRect(
          Rect.fromLTWH(
            adjustedRect.left,
            adjustedRect.top,
            decoration.borderLeftWidth.roundToDouble(),
            adjustedRect.height,
          ),
          _fillPaint,
        );
      }
    }

    // Restore layer if filter was applied
    if (decoration.filter != null && enableComplexFilters) {
      canvas.restore();
    }
  }

  void _paintInlineDecorations(Canvas canvas, Offset offset) {
    for (final decoration in _inlineDecorations) {
      for (final rect in decoration.rects) {
        final rawRect = rect.shift(offset);
        final adjustedRect = Rect.fromLTRB(
          rawRect.left.roundToDouble(),
          rawRect.top.roundToDouble(),
          rawRect.right.roundToDouble(),
          rawRect.bottom.roundToDouble(),
        );

        // 1. Backdrop Filter
        if (decoration.style.backdropFilter != null && enableComplexFilters) {
          canvas.saveLayer(adjustedRect, _sLayerPaint);
          _filterPaint.imageFilter = decoration.style.backdropFilter;
          canvas.drawRect(adjustedRect, _filterPaint);
          _filterPaint.imageFilter = null;
          canvas.restore();
        }

        // 2. Filter (blur, etc.)
        if (decoration.style.filter != null && enableComplexFilters) {
          _filterPaint.imageFilter = decoration.style.filter;
          canvas.saveLayer(adjustedRect, _filterPaint);
          _filterPaint.imageFilter = null;
        }

        // 3. Box shadows
        if (decoration.style.boxShadow != null) {
          for (final shadow in decoration.style.boxShadow!) {
            final shadowPaint = shadow.toPaint();
            final shadowRect =
                adjustedRect.shift(shadow.offset).inflate(shadow.spreadRadius);

            if (decoration.style.borderRadius != null) {
              canvas.drawRRect(
                RRect.fromRectAndCorners(
                  shadowRect,
                  topLeft: decoration.style.borderRadius!.topLeft,
                  topRight: decoration.style.borderRadius!.topRight,
                  bottomLeft: decoration.style.borderRadius!.bottomLeft,
                  bottomRight: decoration.style.borderRadius!.bottomRight,
                ),
                shadowPaint,
              );
            } else {
              canvas.drawRect(shadowRect, shadowPaint);
            }
          }
        }

        // Paint background or gradient
        if (decoration.style.backgroundColor != null ||
            decoration.style.backgroundGradient != null) {
          if (decoration.style.backgroundGradient != null) {
            _fillPaint.shader =
                decoration.style.backgroundGradient!.createShader(adjustedRect);
            _fillPaint.color = const Color(0x00000000);
          } else {
            _fillPaint.shader = null;
            _fillPaint.color = decoration.style.backgroundColor!;
          }

          if (decoration.style.borderRadius != null) {
            canvas.drawRRect(
              RRect.fromRectAndCorners(
                adjustedRect,
                topLeft: decoration.style.borderRadius!.topLeft,
                topRight: decoration.style.borderRadius!.topRight,
                bottomLeft: decoration.style.borderRadius!.bottomLeft,
                bottomRight: decoration.style.borderRadius!.bottomRight,
              ),
              _fillPaint,
            );
          } else {
            canvas.drawRect(adjustedRect, _fillPaint);
          }
          _fillPaint.shader = null;
        }

        // Paint border
        if (decoration.style.borderColor != null &&
            decoration.style.borderWidth > 0) {
          // deflate(width/2) places the stroke centerline on the snapped edge.
          final borderRect =
              adjustedRect.deflate(decoration.style.borderWidth / 2);
          _strokePaint
            ..color = decoration.style.borderColor!
            ..strokeWidth = decoration.style.borderWidth
            ..strokeCap = StrokeCap.square;

          if (decoration.style.borderRadius != null) {
            canvas.drawRRect(
              RRect.fromRectAndCorners(
                borderRect,
                topLeft: decoration.style.borderRadius!.topLeft,
                topRight: decoration.style.borderRadius!.topRight,
                bottomLeft: decoration.style.borderRadius!.bottomLeft,
                bottomRight: decoration.style.borderRadius!.bottomRight,
              ),
              _strokePaint,
            );
          } else {
            canvas.drawRect(borderRect, _strokePaint);
          }
        }

        // Restore layer if filter was applied
        if (decoration.style.filter != null && enableComplexFilters) {
          canvas.restore();
        }
      }
    }
  }

  /// Paint a full-box border on all 4 sides with the given style.
  void _paintFullBoxBorder(
    Canvas canvas,
    Rect rect,
    Color color,
    double width,
    HyperBorderStyle style,
    BorderRadius? borderRadius,
  ) {
    switch (style) {
      case HyperBorderStyle.none:
        return;

      case HyperBorderStyle.dashed:
        _paintDashedBoxBorder(canvas, rect, color, width, borderRadius);

      case HyperBorderStyle.dotted:
        _paintDottedBoxBorder(canvas, rect, color, width, borderRadius);

      case HyperBorderStyle.double:
        _paintDoubleBoxBorder(canvas, rect, color, width, borderRadius);

      case HyperBorderStyle.solid:
      case HyperBorderStyle.groove:
      case HyperBorderStyle.ridge:
      case HyperBorderStyle.inset:
      case HyperBorderStyle.outset:
        // Solid (and unsupported 3D styles rendered as solid)
        _strokePaint
          ..color = color
          ..strokeWidth = width
          ..strokeCap = StrokeCap.square;
        final innerRect = rect.deflate(width / 2);
        if (borderRadius != null) {
          canvas.drawRRect(
            RRect.fromRectAndCorners(
              innerRect,
              topLeft: borderRadius.topLeft,
              topRight: borderRadius.topRight,
              bottomLeft: borderRadius.bottomLeft,
              bottomRight: borderRadius.bottomRight,
            ),
            _strokePaint,
          );
        } else {
          canvas.drawRect(innerRect, _strokePaint);
        }
    }
  }

  /// Draw a dashed border around a rect.
  void _paintDashedBoxBorder(Canvas canvas, Rect rect, Color color,
      double width, BorderRadius? borderRadius) {
    _strokePaint
      ..color = color
      ..strokeWidth = width
      ..strokeCap = StrokeCap.butt;
    final paint = _strokePaint;

    final dashLen = math.max(4.0, width * 3);
    final gapLen = math.max(3.0, width * 2);
    final innerRect = rect.deflate(width / 2);

    final path = Path();
    if (borderRadius != null) {
      path.addRRect(RRect.fromRectAndCorners(
        innerRect,
        topLeft: borderRadius.topLeft,
        topRight: borderRadius.topRight,
        bottomLeft: borderRadius.bottomLeft,
        bottomRight: borderRadius.bottomRight,
      ));
    } else {
      path.addRect(innerRect);
    }
    _drawDashedPath(canvas, path, paint, dashLen, gapLen);
  }

  /// Draw a dotted border around a rect.
  void _paintDottedBoxBorder(Canvas canvas, Rect rect, Color color,
      double width, BorderRadius? borderRadius) {
    _strokePaint
      ..color = color
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round; // Round caps give dot appearance
    final paint = _strokePaint;

    const dashLen = 0.01; // Nearly zero length with round cap = dot
    final gapLen = math.max(2.0, width * 2);
    final innerRect = rect.deflate(width / 2);

    final path = Path();
    if (borderRadius != null) {
      path.addRRect(RRect.fromRectAndCorners(
        innerRect,
        topLeft: borderRadius.topLeft,
        topRight: borderRadius.topRight,
        bottomLeft: borderRadius.bottomLeft,
        bottomRight: borderRadius.bottomRight,
      ));
    } else {
      path.addRect(innerRect);
    }
    _drawDashedPath(canvas, path, paint, dashLen, gapLen);
  }

  /// Draw a double border — two concentric lines with a gap between them.
  void _paintDoubleBoxBorder(Canvas canvas, Rect rect, Color color,
      double width, BorderRadius? borderRadius) {
    final lineWidth = (width / 3).clamp(1.0, double.infinity);
    _strokePaint
      ..color = color
      ..strokeWidth = lineWidth
      ..strokeCap = StrokeCap.square;
    final paint = _strokePaint;

    // Outer line: center at rect edge inset by lineWidth/2
    final outerInset = lineWidth / 2;
    final outerRect = rect.deflate(outerInset);
    // Inner line: center inset by (lineWidth + gap + lineWidth/2)
    final innerInset =
        lineWidth * 2.5; // lineWidth + gap(lineWidth) + lineWidth/2
    final innerRect = rect.deflate(innerInset);

    if (borderRadius != null) {
      canvas.drawRRect(
        RRect.fromRectAndCorners(outerRect,
            topLeft: borderRadius.topLeft,
            topRight: borderRadius.topRight,
            bottomLeft: borderRadius.bottomLeft,
            bottomRight: borderRadius.bottomRight),
        paint,
      );
      canvas.drawRRect(
        RRect.fromRectAndCorners(innerRect,
            topLeft: borderRadius.topLeft,
            topRight: borderRadius.topRight,
            bottomLeft: borderRadius.bottomLeft,
            bottomRight: borderRadius.bottomRight),
        paint,
      );
    } else {
      canvas.drawRect(outerRect, paint);
      canvas.drawRect(innerRect, paint);
    }
  }

  /// Trace a [path] drawing dashes of [dashLen] separated by [gapLen].
  void _drawDashedPath(
      Canvas canvas, Path path, Paint paint, double dashLen, double gapLen) {
    final pathMetrics = path.computeMetrics();
    for (final metric in pathMetrics) {
      double distance = 0;
      bool drawing = true;
      while (distance < metric.length) {
        final segLen = drawing ? dashLen : gapLen;
        final end = (distance + segLen).clamp(0.0, metric.length);
        if (drawing) {
          canvas.drawPath(metric.extractPath(distance, end), paint);
        }
        distance += segLen;
        drawing = !drawing;
      }
    }
  }

  void _paintSelection(Canvas canvas, Offset offset) {
    // Determine selection color:
    // 1. Explicit color passed from HyperViewer
    // 2. Adaptive default based on platform
    final selectionColor = _selectionColor ??
        (defaultTargetPlatform == TargetPlatform.iOS ||
                defaultTargetPlatform == TargetPlatform.macOS
            ? const Color(0x40007AFF) // iOS / macOS blue at 25% opacity
            : const Color(0x404285F4)); // Material 3 blue at 25% opacity

    final selectionPaint = Paint()
      ..color = selectionColor
      ..isAntiAlias = true;

    // 2 px radius on each selected box — matches Safari/iOS selection style.
    // Subtle enough not to look out of place on non-round content, but removes
    // the "spreadsheet cell" feel of perfectly sharp corners.
    const selectionRadius = Radius.circular(2.0);

    for (final line in _lines) {
      // Accumulate all highlight rects for this line into a single Path so
      // that adjacent boxes merge cleanly (no hairline gap between them) and
      // the whole line is drawn with a single canvas call.
      Path? linePath;

      for (final fragment in line.fragments) {
        if (fragment.type == FragmentType.text && fragment.text != null) {
          final fragmentStart = fragment.globalOffset;
          final fragmentEnd = fragmentStart + fragment.text!.length;

          // Check if this fragment overlaps with selection
          if (fragmentEnd > _selection!.start &&
              fragmentStart < _selection!.end) {
            final selectStart = math.max(0, _selection!.start - fragmentStart);
            final selectEnd = math.min(
                fragment.text!.length, _selection!.end - fragmentStart);

            // Trim leading/trailing whitespace for visual highlight only.
            // HTML whitespace normalization creates space chars at inline
            // element boundaries (e.g. " は、" or "を "). These spaces are
            // preserved in the selection range for copy-paste, but should not
            // produce blank margin inside the painted highlight rect.
            // Exception: preformatted content (pre/pre-wrap) where indent
            // spaces are meaningful and must be visually highlighted.
            final text = fragment.text!;
            int visualStart = selectStart;
            int visualEnd = selectEnd;
            final ws = fragment.style.whiteSpace;
            final isPreformatted =
                ws == 'pre' || ws == 'pre-wrap' || ws == 'break-spaces';
            if (!isPreformatted) {
              while (visualStart < visualEnd && text[visualStart] == ' ') {
                visualStart++;
              }
              while (visualEnd > visualStart && text[visualEnd - 1] == ' ') {
                visualEnd--;
              }
            }

            if (visualStart >= visualEnd) {
              continue;
            }

            // Use getBoxesForSelection with tight height/width to get exact
            // glyph bounds — avoids blank space from line-height above/below.
            final painter = _getTextPainter(text, fragment.style);
            final boxes = painter.getBoxesForSelection(
              TextSelection(baseOffset: visualStart, extentOffset: visualEnd),
              boxHeightStyle: ui.BoxHeightStyle.tight,
            );

            final fragmentOffset = fragment.offset ?? Offset.zero;
            for (final box in boxes) {
              if (box.right <= box.left) continue;
              // PIXEL SNAPPING: Selection rects should be sharp to match text glyphs.
              final rect = Rect.fromLTRB(
                (offset.dx + fragmentOffset.dx + box.left).roundToDouble(),
                (offset.dy + fragmentOffset.dy + box.top).roundToDouble(),
                (offset.dx + fragmentOffset.dx + box.right).roundToDouble(),
                (offset.dy + fragmentOffset.dy + box.bottom).roundToDouble(),
              );

              // Path.combine FIX: Replace PathOperation.union (CPU-side CSG)
              // with a single Path that accumulates addRRect calls.
              // Path.combine computed full boolean geometry every frame (~60–120
              // Hz during handle drag), causing significant UI-thread load on
              // complex documents or Flutter Web (CanvasKit).
              // addRRect is O(1) and defers all compositing to the GPU.
              // Adjacent boxes from the same fragment are non-overlapping
              // (TextPainter guarantees disjoint box rects), so the hairline
              // gap concern only applies across styled fragment boundaries
              // (at most 1 px), which is visually negligible.
              linePath ??= Path();
              linePath.addRRect(RRect.fromRectAndRadius(rect, selectionRadius));
            }
          }
        } else if (fragment.type == FragmentType.ruby &&
            fragment.text != null) {
          // Ruby fragments contribute to character offset and get a full-rect
          // highlight covering both the annotation and the base text.
          final fragmentStart = fragment.globalOffset;
          final fragmentEnd = fragmentStart + fragment.text!.length;

          if (fragmentEnd > _selection!.start &&
              fragmentStart < _selection!.end) {
            final fragmentOffset = fragment.offset ?? Offset.zero;
            final rect = Rect.fromLTWH(
              (offset.dx + fragmentOffset.dx).roundToDouble(),
              (offset.dy + fragmentOffset.dy).roundToDouble(),
              fragment.width.roundToDouble(),
              fragment.height.roundToDouble(),
            );
            linePath ??= Path();
            linePath.addRRect(RRect.fromRectAndRadius(rect, selectionRadius));
          }
        }
      }

      // Draw the whole line's highlight as one path — one canvas call per line
      // instead of one per text box.
      if (linePath != null) {
        canvas.drawPath(linePath, selectionPaint);
      }
    }
  }

  void _paintTextFragments(Canvas canvas, Offset offset) {
    // Get visible area in local coordinates to perform line-level culling.
    // shift(-offset) converts the global clip bounds to the RenderBox's local
    // coordinate space so we can compare directly against line.bounds.
    final visibleRect = canvas.getLocalClipBounds().shift(-offset);

    // First paint list markers
    for (final fragment in _fragments) {
      if (fragment is _ListMarkerFragment && fragment.offset != null) {
        // Simple culling for markers: only paint if the line Y is visible.
        final markerY = fragment.offset!.dy;
        if (markerY + fragment.height >= visibleRect.top &&
            markerY <= visibleRect.bottom) {
          _paintListMarker(canvas, offset, fragment);
        }
      }
    }

    // Then paint line content
    for (final line in _lines) {
      // CULLING: Only paint lines that intersect with the visible clip bounds.
      // For a 6000-char chunk (hundreds of lines), this reduces canvas.draw
      // calls by ~90% when only a small part of the chunk is on-screen.
      if (line.top + line.height < visibleRect.top) continue;
      if (line.top > visibleRect.bottom) {
        break; // Lines are sorted by Y; can stop early.
      }

      for (final fragment in line.fragments) {
        // Animated blocks are painted (with interpolated color/opacity/
        // transform) by _paintAnimatedBlocks instead — skip here so they're
        // not drawn twice at their static style. List markers are
        // deliberately NOT skipped: block-level canvas animation covers text
        // content only for now, so a marker stays static even inside an
        // animating block (documented v1 scope limit).
        final owner = _nearestAnimatedAncestor(fragment.sourceNode);
        if (owner != null && _paintedThisFrameByAnimation.contains(owner)) {
          continue;
        }
        if (fragment.type == FragmentType.text && fragment.text != null) {
          _paintTextFragment(canvas, offset, fragment);
        } else if (fragment.type == FragmentType.ruby) {
          _paintRubyFragment(canvas, offset, fragment);
        }
      }
    }
  }

  void _paintListMarker(
      Canvas canvas, Offset offset, _ListMarkerFragment fragment) {
    final painter = _getTextPainter(fragment.marker, fragment.style);
    painter.paint(canvas, offset + fragment.offset!);
  }

  void _paintTextFragment(Canvas canvas, Offset offset, Fragment fragment,
      {Color? colorOverride}) {
    final fragmentOffset = fragment.offset ?? Offset.zero;
    // _effectiveFragmentStyle folds in text-align:justify word-spacing so the
    // painted glyphs match the justified positions computed in layout.
    var style = _effectiveFragmentStyle(fragment);
    if (colorOverride != null) style = style.copyWith(color: colorOverride);
    final painter = _getTextPainter(fragment.text!, style);
    painter.paint(canvas, offset + fragmentOffset);
  }

  void _paintRubyFragment(Canvas canvas, Offset offset, Fragment fragment,
      {Color? colorOverride}) {
    final fragmentOffset = fragment.offset ?? Offset.zero;

    final baseStyle = colorOverride == null
        ? fragment.style
        : fragment.style.copyWith(color: colorOverride);
    final rubyFontSize = baseStyle.fontSize * RenderHyperBox.rubyFontSizeRatio;
    final rubyStyle = baseStyle.copyWith(fontSize: rubyFontSize);
    final rubyPainter = _getTextPainter(fragment.rubyText!, rubyStyle);
    final basePainter = _getTextPainter(fragment.text!, baseStyle);

    final totalWidth = fragment.width;
    // Center both texts horizontally
    final rubyX = (totalWidth - rubyPainter.width) / 2;
    final baseX = (totalWidth - basePainter.width) / 2;

    // Ruby text is at the top, base text below
    const rubyY = 0.0;
    final baseY =
        (fragment.rubyHeight ?? rubyPainter.height) + RenderHyperBox.rubyGap;

    rubyPainter.paint(
      canvas,
      offset + fragmentOffset + Offset(rubyX, rubyY),
    );

    basePainter.paint(
      canvas,
      offset + fragmentOffset + Offset(baseX, baseY),
    );
  }

  void _paintFloatImages(Canvas canvas, Offset offset) {
    // Paint images from float fragments ONLY if they don't have child widgets
    for (final fragment in _fragments) {
      if (fragment is _FloatFragment) {
        if (_hasChildWidgetForFragment(fragment)) continue;

        final node = fragment.sourceNode;
        if (node is AtomicNode && node.tagName == 'img') {
          _paintImage(canvas, offset, fragment, node);
        }
      }
    }

    // Paint carried-over float images from the previous virtualized section.
    // These are float images that extend past the chunk boundary — the previous
    // section painted the top portion, and this section paints the remainder
    // starting from imagePixelOffset.
    for (final carryover in _initialFloats) {
      if (carryover.imageSrc == null || carryover.imagePixelOffset <= 0) {
        continue;
      }
      final cached = _imageCache.get(carryover.imageSrc!);
      if (cached == null ||
          cached.state != ImageLoadState.loaded ||
          cached.image == null) {
        continue;
      }
      final dstRect = carryover.direction == HyperFloat.left
          ? Rect.fromLTWH(
              offset.dx, offset.dy, carryover.width, carryover.overhangHeight)
          : Rect.fromLTWH(offset.dx + _maxWidth - carryover.width, offset.dy,
              carryover.width, carryover.overhangHeight);

      final img = cached.image!;
      final scaleX = img.width / carryover.width;
      final srcTop = carryover.imagePixelOffset * scaleX;
      final srcRect =
          Rect.fromLTWH(0, srcTop, img.width.toDouble(), img.height - srcTop);

      canvas.drawImageRect(img, srcRect, dstRect, Paint());
    }
  }

  void _paintInlineImages(Canvas canvas, Offset offset) {
    // Paint non-float atomic images ONLY if they don't have child widgets
    for (final fragment in _fragments) {
      if (fragment.type == FragmentType.atomic && fragment is! _FloatFragment) {
        // Check if this fragment has a linked child widget - if so, skip canvas painting
        // The child widget (HyperImage) will handle rendering
        if (_hasChildWidgetForFragment(fragment)) continue;

        final node = fragment.sourceNode;
        if (node is AtomicNode && node.tagName == 'img') {
          _paintImage(canvas, offset, fragment, node);
        }
      }
    }
  }

  /// Check if a fragment has a linked child RenderBox widget (O(1) via map).
  bool _hasChildWidgetForFragment(Fragment fragment) {
    if (_fragmentChildMap.containsKey(fragment)) return true;
    // Fallback for edge cases before the map is populated.
    RenderBox? child = firstChild;
    while (child != null) {
      final parentData = child.parentData as HyperBoxParentData;
      if (parentData.fragment == fragment ||
          parentData.sourceNode == fragment.sourceNode) {
        return true;
      }
      child = parentData.nextSibling;
    }
    return false;
  }

  void _paintImage(
      Canvas canvas, Offset offset, Fragment fragment, AtomicNode node) {
    final src = node.src;
    if (src == null) return;

    final fragmentOffset = fragment.offset ?? Offset.zero;
    final rect = Rect.fromLTWH(
      offset.dx + fragmentOffset.dx,
      offset.dy + fragmentOffset.dy,
      fragment.width,
      fragment.height,
    );

    // _LruCache.get() promotes the entry to most-recently-used so images
    // that are actively being painted are never evicted mid-session.
    final cached = _imageCache.get(src);

    if (cached == null) {
      // Cache miss: image was evicted by LRU pressure (or not yet loaded for
      // the first time).  Show shimmer and schedule a re-fetch after this
      // paint pass.  We cannot call _loadImage() directly from paint() because
      // it modifies state — use addPostFrameCallback instead.
      _paintSkeletonPlaceholder(canvas, rect);
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (attached && !_imageCache.containsKey(src)) {
          _loadImage(src);
          markNeedsPaint();
        }
      });
      return;
    }

    if (cached.state == ImageLoadState.loaded && cached.image != null) {
      // Draw loaded image with rounded corners if specified
      final borderRadius = fragment.style.borderRadius;
      if (borderRadius != null) {
        canvas.save();
        canvas.clipRRect(RRect.fromRectAndCorners(
          rect,
          topLeft: borderRadius.topLeft,
          topRight: borderRadius.topRight,
          bottomLeft: borderRadius.bottomLeft,
          bottomRight: borderRadius.bottomRight,
        ));
      }

      paintImage(
        canvas: canvas,
        rect: rect,
        image: cached.image!,
        // object-fit (for <img>) takes priority over background-size (for
        // CSS background images). Fall back to cover when neither is set.
        fit: _getBoxFit(
            fragment.style.objectFit ?? fragment.style.backgroundSize),
        repeat: _getImageRepeat(fragment.style.backgroundRepeat),
        alignment: _getBackgroundAlignment(fragment.style.backgroundPosition),
        filterQuality: FilterQuality.medium,
      );

      if (borderRadius != null) {
        canvas.restore();
      }
    } else if (cached.state == ImageLoadState.loading) {
      // Draw modern skeleton placeholder
      _paintSkeletonPlaceholder(canvas, rect);
    } else {
      // Draw error placeholder with icon
      _paintErrorPlaceholder(canvas, rect);
    }
  }

  /// Paint an animated skeleton shimmer placeholder.
  ///
  /// The shimmer highlight sweeps left → right, driven by [_shimmerPhase]
  /// which is updated each frame via [SchedulerBinding.scheduleFrameCallback].
  /// This matches the Facebook / LinkedIn / Material 3 skeleton pattern —
  /// a moving highlight over a base grey that signals "content loading".
  void _paintSkeletonPlaceholder(Canvas canvas, Rect rect) {
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(8));

    // Base grey background.
    canvas.drawRRect(rrect, _skeletonBasePaint);

    // EASE-IN-OUT PHASE: Using a cubic ease-in-out curve for the phase makes
    // the shimmer sweep feel much more natural and 'high-end' than linear motion.
    double phase = _shimmerPhase;
    // Simple cubic ease-in-out mapping:
    phase = phase < 0.5
        ? 4 * phase * phase * phase
        : 1 - math.pow(-2 * phase + 2, 3) / 2;

    // Animated shimmer highlight.  The bright band is 50% of the rect width;
    // it sweeps from left (-50%) to right (150%) using the eased phase.
    final bandW = rect.width * 0.50;
    final startX = rect.left - bandW + (rect.width + bandW * 2) * phase;

    // PREMIUM GRADIENT: 5-stop gradient with subtle mid-tones creates a
    // soft, 'liquid' light effect instead of a harsh white band.
    _shimmerHighlightPaint.shader = ui.Gradient.linear(
      Offset(startX - bandW * 0.5, rect.center.dy),
      Offset(startX + bandW * 0.5, rect.center.dy),
      const [
        Color(0x00FFFFFF), // transparent
        Color(0x1AFFFFFF), // 10% white
        Color(0x73FFFFFF), // 45% white (peak)
        Color(0x1AFFFFFF), // 10% white
        Color(0x00FFFFFF), // transparent
      ],
      const [0.0, 0.35, 0.5, 0.65, 1.0],
    );

    canvas.save();
    canvas.clipRRect(rrect);
    canvas.drawRect(rect, _shimmerHighlightPaint);
    canvas.restore();

    // Hairline border — no StrokeCap needed for drawRRect.
    canvas.drawRRect(rrect, _skeletonBorderPaint);

    // Minimal loading indicator: a small rounded rectangle placeholder line
    // centered in the image area. Pure shimmer + subtle hint is the modern
    // skeleton standard (Facebook/LinkedIn) — no hand-drawn icon needed.
    if (rect.width > 40 && rect.height > 30) {
      final center = rect.center;

      // Two stacked pill-shaped lines — universally understood as "loading"
      final lineW = (rect.width * 0.35).clamp(20.0, 80.0);
      const lineH = 6.0;
      const gap = 10.0;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset(center.dx, center.dy - gap / 2 - lineH / 2),
              width: lineW,
              height: lineH),
          const Radius.circular(3),
        ),
        _skeletonIndicatorPaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset(center.dx, center.dy + gap / 2 + lineH / 2),
              width: lineW * 0.65,
              height: lineH),
          const Radius.circular(3),
        ),
        _skeletonIndicatorPaint,
      );
    }
  }

  /// Paint an error placeholder with broken image icon
  void _paintErrorPlaceholder(Canvas canvas, Rect rect) {
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(8));
    canvas.drawRRect(rrect, _errorBgPaint);
    canvas.drawRRect(rrect, _errorBorderPaint);

    // Broken image indicator: a soft rounded frame + small diagonal slash.
    // Uses rounded corners and muted colors — premium feel, not hand-drawn.
    if (rect.width > 24 && rect.height > 20) {
      final center = rect.center;
      final iconSize = (rect.shortestSide * 0.28).clamp(14.0, 28.0);

      // Rounded frame
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: center, width: iconSize * 1.5, height: iconSize),
          const Radius.circular(3),
        ),
        _errorFramePaint,
      );

      // Diagonal slash in error red — universally understood as "broken"
      canvas.drawLine(
        Offset(center.dx - iconSize * 0.45, center.dy - iconSize * 0.28),
        Offset(center.dx + iconSize * 0.45, center.dy + iconSize * 0.28),
        _errorSlashPaint,
      );
    }
  }

  /// Draws colored outlines for each line and fragment when [debugShowBounds] is true.
  void _paintDebugBounds(Canvas canvas, Offset offset) {
    final linePaint = Paint()
      ..color = const Color(0x66007BFF) // blue for line rows
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.square;

    final fragmentPaint = Paint()
      ..color = const Color(0x66FF6B00) // orange for individual fragments
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5
      ..strokeCap = StrokeCap.square;

    for (final line in _lines) {
      // Draw the full line row
      final lineRect = Rect.fromLTWH(
        offset.dx,
        offset.dy + line.top,
        _maxWidth.isFinite ? _maxWidth : size.width,
        line.height,
      );
      canvas.drawRect(lineRect, linePaint);

      // Draw each fragment within the line
      for (final fragment in line.fragments) {
        final rect = fragment.rect;
        if (rect != null) {
          canvas.drawRect(rect.shift(offset), fragmentPaint);
        }
      }
    }
  }
}
