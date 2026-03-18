part of 'render_hyper_box.dart';

extension _RenderHyperBoxPaint on RenderHyperBox {
  void _paintBlockDecorations(Canvas canvas, Offset offset) {
    for (final decoration in _blockDecorations) {
      final adjustedRect = decoration.rect.shift(offset);

      // 1. Backdrop Filter (Glassmorphism)
      if (decoration.backdropFilter != null) {
        canvas.saveLayer(adjustedRect, Paint());
        final filterPaint = Paint()
          ..imageFilter = decoration.backdropFilter
          ..blendMode = BlendMode.srcOver;
        canvas.drawRect(adjustedRect, filterPaint);
        canvas.restore();
      }

      // 2. Filter (blur, etc.)
      if (decoration.filter != null) {
        canvas.saveLayer(adjustedRect, Paint()..imageFilter = decoration.filter);
      }

      // 3. Box shadows
      if (decoration.boxShadow != null) {
        for (final shadow in decoration.boxShadow!) {
          final shadowPaint = shadow.toPaint();
          final shadowRect = adjustedRect.shift(shadow.offset).inflate(shadow.spreadRadius);

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
      if (decoration.backgroundColor != null || decoration.backgroundGradient != null) {
        final bgPaint = Paint()..isAntiAlias = true;

        if (decoration.backgroundGradient != null) {
          bgPaint.shader = decoration.backgroundGradient!.createShader(adjustedRect);
        } else {
          bgPaint.color = decoration.backgroundColor!;
        }

        if (decoration.borderRadius != null) {
          // Draw rounded rectangle for code blocks, etc.
          canvas.drawRRect(
            RRect.fromRectAndCorners(
              adjustedRect,
              topLeft: decoration.borderRadius!.topLeft,
              topRight: decoration.borderRadius!.topRight,
              bottomLeft: decoration.borderRadius!.bottomLeft,
              bottomRight: decoration.borderRadius!.bottomRight,
            ),
            bgPaint,
          );
        } else {
          canvas.drawRect(adjustedRect, bgPaint);
        }
      }

      // Paint border-left (for blockquote style)
      if (decoration.borderLeftColor != null && decoration.borderLeftWidth > 0) {
        _drawStyledLine(
          canvas,
          Offset(adjustedRect.left + decoration.borderLeftWidth / 2, adjustedRect.top),
          Offset(adjustedRect.left + decoration.borderLeftWidth / 2, adjustedRect.bottom),
          decoration.borderLeftColor!,
          decoration.borderLeftWidth,
          decoration.borderLeftStyle,
        );
      }

      // Restore layer if filter was applied
      if (decoration.filter != null) {
        canvas.restore();
      }
    }
  }

  void _paintInlineDecorations(Canvas canvas, Offset offset) {
    for (final decoration in _inlineDecorations) {
      for (final rect in decoration.rects) {
        final adjustedRect = rect.shift(offset);

        // 1. Backdrop Filter
        if (decoration.backdropFilter != null) {
          canvas.saveLayer(adjustedRect, Paint());
          canvas.drawRect(adjustedRect, Paint()..imageFilter = decoration.backdropFilter);
          canvas.restore();
        }

        // 2. Filter (blur, etc.)
        if (decoration.filter != null) {
          canvas.saveLayer(adjustedRect, Paint()..imageFilter = decoration.filter);
        }

        // 3. Box shadows
        if (decoration.boxShadow != null) {
          for (final shadow in decoration.boxShadow!) {
            final shadowPaint = shadow.toPaint();
            final shadowRect = adjustedRect.shift(shadow.offset).inflate(shadow.spreadRadius);

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

        // Paint background or gradient
        if (decoration.backgroundColor != null || decoration.backgroundGradient != null) {
          final paint = Paint()..isAntiAlias = true;

          if (decoration.backgroundGradient != null) {
            paint.shader = decoration.backgroundGradient!.createShader(adjustedRect);
          } else {
            paint.color = decoration.backgroundColor!;
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
              paint,
            );
          } else {
            canvas.drawRect(adjustedRect, paint);
          }
        }

        // Paint border
        if (decoration.borderColor != null && decoration.borderWidth > 0) {
          _drawStyledBorder(
            canvas,
            adjustedRect,
            decoration.borderColor!,
            decoration.borderWidth,
            decoration.borderStyle,
            decoration.borderRadius,
          );
        }

        // Restore layer if filter was applied
        if (decoration.filter != null) {
          canvas.restore();
        }
      }
    }
  }

  /// Helper to draw a single line with different styles
  void _drawStyledLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Color color,
    double width,
    HyperBorderStyle style,
  ) {
    if (style == HyperBorderStyle.none || width <= 0) return;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..isAntiAlias = true
      ..strokeCap = StrokeCap.square;

    if (style == HyperBorderStyle.solid) {
      canvas.drawLine(start, end, paint);
      return;
    }

    if (style == HyperBorderStyle.double) {
      final offset = width / 3;
      final outerPaint = paint..strokeWidth = offset;
      final innerPaint = paint..strokeWidth = offset;
      
      // Determine if vertical or horizontal
      final bool isVertical = start.dx == end.dx;
      if (isVertical) {
        canvas.drawLine(start.translate(-offset, 0), end.translate(-offset, 0), outerPaint);
        canvas.drawLine(start.translate(offset, 0), end.translate(offset, 0), innerPaint);
      } else {
        canvas.drawLine(start.translate(0, -offset), end.translate(0, -offset), outerPaint);
        canvas.drawLine(start.translate(0, offset), end.translate(0, offset), innerPaint);
      }
      return;
    }

    // Dashed or Dotted
    final List<double> dashArray = style == HyperBorderStyle.dashed 
      ? [width * 3, width * 2] 
      : [width, width];

    final path = Path()..moveTo(start.dx, start.dy)..lineTo(end.dx, end.dy);
    _drawDashedPath(canvas, path, paint, dashArray);
  }

  /// Helper to draw borders with different styles (solid, dashed, dotted, double)
  void _drawStyledBorder(
    Canvas canvas,
    Rect rect,
    Color color,
    double width,
    HyperBorderStyle style,
    BorderRadius? borderRadius,
  ) {
    if (style == HyperBorderStyle.none || width <= 0) return;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..isAntiAlias = true
      ..strokeCap = StrokeCap.square;

    if (style == HyperBorderStyle.solid) {
      if (borderRadius != null) {
        canvas.drawRRect(
          RRect.fromRectAndCorners(
            rect,
            topLeft: borderRadius.topLeft,
            topRight: borderRadius.topRight,
            bottomLeft: borderRadius.bottomLeft,
            bottomRight: borderRadius.bottomRight,
          ),
          paint,
        );
      } else {
        canvas.drawRect(rect, paint);
      }
      return;
    }

    if (style == HyperBorderStyle.double) {
      // Draw two solid lines with a gap
      final outerWidth = width / 3;
      final innerWidth = width / 3;
      
      // Outer border
      final outerPaint = paint..strokeWidth = outerWidth;
      final outerRect = rect.inflate(outerWidth / 2); // Inflate to align outer edge
      if (borderRadius != null) {
        canvas.drawRRect(RRect.fromRectAndCorners(outerRect, 
          topLeft: borderRadius.topLeft, topRight: borderRadius.topRight, 
          bottomLeft: borderRadius.bottomLeft, bottomRight: borderRadius.bottomRight), outerPaint);
      } else {
        canvas.drawRect(outerRect, outerPaint);
      }

      // Inner border
      final innerPaint = paint..strokeWidth = innerWidth;
      final innerRect = rect.deflate(innerWidth / 2); // Deflate for inner line
      if (borderRadius != null) {
        // Calculate the reduction amount for the radius.
        // The original 'deflate(width / 1.5)' suggests a reduction.
        // Let's assume it's the amount to subtract from each radius component.
        // We clamp to 0 to prevent negative radii.
        final double reduction = (width / 1.5).clamp(0.0, double.infinity);

        final Radius newTopLeft = borderRadius.topLeft.x > 0 ? Radius.circular(math.max(0.0, borderRadius.topLeft.x - reduction)) : Radius.zero;
        final Radius newTopRight = borderRadius.topRight.x > 0 ? Radius.circular(math.max(0.0, borderRadius.topRight.x - reduction)) : Radius.zero;
        final Radius newBottomLeft = borderRadius.bottomLeft.x > 0 ? Radius.circular(math.max(0.0, borderRadius.bottomLeft.x - reduction)) : Radius.zero;
        final Radius newBottomRight = borderRadius.bottomRight.x > 0 ? Radius.circular(math.max(0.0, borderRadius.bottomRight.x - reduction)) : Radius.zero;

        final innerRadius = BorderRadius.only(
          topLeft: newTopLeft,
          topRight: newTopRight,
          bottomLeft: newBottomLeft,
          bottomRight: newBottomRight,
        );

        canvas.drawRRect(RRect.fromRectAndCorners(innerRect,
          topLeft: innerRadius.topLeft, topRight: innerRadius.topRight,
          bottomLeft: innerRadius.bottomLeft, bottomRight: innerRadius.bottomRight), innerPaint);
      } else {
        canvas.drawRect(innerRect, innerPaint);
      }
      return;
    }

    // Dashed or Dotted
    final List<double> dashArray = style == HyperBorderStyle.dashed 
      ? [width * 3, width * 2] 
      : [width, width];

    final path = Path();
    if (borderRadius != null) {
      path.addRRect(RRect.fromRectAndCorners(
        rect,
        topLeft: borderRadius.topLeft,
        topRight: borderRadius.topRight,
        bottomLeft: borderRadius.bottomLeft,
        bottomRight: borderRadius.bottomRight,
      ));
    } else {
      path.addRect(rect);
    }

    _drawDashedPath(canvas, path, paint, dashArray);
  }

  /// Draw a dashed path manually using PathMetrics
  void _drawDashedPath(Canvas canvas, Path path, Paint paint, List<double> dashArray) {
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      bool draw = true;
      int i = 0;
      while (distance < metric.length) {
        final double step = dashArray[i % dashArray.length];
        if (draw) {
          final double end = math.min(distance + step, metric.length);
          canvas.drawPath(metric.extractPath(distance, end), paint);
        }
        distance += step;
        draw = !draw;
        i++;
      }
    }
  }

  void _paintSelection(Canvas canvas, Offset offset) {
    // Determine selection color:
    // 1. Explicit color passed from HyperViewer
    // 2. Adaptive default based on platform
    final selectionColor = _selectionColor ??
        (Platform.isIOS || Platform.isMacOS
            ? const Color(0x40007AFF) // iOS blue at 25% opacity
            : const Color(0x404285F4)); // Material 3 blue at 25% opacity

    final selectionPaint = Paint()
      ..color = selectionColor
      ..isAntiAlias = true;

    int currentOffset = 0;
    for (final line in _lines) {
      for (final fragment in line.fragments) {
        if (fragment.type == FragmentType.text && fragment.text != null) {
          final fragmentStart = currentOffset;
          final fragmentEnd = currentOffset + fragment.text!.length;

          // Check if this fragment overlaps with selection
          if (fragmentEnd > _selection!.start &&
              fragmentStart < _selection!.end) {
            final selectStart =
                math.max(0, _selection!.start - fragmentStart);
            final selectEnd = math.min(
                fragment.text!.length, _selection!.end - fragmentStart);

            // Get selection rect within this fragment
            final painter = _getTextPainter(fragment.text!, fragment.style);
            final startOffset = painter
                .getOffsetForCaret(TextPosition(offset: selectStart),
                    Rect.zero)
                .dx;
            final endOffset = painter
                .getOffsetForCaret(TextPosition(offset: selectEnd), Rect.zero)
                .dx;

            final fragmentOffset = fragment.offset ?? Offset.zero;
            final selectionRect = Rect.fromLTWH(
              offset.dx + fragmentOffset.dx + startOffset,
              offset.dy + fragmentOffset.dy,
              endOffset - startOffset,
              fragment.height,
            );

            canvas.drawRect(selectionRect, selectionPaint);
          }

          currentOffset = fragmentEnd;
        }
      }
    }
  }

  void _paintTextFragments(Canvas canvas, Offset offset) {
    // First paint list markers
    for (final fragment in _fragments) {
      if (fragment is _ListMarkerFragment && fragment.offset != null) {
        _paintListMarker(canvas, offset, fragment);
      }
    }

    // Then paint line content
    for (final line in _lines) {
      for (final fragment in line.fragments) {
        if (fragment.type == FragmentType.text && fragment.text != null) {
          _paintTextFragment(canvas, offset, fragment);
        } else if (fragment.type == FragmentType.ruby) {
          _paintRubyFragment(canvas, offset, fragment);
        }
      }
    }
  }

  void _paintListMarker(Canvas canvas, Offset offset, _ListMarkerFragment fragment) {
    final painter = _getTextPainter(fragment.marker, fragment.style);
    painter.paint(canvas, offset + fragment.offset!);
  }

  void _paintTextFragment(Canvas canvas, Offset offset, Fragment fragment) {
    final fragmentOffset = fragment.offset ?? Offset.zero;
    final painter = _getTextPainter(fragment.text!, fragment.style);
    painter.paint(canvas, offset + fragmentOffset);
  }

  void _paintRubyFragment(Canvas canvas, Offset offset, Fragment fragment) {
    final fragmentOffset = fragment.offset ?? Offset.zero;

    final rubyFontSize = fragment.style.fontSize * RenderHyperBox.rubyFontSizeRatio;
    final rubyStyle = fragment.style.copyWith(fontSize: rubyFontSize);
    final rubyPainter = _getTextPainter(fragment.rubyText!, rubyStyle);
    final basePainter = _getTextPainter(fragment.text!, fragment.style);

    final totalWidth = fragment.width;
    // Center both texts horizontally
    final rubyX = (totalWidth - rubyPainter.width) / 2;
    final baseX = (totalWidth - basePainter.width) / 2;

    // Ruby text is at the top, base text below
    const rubyY = 0.0;
    final baseY = (fragment.rubyHeight ?? rubyPainter.height) + RenderHyperBox.rubyGap;

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

  /// Check if a fragment has a linked child RenderBox widget
  bool _hasChildWidgetForFragment(Fragment fragment) {
    RenderBox? child = firstChild;
    while (child != null) {
      final parentData = child.parentData as HyperBoxParentData;
      if (parentData.fragment == fragment || parentData.sourceNode == fragment.sourceNode) {
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

    final cached = _imageCache[src];

    if (cached?.state == ImageLoadState.loaded && cached?.image != null) {
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
        image: cached!.image!,
        fit: _getBoxFit(fragment.style.backgroundSize),
        filterQuality: FilterQuality.medium, // Crisp rendering on retina displays
      );

      if (borderRadius != null) {
        canvas.restore();
      }
    } else if (cached?.state == ImageLoadState.loading) {
      // Draw modern skeleton placeholder
      _paintSkeletonPlaceholder(canvas, rect);
    } else {
      // Draw error placeholder with icon
      _paintErrorPlaceholder(canvas, rect);
    }
  }

  /// Paint a skeleton loading placeholder (similar to shimmer effect)
  void _paintSkeletonPlaceholder(Canvas canvas, Rect rect) {
    // Background
    final bgPaint = Paint()
      ..shader = ui.Gradient.linear(
        rect.topLeft,
        rect.bottomRight,
        [
          const Color(0xFFF0F0F0),
          const Color(0xFFE8E8E8),
          const Color(0xFFF0F0F0),
        ],
        [0.0, 0.5, 1.0],
      )
      ..isAntiAlias = true;

    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(8));
    canvas.drawRRect(rrect, bgPaint);

    // Subtle border
    final borderPaint = Paint()
      ..color = const Color(0xFFE0E0E0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..isAntiAlias = true
      ..strokeCap = StrokeCap.square;
    canvas.drawRRect(rrect, borderPaint);

    // Image icon in center
    final center = rect.center;
    final iconPaint = Paint()
      ..color = const Color(0xFFBDBDBD)
      ..isAntiAlias = true;

    // Draw a simple image icon (mountain landscape)
    final iconPath = Path();
    const iconSize = 24.0;

    // Frame
    iconPath.addRect(Rect.fromCenter(
      center: center,
      width: iconSize * 1.5,
      height: iconSize,
    ));

    canvas.drawPath(iconPath, iconPaint..style = PaintingStyle.stroke..strokeWidth = 1.5);

    // Mountains
    final mountainPath = Path();
    mountainPath.moveTo(center.dx - iconSize * 0.6, center.dy + iconSize * 0.3);
    mountainPath.lineTo(center.dx - iconSize * 0.2, center.dy - iconSize * 0.2);
    mountainPath.lineTo(center.dx + iconSize * 0.1, center.dy + iconSize * 0.1);
    mountainPath.lineTo(center.dx + iconSize * 0.3, center.dy - iconSize * 0.1);
    mountainPath.lineTo(center.dx + iconSize * 0.6, center.dy + iconSize * 0.3);

    canvas.drawPath(mountainPath, iconPaint..style = PaintingStyle.stroke..strokeWidth = 1.5);
  }

  /// Paint an error placeholder with broken image icon
  void _paintErrorPlaceholder(Canvas canvas, Rect rect) {
    // Background
    final bgPaint = Paint()
      ..color = const Color(0xFFFAFAFA)
      ..isAntiAlias = true;
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(8));
    canvas.drawRRect(rrect, bgPaint);

    // Border
    final borderPaint = Paint()
      ..color = const Color(0xFFE0E0E0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..isAntiAlias = true
      ..strokeCap = StrokeCap.square;
    canvas.drawRRect(rrect, borderPaint);

    // Broken image icon
    final center = rect.center;
    final iconPaint = Paint()
      ..color = const Color(0xFFBDBDBD)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..isAntiAlias = true;

    const iconSize = 20.0;

    // Draw broken image icon (image frame with crack)
    final framePath = Path();
    framePath.addRect(Rect.fromCenter(
      center: center,
      width: iconSize * 1.5,
      height: iconSize,
    ));
    canvas.drawPath(framePath, iconPaint);

    // Diagonal crack
    canvas.drawLine(
      Offset(center.dx - iconSize * 0.5, center.dy - iconSize * 0.3),
      Offset(center.dx + iconSize * 0.5, center.dy + iconSize * 0.3),
      iconPaint..color = const Color(0xFFE57373),
    );
  }
}
