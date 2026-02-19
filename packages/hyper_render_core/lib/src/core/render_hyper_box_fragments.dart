part of 'render_hyper_box.dart';

// ============================================
// Special Fragment Types
// ============================================

class _BlockStartFragment extends Fragment {
  final double marginTop;
  final double paddingTop;
  final double paddingLeft;
  final double paddingRight;

  _BlockStartFragment({
    required super.sourceNode,
    required super.style,
    this.marginTop = 0,
    this.paddingTop = 0,
    this.paddingLeft = 0,
    this.paddingRight = 0,
  }) : super(type: FragmentType.text, text: '');
}

class _BlockEndFragment extends Fragment {
  final double marginBottom;
  final double paddingBottom;

  _BlockEndFragment({
    required super.sourceNode,
    required super.style,
    this.marginBottom = 0,
    this.paddingBottom = 0,
  }) : super(type: FragmentType.text, text: '');
}

class _FloatFragment extends Fragment {
  final HyperFloat floatDirection;

  _FloatFragment({
    required super.sourceNode,
    required super.style,
    required this.floatDirection,
  }) : super(type: FragmentType.atomic);
}

class _TableFragment extends Fragment {
  _TableFragment({
    required super.sourceNode,
    required super.style,
  }) : super(type: FragmentType.atomic);
}

/// Fragment for code blocks (<pre> elements) that are rendered as child widgets
/// This acts as a placeholder in the fragment list, similar to _TableFragment
class _CodeBlockFragment extends Fragment {
  _CodeBlockFragment({
    required super.sourceNode,
    required super.style,
  }) : super(type: FragmentType.atomic);
}

class _InlineStartFragment extends Fragment {
  _InlineStartFragment({
    required super.sourceNode,
    required super.style,
  }) : super(type: FragmentType.text, text: '');
}

class _InlineEndFragment extends Fragment {
  _InlineEndFragment({
    required super.sourceNode,
    required super.style,
  }) : super(type: FragmentType.text, text: '');
}

/// Fragment for list markers (bullets, numbers)
class _ListMarkerFragment extends Fragment {
  /// The marker text (•, 1., 2., etc.)
  final String marker;

  /// Whether this is an ordered list
  final bool isOrdered;

  /// The list item index (1-based)
  final int index;

  _ListMarkerFragment({
    required super.sourceNode,
    required super.style,
    required this.marker,
    required this.isOrdered,
    required this.index,
  }) : super(type: FragmentType.text, text: marker);
}
