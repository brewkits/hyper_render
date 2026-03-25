part of 'render_hyper_box.dart';

extension RenderHyperBoxSelection on RenderHyperBox {
  // ── Binary-search helper ──────────────────────────────────────────────────

  /// Returns the index of the [LineInfo] in [_lines] whose vertical span
  /// contains [dy], or -1 when [dy] falls outside all lines.
  ///
  /// Lines are laid out top-to-bottom with monotonically increasing [top]
  /// values, so binary search gives O(log N) instead of the previous O(N)
  /// linear scan — critical for long documents during handle-drag selection.
  int _lineIndexAt(double dy) {
    int lo = 0, hi = _lines.length - 1;
    while (lo <= hi) {
      final mid = (lo + hi) >>> 1;
      final line = _lines[mid];
      if (dy < line.top) {
        hi = mid - 1;
      } else if (dy >= line.top + line.height) {
        lo = mid + 1;
      } else {
        return mid;
      }
    }
    return -1;
  }

  // ── Hit testing ───────────────────────────────────────────────────────────

  Fragment? _findFragmentAtPosition(Offset position) {
    final lineIdx = _lineIndexAt(position.dy);
    if (lineIdx < 0) return null;
    for (final fragment in _lines[lineIdx].fragments) {
      final rect = fragment.rect;
      if (rect != null && rect.contains(position)) return fragment;
    }
    return null;
  }

  int _getCharacterPositionAtOffset(Offset position) {
    final lineIdx = _lineIndexAt(position.dy);
    if (lineIdx < 0) return -1;

    final line = _lines[lineIdx];
    // O(1) lookup of cumulative char count before this line
    // (populated by _buildCharacterMapping after every layout pass).
    int currentOffset =
        lineIdx < _lineStartOffsets.length ? _lineStartOffsets[lineIdx] : 0;
    final lineStartOffset = currentOffset;

    for (final fragment in line.fragments) {
      if ((fragment.type == FragmentType.text && fragment.text != null) ||
          fragment.type == FragmentType.ruby) {
        final text = fragment.text!;
        final fragmentOffset = fragment.offset ?? Offset.zero;
        final fragmentRect = Rect.fromLTWH(
          fragmentOffset.dx,
          fragmentOffset.dy,
          fragment.width,
          fragment.height,
        );

        // Click is before this fragment — place cursor at start of line.
        if (position.dx < fragmentRect.left) return lineStartOffset;

        if (position.dx <= fragmentRect.right) {
          // Click is within this fragment — find exact character position.
          final painter = _getTextPainter(text, fragment.style);
          final localX = position.dx - fragmentRect.left;
          final textPosition = painter.getPositionForOffset(Offset(localX, 0));
          return currentOffset + textPosition.offset;
        }

        currentOffset += text.length;
      }
    }
    // Click was past all fragments (right margin) — return end of line.
    return currentOffset;
  }

  /// Get selected text
  ///
  /// Iterates [_fragments] in order, inserting '\n' whenever a
  /// [_BlockEndFragment] is encountered so that block-level boundaries
  /// (e.g. <li> → <h3>, <p> → <p>) are reflected in the copied text.
  String? getSelectedText() {
    if (_selection == null || !_selection!.isValid || _selection!.isCollapsed) {
      return null;
    }

    final buffer = StringBuffer();
    int currentOffset = 0;
    bool pendingNewline = false;

    for (final fragment in _fragments) {
      // Structural markers (block start/end) have no visible text.
      if (fragment is _BlockStartFragment) continue;

      if (fragment is _BlockEndFragment) {
        if (buffer.isNotEmpty) pendingNewline = true;
        continue;
      }

      final isText =
          fragment.type == FragmentType.text && fragment.text != null;
      final isRuby =
          fragment.type == FragmentType.ruby && fragment.text != null;
      if (!isText && !isRuby) continue;

      final fragmentStart = currentOffset;
      final fragmentEnd = currentOffset + fragment.text!.length;
      currentOffset = fragmentEnd;

      // Outside selection range — skip.
      if (fragmentEnd <= _selection!.start ||
          fragmentStart >= _selection!.end) {
        continue;
      }

      // Flush the pending newline now that we have real text to follow it.
      if (pendingNewline) {
        buffer.write('\n');
        pendingNewline = false;
      }

      final selectStart = math.max(0, _selection!.start - fragmentStart);
      final selectEnd =
          math.min(fragment.text!.length, _selection!.end - fragmentStart);

      if (isRuby) {
        final base = fragment.text!.substring(selectStart, selectEnd);
        // Include furigana annotation when the *full* base text is selected,
        // formatted as "base(annotation)" — e.g. "東京(とうきょう)".
        // Partial ruby selections copy only the base text so that the
        // character count remains consistent with _selection offsets.
        if (selectStart == 0 &&
            selectEnd == fragment.text!.length &&
            fragment.rubyText != null &&
            fragment.rubyText!.isNotEmpty) {
          buffer.write('$base(${fragment.rubyText})');
        } else {
          buffer.write(base);
        }
      } else {
        buffer.write(fragment.text!.substring(selectStart, selectEnd));
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
      _selection = HyperTextSelection(start: 0, end: _totalCharacterCount);
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
            final selectStart = math.max(0, _selection!.start - fragmentStart);
            final selectEnd = math.min(
                fragment.text!.length, _selection!.end - fragmentStart);

            // Trim whitespace for visual bounds (same as _paintSelection)
            final text = fragment.text!;
            int visualStart = selectStart;
            int visualEnd = selectEnd;
            while (visualStart < visualEnd && text[visualStart] == ' ') {
              visualStart++;
            }
            while (visualEnd > visualStart && text[visualEnd - 1] == ' ') {
              visualEnd--;
            }
            if (visualStart >= visualEnd) {
              currentOffset = fragmentEnd;
              continue;
            }

            final painter = _getTextPainter(text, fragment.style);
            final boxes = painter.getBoxesForSelection(
              TextSelection(baseOffset: visualStart, extentOffset: visualEnd),
              boxHeightStyle: ui.BoxHeightStyle.tight,
            );

            final fragmentOffset = fragment.offset ?? Offset.zero;
            for (final box in boxes) {
              if (box.right <= box.left) continue;
              rects.add(Rect.fromLTRB(
                fragmentOffset.dx + box.left,
                fragmentOffset.dy + box.top,
                fragmentOffset.dx + box.right,
                fragmentOffset.dy + box.bottom,
              ));
            }
          }

          currentOffset = fragmentEnd;
        } else if (fragment.type == FragmentType.ruby &&
            fragment.text != null) {
          final fragmentStart = currentOffset;
          final fragmentEnd = currentOffset + fragment.text!.length;

          if (fragmentEnd > _selection!.start &&
              fragmentStart < _selection!.end) {
            final fragmentOffset = fragment.offset ?? Offset.zero;
            rects.add(Rect.fromLTWH(
              fragmentOffset.dx,
              fragmentOffset.dy,
              fragment.width,
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
