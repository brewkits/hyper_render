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
    int lastOffset =
        lineIdx < _lineStartOffsets.length ? _lineStartOffsets[lineIdx] : 0;

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

        // Click is before this fragment — place cursor at start of fragment.
        if (position.dx < fragmentRect.left) return fragment.globalOffset;

        if (position.dx <= fragmentRect.right) {
          // Click is within this fragment — find exact character position.
          final painter = _getTextPainter(text, fragment.style);
          final localX = position.dx - fragmentRect.left;
          final textPosition = painter.getPositionForOffset(Offset(localX, 0));
          return fragment.globalOffset + textPosition.offset;
        }

        lastOffset = fragment.globalOffset + text.length;
      }
    }
    // Click was past all fragments (right margin) — return end of line.
    return lastOffset;
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
    bool pendingNewline = false;

    for (final fragment in _fragments) {
      if (fragment is _BlockStartFragment) continue;
      if (fragment is _BlockEndFragment) {
        if (buffer.isNotEmpty) pendingNewline = true;
        continue;
      }

      final isText = (fragment.type == FragmentType.text ||
              fragment.type == FragmentType.ruby) &&
          fragment.text != null;
      if (!isText) continue;

      final fragmentLength = fragment.text!.length;
      final fragmentStart = fragment.globalOffset;
      final fragmentEnd = fragmentStart + fragmentLength;

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
          math.min(fragmentLength, _selection!.end - fragmentStart);

      if (selectStart >= selectEnd) continue;

      final fragmentText = fragment.text!;
      // SAFETY: Ensure we don't split Unicode surrogate pairs by snapping
      // to valid character boundaries if the selection offsets fall in the middle.
      int safeStart = selectStart;
      if (safeStart > 0 && safeStart < fragmentText.length) {
        final codeUnit = fragmentText.codeUnitAt(safeStart);
        if (codeUnit >= 0xDC00 && codeUnit <= 0xDFFF) {
          safeStart--; // Move back to lead surrogate
        }
      }
      int safeEnd = selectEnd;
      if (safeEnd > 0 && safeEnd < fragmentText.length) {
        final codeUnit = fragmentText.codeUnitAt(safeEnd);
        if (codeUnit >= 0xDC00 && codeUnit <= 0xDFFF) {
          safeEnd--; // Exclude the split trailing surrogate
        }
      }

      if (fragment.type == FragmentType.ruby) {
        // For Ruby, we only include the furigana in brackets if the
        // ENTIRE base text is within the selection range.
        // Otherwise, we only include the selected portion of the base text.
        final isFullRubySelected =
            selectStart == 0 && selectEnd == fragmentLength;
        final base = fragmentText.substring(safeStart, safeEnd);

        if (isFullRubySelected &&
            fragment.rubyText != null &&
            fragment.rubyText!.isNotEmpty) {
          buffer.write('$base(${fragment.rubyText})');
        } else {
          buffer.write(base);
        }
      } else {
        buffer.write(fragmentText.substring(safeStart, safeEnd));
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

    for (final line in _lines) {
      for (final fragment in line.fragments) {
        if ((fragment.type == FragmentType.text ||
                fragment.type == FragmentType.ruby) &&
            fragment.text != null) {
          final fragmentLength = fragment.text!.length;
          final fragmentStart = fragment.globalOffset;
          final fragmentEnd = fragmentStart + fragmentLength;

          // Check if this fragment overlaps with selection
          if (fragmentEnd > _selection!.start &&
              fragmentStart < _selection!.end) {
            final selectStart = math.max(0, _selection!.start - fragmentStart);
            final selectEnd =
                math.min(fragmentLength, _selection!.end - fragmentStart);

            // Trim trailing/leading spaces for visual bounds, but preserve them
            // in preformatted contexts where indentation is meaningful.
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

            if (visualStart < visualEnd) {
              if (fragment.type == FragmentType.ruby) {
                // Ruby selection highlight covers the whole fragment rect
                final fragmentOffset = fragment.offset ?? Offset.zero;
                rects.add(Rect.fromLTWH(
                  fragmentOffset.dx,
                  fragmentOffset.dy,
                  fragment.width,
                  fragment.height,
                ));
              } else {
                final painter = _getTextPainter(text, fragment.style);
                final boxes = painter.getBoxesForSelection(
                  TextSelection(
                      baseOffset: visualStart, extentOffset: visualEnd),
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
            }
          }
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

    final HyperTextSelection newSel;
    if (isStartHandle) {
      if (charPos <= _selection!.end) {
        newSel = HyperTextSelection(start: charPos, end: _selection!.end);
      } else {
        // Start dragged past end — swap anchors so selection inverts smoothly.
        newSel = HyperTextSelection(start: _selection!.end, end: charPos);
      }
    } else {
      if (charPos >= _selection!.start) {
        newSel = HyperTextSelection(start: _selection!.start, end: charPos);
      } else {
        // End dragged past start — swap anchors so selection inverts smoothly.
        newSel = HyperTextSelection(start: charPos, end: _selection!.start);
      }
    }

    if (newSel == _selection) return;
    _selection = newSel;
    markNeedsPaint();
    _notifySelectionChanged();
  }
}
