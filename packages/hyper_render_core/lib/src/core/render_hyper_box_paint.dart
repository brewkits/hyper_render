part of 'render_hyper_box.dart';

extension _RenderHyperBoxPaint on RenderHyperBox {
  void _paintBlockDecorations(Canvas canvas, Offset offset) {
    for (final decoration in _blockDecorations) {
      final adjustedRect = decoration.rect.shift(offset);

      // Paint background if specified
      if (decoration.backgroundColor != null) {
        final bgPaint = Paint()
          ..color = decoration.backgroundColor!
          ..isAntiAlias = true;

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
        final borderPaint = Paint()
          ..color = decoration.borderLeftColor!
          ..style = PaintingStyle.stroke
          ..strokeWidth = decoration.borderLeftWidth
          ..isAntiAlias = true;

        canvas.drawLine(
          Offset(adjustedRect.left + decoration.borderLeftWidth / 2, adjustedRect.top),
          Offset(adjustedRect.left + decoration.borderLeftWidth / 2, adjustedRect.bottom),
          borderPaint,
        );
      }
    }
  }

  void _paintInlineDecorations(Canvas canvas, Offset offset) {
    for (final decoration in _inlineDecorations) {
      for (final rect in decoration.rects) {
        final adjustedRect = rect.shift(offset);

        // Paint background
        if (decoration.backgroundColor != null) {
          final paint = Paint()
            ..color = decoration.backgroundColor!
            ..isAntiAlias = true;

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
          final paint = Paint()
            ..color = decoration.borderColor!
            ..style = PaintingStyle.stroke
            ..strokeWidth = decoration.borderWidth
            ..isAntiAlias = true;

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
      }
    }
  }

  void _paintSelection(Canvas canvas, Offset offset) {
    final selectionPaint = Paint()
      ..color = const Color(0x40007AFF) // iOS blue with 25% opacity
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

            // Viewport culling: skip rects that are outside the clip bounds
            if (_paintClipBounds != null && !_paintClipBounds!.overlaps(selectionRect)) {
              currentOffset = fragmentEnd;
              continue;
            }

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
        fit: BoxFit.cover,
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
      ..isAntiAlias = true;
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
      ..isAntiAlias = true;
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
