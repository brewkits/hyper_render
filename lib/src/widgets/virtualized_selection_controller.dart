import 'package:flutter/widgets.dart';
import 'package:hyper_render_core/hyper_render_core.dart';

// ──────────────────────────────────────────────────────────────────────────────
// Data model
// ──────────────────────────────────────────────────────────────────────────────

/// A position inside a virtualised document: which chunk and which local char.
class ChunkAnchor {
  const ChunkAnchor(this.chunkIndex, this.localOffset);
  final int chunkIndex;
  final int localOffset;

  bool operator <=(ChunkAnchor other) {
    if (chunkIndex != other.chunkIndex) return chunkIndex < other.chunkIndex;
    return localOffset <= other.localOffset;
  }

  @override
  bool operator ==(Object other) =>
      other is ChunkAnchor &&
      chunkIndex == other.chunkIndex &&
      localOffset == other.localOffset;

  @override
  int get hashCode => Object.hash(chunkIndex, localOffset);
}

/// A cross-chunk selection range.
class CrossChunkSelection {
  const CrossChunkSelection({required this.start, required this.end});

  final ChunkAnchor start; // always ≤ end in document order
  final ChunkAnchor end;

  bool get isCollapsed =>
      start.chunkIndex == end.chunkIndex &&
      start.localOffset == end.localOffset;
}

/// Per-chunk registration record (internal).
class _ChunkRegistration {
  _ChunkRegistration({
    required this.chunkIndex,
    required this.renderKey,
    required this.charCount,
  });

  final int chunkIndex;
  final GlobalKey renderKey;
  int charCount; // may be updated on re-layout
}

// ──────────────────────────────────────────────────────────────────────────────
// Controller
// ──────────────────────────────────────────────────────────────────────────────

/// Manages text selection that spans multiple [RenderHyperBox] chunks in a
/// virtualised [ListView].
///
/// Each mounted [_VirtualizedChunk] registers itself on first layout. The
/// controller translates [CrossChunkSelection] into per-chunk
/// [HyperTextSelection] values and keeps the overlay notified of handle/menu
/// positions.
class VirtualizedSelectionController extends ChangeNotifier {
  VirtualizedSelectionController({
    required this.sectionsGetter,
    required this.listViewKey,
  });

  /// Returns the live [DocumentNode] sections list — used to extract text from
  /// off-screen chunks (no live [RenderHyperBox] available).
  final List<DocumentNode> Function() sectionsGetter;

  /// Key on the [ListView] (or the [Stack] containing it) used as the ancestor
  /// for coordinate conversions.
  final GlobalKey listViewKey;

  CrossChunkSelection? _selection;
  final Map<int, _ChunkRegistration> _chunks = {};

  // ── Registration ────────────────────────────────────────────────────────────

  /// Called by [_VirtualizedChunkState] after the first layout of the chunk.
  void registerChunk(int chunkIndex, GlobalKey renderKey, int charCount) {
    final existing = _chunks[chunkIndex];
    if (existing != null) {
      existing.charCount = charCount;
    } else {
      _chunks[chunkIndex] =
          _ChunkRegistration(chunkIndex: chunkIndex, renderKey: renderKey, charCount: charCount);
    }
    // Apply any pending selection to the newly-visible chunk.
    if (_selection != null) {
      _applySelectionToChunks();
    }
  }

  /// Called by [_VirtualizedChunkState.dispose].
  void unregisterChunk(int chunkIndex) {
    _chunks.remove(chunkIndex);
  }

  // ── Selection manipulation ───────────────────────────────────────────────────

  bool get hasSelection =>
      _selection != null && !_selection!.isCollapsed;

  CrossChunkSelection? get selection => _selection;

  /// Initiates a new selection at [localPositionInChunk] inside [chunkIndex].
  void startSelection(int chunkIndex, Offset localPositionInChunk) {
    final box = _getRenderBox(chunkIndex);
    if (box == null) return;
    final offset = box.getCharacterPositionAtOffset(localPositionInChunk);
    if (offset < 0) return;
    final anchor = ChunkAnchor(chunkIndex, offset);
    _selection = CrossChunkSelection(start: anchor, end: anchor);
    _applySelectionToChunks();
    notifyListeners();
  }

  /// Updates the selection as the user drags (may cross chunk boundaries).
  void updateSelectionFromHandle(bool isStartHandle, Offset globalPosition) {
    final currentSel = _selection;
    if (currentSel == null) return;

    final target = _findChunkAtGlobal(globalPosition);
    if (target == null) return;
    final (targetChunkIndex, box) = target;

    final localPos = box.globalToLocal(globalPosition);
    final localOffset =
        box.getCharacterPositionAtOffset(localPos).clamp(0, box.totalCharacterCount);

    final newAnchor = ChunkAnchor(targetChunkIndex, localOffset);

    CrossChunkSelection newSel;
    if (isStartHandle) {
      // Start handle dragged: keep end fixed, clamp start ≤ end.
      if (newAnchor <= currentSel.end) {
        newSel = CrossChunkSelection(start: newAnchor, end: currentSel.end);
      } else {
        // Dragged past end — swap handles.
        newSel = CrossChunkSelection(start: currentSel.end, end: newAnchor);
      }
    } else {
      // End handle dragged: keep start fixed, clamp end ≥ start.
      if (currentSel.start <= newAnchor) {
        newSel = CrossChunkSelection(start: currentSel.start, end: newAnchor);
      } else {
        // Dragged past start — swap handles.
        newSel = CrossChunkSelection(start: newAnchor, end: currentSel.start);
      }
    }

    _selection = newSel;
    _applySelectionToChunks();
    notifyListeners();
  }

  /// Called by [_VirtualizedChunkState] when a chunk's selection changes
  /// (e.g. handle rects moved after paint). Triggers an overlay rebuild.
  void notifyHandleRectsChanged() => notifyListeners();

  /// Selects all text across every section.
  void selectAll() {
    final sections = sectionsGetter();
    if (sections.isEmpty) return;
    _selection = CrossChunkSelection(
      start: const ChunkAnchor(0, 0),
      end: ChunkAnchor(
        sections.length - 1,
        sections.last.textContent.length,
      ),
    );
    _applySelectionToChunks();
    notifyListeners();
  }

  /// Clears all selection state across every registered chunk.
  void clearSelection() {
    _selection = null;
    for (final reg in _chunks.values) {
      _getRenderBox(reg.chunkIndex)?.clearSelection();
    }
    notifyListeners();
  }

  /// Copies selected text from all spanned chunks (including off-screen ones).
  String? getSelectedText() {
    final sel = _selection;
    if (sel == null || sel.isCollapsed) return null;

    final sections = sectionsGetter();
    final buffer = StringBuffer();

    for (int i = sel.start.chunkIndex; i <= sel.end.chunkIndex; i++) {
      if (i >= sections.length) break;
      final box = _getRenderBox(i);

      if (box != null) {
        // Live chunk — ask RenderHyperBox directly.
        final text = box.getSelectedText();
        if (text != null && text.isNotEmpty) {
          if (buffer.isNotEmpty) buffer.write('\n');
          buffer.write(text);
        }
      } else {
        // Off-screen chunk — extract raw text from DocumentNode.
        final fullText = sections[i].textContent;
        final start = (i == sel.start.chunkIndex) ? sel.start.localOffset : 0;
        final end = (i == sel.end.chunkIndex)
            ? sel.end.localOffset.clamp(0, fullText.length)
            : fullText.length;
        if (start < end) {
          if (buffer.isNotEmpty) buffer.write('\n');
          buffer.write(fullText.substring(start, end));
        }
      }
    }

    return buffer.isEmpty ? null : buffer.toString();
  }

  // ── Handle rect computation ──────────────────────────────────────────────────

  /// Start handle rect in the [listViewKey] coordinate space, or null.
  Rect? get startHandleRectInStack {
    final sel = _selection;
    if (sel == null || sel.isCollapsed) return null;
    return _toStackRect(sel.start.chunkIndex,
        _getRenderBox(sel.start.chunkIndex)?.getStartHandleRect());
  }

  /// End handle rect in the [listViewKey] coordinate space, or null.
  Rect? get endHandleRectInStack {
    final sel = _selection;
    if (sel == null || sel.isCollapsed) return null;
    return _toStackRect(sel.end.chunkIndex,
        _getRenderBox(sel.end.chunkIndex)?.getEndHandleRect());
  }

  /// The topmost selection rect across all spanned chunks, in Stack coordinates.
  /// Used to position the Copy menu above the selection.
  Rect? get topmostSelectionRectInStack {
    final sel = _selection;
    if (sel == null || sel.isCollapsed) return null;

    Rect? topmost;
    for (int i = sel.start.chunkIndex; i <= sel.end.chunkIndex; i++) {
      final rects = _getRenderBox(i)?.getSelectionRects();
      if (rects == null || rects.isEmpty) continue;
      for (final r in rects) {
        final inStack = _toStackRect(i, r);
        if (inStack == null) continue;
        if (topmost == null || inStack.top < topmost.top) {
          topmost = inStack;
        }
      }
    }
    return topmost;
  }

  // ── Private helpers ─────────────────────────────────────────────────────────

  RenderHyperBox? _getRenderBox(int chunkIndex) {
    final reg = _chunks[chunkIndex];
    if (reg == null) return null;
    final ro = reg.renderKey.currentContext?.findRenderObject();
    return ro is RenderHyperBox ? ro : null;
  }

  /// Finds which registered chunk contains [globalPosition] and returns it.
  (int, RenderHyperBox)? _findChunkAtGlobal(Offset globalPosition) {
    for (final reg in _chunks.values) {
      final box = _getRenderBox(reg.chunkIndex);
      if (box == null || !box.attached) continue;
      final globalRect = Rect.fromPoints(
        box.localToGlobal(Offset.zero),
        box.localToGlobal(Offset(box.size.width, box.size.height)),
      );
      if (globalRect.contains(globalPosition)) {
        return (reg.chunkIndex, box);
      }
    }
    // Fallback: find the closest chunk vertically (handles drag beyond edges).
    _ChunkRegistration? closest;
    double closestDist = double.infinity;
    for (final reg in _chunks.values) {
      final box = _getRenderBox(reg.chunkIndex);
      if (box == null || !box.attached) continue;
      final globalRect = Rect.fromPoints(
        box.localToGlobal(Offset.zero),
        box.localToGlobal(Offset(box.size.width, box.size.height)),
      );
      final dist = (globalPosition.dy - globalRect.center.dy).abs();
      if (dist < closestDist) {
        closestDist = dist;
        closest = reg;
      }
    }
    if (closest == null) return null;
    final box = _getRenderBox(closest.chunkIndex);
    return box != null ? (closest.chunkIndex, box) : null;
  }

  /// Converts a chunk-local [rect] to the [listViewKey] Stack coordinate space.
  Rect? _toStackRect(int chunkIndex, Rect? localRect) {
    if (localRect == null) return null;
    final box = _getRenderBox(chunkIndex);
    if (box == null || !box.attached) return null;
    final stackBox = listViewKey.currentContext?.findRenderObject() as RenderBox?;
    if (stackBox == null || !stackBox.attached) return null;
    final topLeft = box.localToGlobal(localRect.topLeft, ancestor: stackBox);
    final bottomRight =
        box.localToGlobal(localRect.bottomRight, ancestor: stackBox);
    return Rect.fromPoints(topLeft, bottomRight);
  }

  /// Translates [_selection] into per-chunk [HyperTextSelection] values and
  /// applies them to every live chunk.
  void _applySelectionToChunks() {
    final sel = _selection;
    for (final reg in _chunks.values) {
      final box = _getRenderBox(reg.chunkIndex);
      if (box == null) continue;
      if (sel == null) {
        box.clearSelection();
        continue;
      }
      final i = reg.chunkIndex;
      if (i < sel.start.chunkIndex || i > sel.end.chunkIndex) {
        box.clearSelection();
      } else if (sel.start.chunkIndex == sel.end.chunkIndex && i == sel.start.chunkIndex) {
        box.selection = HyperTextSelection(
            start: sel.start.localOffset, end: sel.end.localOffset);
      } else if (i == sel.start.chunkIndex) {
        box.selection =
            HyperTextSelection(start: sel.start.localOffset, end: box.totalCharacterCount);
      } else if (i == sel.end.chunkIndex) {
        box.selection =
            HyperTextSelection(start: 0, end: sel.end.localOffset);
      } else {
        box.selection =
            HyperTextSelection(start: 0, end: box.totalCharacterCount);
      }
    }
  }
}
