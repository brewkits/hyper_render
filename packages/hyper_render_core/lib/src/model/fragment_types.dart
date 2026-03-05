/// Special Fragment Types for Layout
///
/// These are internal fragment types used by the layout engine.
/// Extracted from RenderHyperBox to support pure Dart engines.
library;


import 'fragment.dart';
import 'computed_style.dart';

/// Block start marker fragment
class BlockStartFragment extends Fragment {
  final double marginTop;
  final double paddingTop;
  final double paddingLeft;
  final double paddingRight;

  BlockStartFragment({
    required super.sourceNode,
    required super.style,
    this.marginTop = 0,
    this.paddingTop = 0,
    this.paddingLeft = 0,
    this.paddingRight = 0,
  }) : super(type: FragmentType.text, text: '');
}

/// Block end marker fragment
class BlockEndFragment extends Fragment {
  final double marginBottom;
  final double paddingBottom;

  BlockEndFragment({
    required super.sourceNode,
    required super.style,
    this.marginBottom = 0,
    this.paddingBottom = 0,
  }) : super(type: FragmentType.text, text: '');
}

/// Float fragment (CSS float: left/right)
class FloatFragment extends Fragment {
  final HyperFloat floatDirection;

  FloatFragment({
    required super.sourceNode,
    required super.style,
    required this.floatDirection,
  }) : super(type: FragmentType.atomic);
}

/// Table fragment
class TableFragment extends Fragment {
  TableFragment({
    required super.sourceNode,
    required super.style,
  }) : super(type: FragmentType.atomic);
}

/// Code block fragment
class CodeBlockFragment extends Fragment {
  CodeBlockFragment({
    required super.sourceNode,
    required super.style,
  }) : super(type: FragmentType.atomic);
}

/// Inline start marker fragment
class InlineStartFragment extends Fragment {
  InlineStartFragment({
    required super.sourceNode,
    required super.style,
  }) : super(type: FragmentType.text, text: '');
}

/// Inline end marker fragment
class InlineEndFragment extends Fragment {
  InlineEndFragment({
    required super.sourceNode,
    required super.style,
  }) : super(type: FragmentType.text, text: '');
}

/// List marker fragment (bullets, numbers)
class ListMarkerFragment extends Fragment {
  /// The marker text (•, 1., 2., etc.)
  final String marker;

  /// Whether this is an ordered list
  final bool isOrdered;

  /// The list item index (1-based)
  final int index;

  ListMarkerFragment({
    required super.sourceNode,
    required super.style,
    required this.marker,
    required this.isOrdered,
    required this.index,
  }) : super(type: FragmentType.text, text: marker);
}
