part of 'render_hyper_box.dart';

extension RenderHyperBoxSelection on RenderHyperBox {
  Fragment? _findFragmentAtPosition(Offset position) {
    for (final line in _lines) {
      if (position.dy >= line.top && position.dy < line.top + line.height) {
        for (final fragment in line.fragments) {
          final rect = fragment.rect;
          if (rect != null && rect.contains(position)) {
            return fragment;
          }
        }
      }
    }
    return null;
  }

  int _getCharacterPositionAtOffset(Offset position) {
    int currentOffset = 0;

    for (final line in _lines) {
      if (position.dy >= line.top && position.dy < line.top + line.height) {
        for (final fragment in line.fragments) {
          if (fragment.type == FragmentType.text && fragment.text != null) {
            final fragmentOffset = fragment.offset ?? Offset.zero;
            final fragmentRect = Rect.fromLTWH(
              fragmentOffset.dx,
              fragmentOffset.dy,
              fragment.width,
              fragment.height,
            );

            if (position.dx >= fragmentRect.left &&
                position.dx <= fragmentRect.right) {
              // Find character within fragment
              final painter = _getTextPainter(fragment.text!, fragment.style);
              final localX = position.dx - fragmentRect.left;
              final textPosition =
                  painter.getPositionForOffset(Offset(localX, 0));
              return currentOffset + textPosition.offset;
            }

            currentOffset += fragment.text!.length;
          }
        }
        // If we're on the line but past all fragments, return end of line
        return currentOffset;
      }

      // Add character count for this line
      for (final fragment in line.fragments) {
        if (fragment.type == FragmentType.text && fragment.text != null) {
          currentOffset += fragment.text!.length;
        }
      }
    }

    return -1;
  }

  /// Get selected text
  String? getSelectedText() {
    if (_selection == null || !_selection!.isValid || _selection!.isCollapsed) {
      return null;
    }

    final buffer = StringBuffer();
    int currentOffset = 0;

    for (final fragment in _fragments) {
      if (fragment.type == FragmentType.text && fragment.text != null) {
        final fragmentStart = currentOffset;
        final fragmentEnd = currentOffset + fragment.text!.length;

        if (fragmentEnd > _selection!.start &&
            fragmentStart < _selection!.end) {
          final selectStart = math.max(0, _selection!.start - fragmentStart);
          final selectEnd =
              math.min(fragment.text!.length, _selection!.end - fragmentStart);
          buffer.write(fragment.text!.substring(selectStart, selectEnd));
        }

        currentOffset = fragmentEnd;
      }
    }

    return buffer.isEmpty ? null : buffer.toString();
  }

  /// Copy selected text to clipboard
  Future<void> copySelection() async {
    final text = getSelectedText();
    if (text != null) {
      await Clipboard.setData(ClipboardData(text: text));
    }
  }

  /// Clear selection
  void clearSelection() {
    _selection = null;
    markNeedsPaint();
    _notifySelectionChanged();
  }

  /// Select all text
  void selectAll() {
    if (_totalCharacterCount > 0) {
      _selection =
          HyperTextSelection(start: 0, end: _totalCharacterCount);
      markNeedsPaint();
      _notifySelectionChanged();
    }
  }

  /// Get selection rects for rendering handles
  List<Rect> getSelectionRects() {
    if (_selection == null || !_selection!.isValid || _selection!.isCollapsed) {
      return [];
    }

    final rects = <Rect>[];
    int currentOffset = 0;

    for (final line in _lines) {
      for (final fragment in line.fragments) {
        if (fragment.type == FragmentType.text && fragment.text != null) {
          final fragmentStart = currentOffset;
          final fragmentEnd = currentOffset + fragment.text!.length;

          if (fragmentEnd > _selection!.start &&
              fragmentStart < _selection!.end) {
            final selectStart =
                math.max(0, _selection!.start - fragmentStart);
            final selectEnd = math.min(
                fragment.text!.length, _selection!.end - fragmentStart);

            final painter = _getTextPainter(fragment.text!, fragment.style);
            final startOffset = painter
                .getOffsetForCaret(TextPosition(offset: selectStart), Rect.zero)
                .dx;
            final endOffset = painter
                .getOffsetForCaret(TextPosition(offset: selectEnd), Rect.zero)
                .dx;

            final fragmentOffset = fragment.offset ?? Offset.zero;
            rects.add(Rect.fromLTWH(
              fragmentOffset.dx + startOffset,
              fragmentOffset.dy,
              endOffset - startOffset,
              fragment.height,
            ));
          }

          currentOffset = fragmentEnd;
        }
      }
    }

    return rects;
  }

  /// Get the rect for start handle
  Rect? getStartHandleRect() {
    final rects = getSelectionRects();
    if (rects.isEmpty) return null;
    return rects.first;
  }

  /// Get the rect for end handle
  Rect? getEndHandleRect() {
    final rects = getSelectionRects();
    if (rects.isEmpty) return null;
    return rects.last;
  }

  /// Update selection from handle drag
  void updateSelectionFromHandle(
    bool isStartHandle,
    Offset localPosition,
  ) {
    final charPos = _getCharacterPositionAtOffset(localPosition);
    if (charPos < 0 || _selection == null) return;

    if (isStartHandle) {
      if (charPos < _selection!.end) {
        _selection = HyperTextSelection(start: charPos, end: _selection!.end);
        markNeedsPaint();
      }
    } else {
      if (charPos > _selection!.start) {
        _selection = HyperTextSelection(start: _selection!.start, end: charPos);
        markNeedsPaint();
      }
    }
  }
}
