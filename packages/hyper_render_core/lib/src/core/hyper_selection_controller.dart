import 'package:flutter/foundation.dart';

import 'render_hyper_box.dart';

/// Coordinates text-selection state across multiple [RenderHyperBox] instances.
///
/// When content is split into chunks (virtualized mode, multiple
/// [HyperSelectionOverlay] widgets on one screen), only one chunk should hold
/// an active selection at a time. Passing the same controller to every
/// [HyperRenderWidget] / [HyperSelectionOverlay] makes sure that selecting text
/// in chunk B automatically clears any previous selection in chunk A.
///
/// ## Usage
///
/// ```dart
/// final controller = HyperSelectionController();
///
/// HyperSelectionOverlay(document: doc1, selectionController: controller, ...)
/// HyperSelectionOverlay(document: doc2, selectionController: controller, ...)
/// ```
///
/// ## Listening to selection changes
///
/// ```dart
/// controller.addListener(() {
///   final text = controller.selectedText;
///   if (text != null) print('Selected: $text');
/// });
/// ```
class HyperSelectionController extends ChangeNotifier {
  RenderHyperBox? _activeBox;

  final Set<RenderHyperBox> _registeredBoxes = {};

  /// The [RenderHyperBox] that currently owns the selection, or null if none.
  RenderHyperBox? get activeBox => _activeBox;

  /// The currently selected text across all registered boxes, or null.
  String? get selectedText => _activeBox?.getSelectedText();

  /// Returns true if any registered box has an active (non-collapsed) selection.
  bool get hasSelection => _activeBox != null && selectedText != null;

  /// Registers [box] with this controller.
  ///
  /// Called automatically when the associated widget is mounted.  Idempotent.
  void register(RenderHyperBox box) {
    _registeredBoxes.add(box);
  }

  /// Removes [box] from this controller.
  ///
  /// Called automatically when the associated widget is unmounted.
  void unregister(RenderHyperBox box) {
    _registeredBoxes.remove(box);
    if (_activeBox == box) {
      _activeBox = null;
      notifyListeners();
    }
  }

  /// Called by a [RenderHyperBox] when it starts or updates a selection.
  ///
  /// Clears the selection in all *other* registered boxes so that only [box]
  /// has an active selection.
  void reportSelectionChanged(RenderHyperBox box) {
    if (_activeBox != box) {
      _activeBox?.clearSelection();
      _activeBox = box;
    }
    notifyListeners();
  }

  /// Clears the selection in the currently active box (if any).
  void clearSelection() {
    _activeBox?.clearSelection();
    _activeBox = null;
    notifyListeners();
  }

  /// Selects all text in [box] and makes it the active box.
  void selectAllIn(RenderHyperBox box) {
    if (_activeBox != box) {
      _activeBox?.clearSelection();
      _activeBox = box;
    }
    box.selectAll();
    notifyListeners();
  }

  @override
  void dispose() {
    _registeredBoxes.clear();
    _activeBox = null;
    super.dispose();
  }
}
