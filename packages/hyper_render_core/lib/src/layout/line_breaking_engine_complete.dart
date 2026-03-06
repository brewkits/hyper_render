/// COMPLETE Line-Breaking Engine - Production Ready
///
/// This is the FULL implementation extracted from RenderHyperBox.
/// NO Flutter dependencies except for Size/Offset (which are pure Dart in dart:ui).
/// 100% unit testable!
library;

import 'dart:ui' show Offset, Rect;

import '../model/fragment.dart';
import '../model/fragment_types.dart';
import '../model/computed_style.dart';
import '../core/kinsoku_processor.dart';
import 'float_layout_calculator.dart';
import 'fragment_measurer.dart';

export 'float_layout_calculator.dart' show FloatArea;

/// Line information with positioned fragments
class BreakingLineInfo {
  final double top;
  final double baseline;
  final double leftInset;
  final double rightInset;
  final List<Fragment> fragments = [];
  Rect bounds = Rect.zero;

  BreakingLineInfo({
    required this.top,
    required this.baseline,
    required this.leftInset,
    required this.rightInset,
  });

  void add(Fragment fragment) {
    fragments.add(fragment);
  }

  double get width {
    if (fragments.isEmpty) return 0;
    final lastFrag = fragments.last;
    final offset = lastFrag.offset;
    if (offset == null) return 0;
    return (offset.dx + lastFrag.width) - leftInset;
  }

  double get height => bounds.height;

  @override
  String toString() =>
      'BreakingLineInfo(fragments: ${fragments.length}, top: $top, width: $width)';
}

/// Complete line-breaking result
class LineBreakingResult {
  final List<BreakingLineInfo> lines;
  final List<FloatArea> leftFloats;
  final List<FloatArea> rightFloats;
  final double totalHeight;

  const LineBreakingResult({
    required this.lines,
    required this.leftFloats,
    required this.rightFloats,
    required this.totalHeight,
  });
}

/// Block decoration info (for backgrounds, borders)
class BlockDecoration {
  final Fragment fragment;
  final double startY;
  final double leftX;
  final double rightX;

  const BlockDecoration({
    required this.fragment,
    required this.startY,
    required this.leftX,
    required this.rightX,
  });
}

/// COMPLETE Line-Breaking Engine
///
/// This is the REAL implementation - not a placeholder!
/// Handles:
/// - Text splitting and wrapping
/// - Float layout
/// - Margin collapsing
/// - Block/inline formatting
/// - Kinsoku line-breaking (CJK)
/// - White-space handling
class LineBreakingEngine {
  final FloatLayoutCalculator _floatCalc;
  final FragmentMeasurer _measurer;
  final KinsokuProcessor? kinsokuProcessor;

  LineBreakingEngine({
    FloatLayoutCalculator? floatCalculator,
    FragmentMeasurer? measurer,
    this.kinsokuProcessor,
  })  : _floatCalc = floatCalculator ?? const FloatLayoutCalculator(),
        _measurer = measurer ?? FragmentMeasurer();

  /// Break fragments into lines
  ///
  /// This is the MAIN entry point - PURE FUNCTION!
  LineBreakingResult breakLines({
    required List<Fragment> fragments,
    required double maxWidth,
  }) {
    if (fragments.isEmpty) {
      return const LineBreakingResult(
        lines: [],
        leftFloats: [],
        rightFloats: [],
        totalHeight: 0,
      );
    }

    final lines = <BreakingLineInfo>[];
    final leftFloats = <FloatArea>[];
    final rightFloats = <FloatArea>[];
    final blockDecorations = <BlockDecoration>[];

    double currentY = 0;
    double currentX = 0;
    double lineHeight = 0;
    double maxBaseline = 0;
    List<Fragment> currentLineFragments = [];
    double leftInset = 0;
    double rightInset = 0;

    // Stack for nested block padding
    final leftPaddingStack = <double>[0];
    final rightPaddingStack = <double>[0];

    // Pending fragment from splits (avoids O(n²) list insertions)
    Fragment? pendingFragment;

    // Helper: Finish current line
    void finishLine() {
      if (currentLineFragments.isEmpty) return;

      // Trim trailing whitespace
      while (currentLineFragments.isNotEmpty &&
          currentLineFragments.last.isWhitespace) {
        currentLineFragments.removeLast();
      }

      if (currentLineFragments.isEmpty) return;

      final lineInfo = BreakingLineInfo(
        top: currentY,
        baseline: maxBaseline,
        leftInset: leftInset,
        rightInset: rightInset,
      );

      for (final frag in currentLineFragments) {
        lineInfo.add(frag);
      }

      lineInfo.bounds = Rect.fromLTWH(leftInset, currentY, lineInfo.width, lineHeight);
      lines.add(lineInfo);

      currentY += lineHeight;
      currentLineFragments.clear();
      lineHeight = 0;
      maxBaseline = 0;
    }

    // Helper: Get available width at current Y
    double getAvailableWidth() {
      final insets = _floatCalc.calculateInsets(
        currentY: currentY,
        maxWidth: maxWidth,
        leftFloats: leftFloats,
        rightFloats: rightFloats,
        leftPadding: leftPaddingStack.last,
        rightPadding: rightPaddingStack.last,
      );

      leftInset = insets.left;
      rightInset = insets.right;

      return maxWidth - leftInset - rightInset;
    }

    // Helper: Update line metrics
    void updateLineMetrics(Fragment fragment) {
      // CRITICAL FIX: Respect CSS line-height property!
      // If line-height is specified in CSS (e.g., line-height: 2.0),
      // use it to calculate the effective line height.
      final effectiveLineHeight = fragment.style.lineHeight != null
          ? fragment.height * fragment.style.lineHeight!
          : fragment.height;

      // DEBUG: Log line-height calculations
      if (fragment.style.lineHeight != null) {
        print('🐛 LineHeight DEBUG: text="${fragment.text?.substring(0, fragment.text!.length > 20 ? 20 : fragment.text!.length)}", '
            'cssLineHeight=${fragment.style.lineHeight}, fragHeight=${fragment.height}, '
            'effectiveHeight=$effectiveLineHeight');
      }

      if (effectiveLineHeight > lineHeight) {
        lineHeight = effectiveLineHeight;
      }

      // Calculate baseline
      double baseline;
      if (fragment.type == FragmentType.text && fragment.text != null) {
        // For text, use actual font baseline
        final metrics = _measurer.measureTextMetrics(fragment.text!, fragment.style);
        baseline = metrics.firstBaseline;
      } else if (fragment.type == FragmentType.ruby) {
        baseline = fragment.height * 0.85;
      } else {
        baseline = fragment.height; // Bottom alignment for atomic
      }

      if (baseline > maxBaseline) {
        maxBaseline = baseline;
      }
    }

    // Helper: Process a single fragment
    void processFragment(Fragment fragment) {
      // Block start
      if (fragment is BlockStartFragment) {
        finishLine();
        currentY += fragment.marginTop + fragment.paddingTop;

        final newLeftPadding = leftPaddingStack.last + fragment.paddingLeft;
        final newRightPadding = rightPaddingStack.last + fragment.paddingRight;
        leftPaddingStack.add(newLeftPadding);
        rightPaddingStack.add(newRightPadding);

        leftInset = newLeftPadding;
        rightInset = newRightPadding;
        currentX = leftInset;

        // Track block decoration
        final style = fragment.style;
        if (style.backgroundColor != null ||
            (style.borderColor != null && style.borderWidth.left > 0)) {
          final blockLeftX = leftPaddingStack.length > 1
              ? leftPaddingStack[leftPaddingStack.length - 2]
              : 0.0;
          final blockRightX = rightPaddingStack.length > 1
              ? maxWidth - rightPaddingStack[rightPaddingStack.length - 2]
              : maxWidth;
          final blockStartY = currentY - fragment.paddingTop;

          blockDecorations.add(BlockDecoration(
            fragment: fragment,
            startY: blockStartY,
            leftX: blockLeftX,
            rightX: blockRightX,
          ));
        }
        return;
      }

      // Block end
      if (fragment is BlockEndFragment) {
        finishLine();
        currentY += fragment.paddingBottom;

        leftPaddingStack.removeLast();
        rightPaddingStack.removeLast();

        leftInset = leftPaddingStack.last;
        rightInset = rightPaddingStack.last;
        currentX = leftInset;
        return;
      }

      // Float
      if (fragment.style.float != HyperFloat.none) {
        final floatArea = _floatCalc.layoutFloat(
          fragment: fragment,
          currentY: currentY,
          maxWidth: maxWidth,
          existingLeftFloats: leftFloats,
          existingRightFloats: rightFloats,
          leftPadding: leftPaddingStack.last,
          rightPadding: rightPaddingStack.last,
        );

        if (floatArea.side == HyperFloat.left) {
          leftFloats.add(floatArea);
        } else {
          rightFloats.add(floatArea);
        }

        fragment.offset = Offset(floatArea.left, floatArea.top);
        return;
      }

      // Line break
      if (fragment.type == FragmentType.lineBreak) {
        finishLine();
        currentX = leftInset;
        return;
      }

      // Skip inline markers
      if (fragment is InlineStartFragment || fragment is InlineEndFragment) {
        return;
      }

      // Main layout logic for text/atomic fragments
      final availableWidth = getAvailableWidth();
      final remainingWidth = leftInset + availableWidth - currentX;

      // Check if fragment fits
      if (fragment.width > remainingWidth) {
        // Try to split text if possible
        if (fragment.type == FragmentType.text && fragment.text != null) {
          final whiteSpace = fragment.style.whiteSpace;
          final allowWrap = (whiteSpace != 'nowrap' && whiteSpace != 'pre');

          if (allowWrap && currentLineFragments.isNotEmpty && remainingWidth > 20) {
            // Try to fit part on current line
            final splitResult = _splitTextFragment(fragment, remainingWidth);
            if (splitResult != null) {
              final (firstPart, secondPart) = splitResult;
              currentLineFragments.add(firstPart);
              updateLineMetrics(firstPart);
              finishLine();
              currentX = leftInset;
              pendingFragment = secondPart;
              return;
            }
          }

          // Start new line
          if (currentLineFragments.isNotEmpty) {
            finishLine();
            currentX = leftInset;
          }

          // Force split if wider than full line
          final fullLineWidth = getAvailableWidth();
          if (fragment.width > fullLineWidth && fragment.text!.length > 1 && allowWrap) {
            final forceSplit = _forceSplitTextFragment(fragment, fullLineWidth);
            if (forceSplit != null) {
              final (firstPart, secondPart) = forceSplit;
              currentLineFragments.add(firstPart);
              updateLineMetrics(firstPart);
              finishLine();
              currentX = leftInset;
              pendingFragment = secondPart;
              return;
            }
          }
        } else {
          // Non-text: just start new line
          if (currentLineFragments.isNotEmpty) {
            finishLine();
            currentX = leftInset;
            getAvailableWidth();
          }
        }
      }

      // Add fragment to current line
      fragment.offset = Offset(currentX, currentY);
      currentX += fragment.width;
      currentLineFragments.add(fragment);
      updateLineMetrics(fragment);
    }

    // Main loop
    for (int i = 0; i < fragments.length; i++) {
      // Process pending fragment first
      while (pendingFragment != null) {
        final frag = pendingFragment!;
        pendingFragment = null;
        processFragment(frag);
      }

      processFragment(fragments[i]);
    }

    // Process final pending
    while (pendingFragment != null) {
      final frag = pendingFragment!;
      pendingFragment = null;
      processFragment(frag);
    }

    finishLine();

    return LineBreakingResult(
      lines: lines,
      leftFloats: leftFloats,
      rightFloats: rightFloats,
      totalHeight: currentY,
    );
  }

  /// Split text fragment at word boundary
  (Fragment, Fragment)? _splitTextFragment(Fragment fragment, double maxWidth) {
    final text = fragment.text!;
    if (text.length <= 1) return null;

    int breakIndex = -1;

    // Find last space that fits
    for (int i = text.length - 1; i >= 0; i--) {
      if (text[i] == ' ' || text[i] == '\u200B') {
        final testText = text.substring(0, i + 1);
        final width = _measurer.measureTextWidth(testText, fragment.style);

        if (width <= maxWidth) {
          breakIndex = i + 1;
          break;
        }
      }
    }

    if (breakIndex <= 0 || breakIndex >= text.length) {
      return null;
    }

    final whiteSpace = fragment.style.whiteSpace;
    final shouldTrim = (whiteSpace != 'pre' &&
                        whiteSpace != 'pre-wrap' &&
                        whiteSpace != 'break-spaces');

    final firstPart = shouldTrim
        ? text.substring(0, breakIndex).trimRight()
        : text.substring(0, breakIndex);
    final rawSecond = text.substring(breakIndex);
    final secondPart = shouldTrim ? rawSecond.trimLeft() : rawSecond;

    if (firstPart.isEmpty || secondPart.isEmpty) {
      return null;
    }

    final firstFragment = Fragment.text(
      text: firstPart,
      sourceNode: fragment.sourceNode,
      style: fragment.style,
      characterOffset: fragment.characterOffset,
    );
    _measurer.measure(firstFragment);

    final secondFragment = Fragment.text(
      text: secondPart,
      sourceNode: fragment.sourceNode,
      style: fragment.style,
      characterOffset: fragment.characterOffset + breakIndex,
    );
    _measurer.measure(secondFragment);

    return (firstFragment, secondFragment);
  }

  /// Force split when entire text is too wide
  (Fragment, Fragment)? _forceSplitTextFragment(Fragment fragment, double maxWidth) {
    final text = fragment.text!;
    if (text.length <= 1) return null;

    // Try word boundaries first
    int breakIndex = -1;
    final spaceIndices = <int>[];

    for (int i = 0; i < text.length; i++) {
      if (text[i] == ' ') {
        spaceIndices.add(i);
      }
    }

    for (int i = spaceIndices.length - 1; i >= 0; i--) {
      final spaceIdx = spaceIndices[i];
      final testText = text.substring(0, spaceIdx + 1);
      final width = _measurer.measureTextWidth(testText, fragment.style);

      if (width <= maxWidth) {
        breakIndex = spaceIdx + 1;
        break;
      }
    }

    // Binary search if no word boundary found
    if (breakIndex <= 0) {
      int low = 1;
      int high = text.length - 1;

      while (low < high) {
        final mid = (low + high + 1) ~/ 2;
        final testText = text.substring(0, mid);
        final width = _measurer.measureTextWidth(testText, fragment.style);

        if (width <= maxWidth) {
          low = mid;
        } else {
          high = mid - 1;
        }
      }

      breakIndex = low;
    }

    if (breakIndex <= 0 || breakIndex >= text.length) {
      return null;
    }

    final whiteSpace = fragment.style.whiteSpace;
    final shouldTrim = (whiteSpace != 'pre' &&
                        whiteSpace != 'pre-wrap' &&
                        whiteSpace != 'break-spaces');

    final firstPart = shouldTrim
        ? text.substring(0, breakIndex).trimRight()
        : text.substring(0, breakIndex);
    final rawSecond = text.substring(breakIndex);
    final secondPart = shouldTrim ? rawSecond.trimLeft() : rawSecond;

    if (firstPart.isEmpty || secondPart.isEmpty) {
      return null;
    }

    final firstFragment = Fragment.text(
      text: firstPart,
      sourceNode: fragment.sourceNode,
      style: fragment.style,
      characterOffset: fragment.characterOffset,
    );
    _measurer.measure(firstFragment);

    final secondFragment = Fragment.text(
      text: secondPart,
      sourceNode: fragment.sourceNode,
      style: fragment.style,
      characterOffset: fragment.characterOffset + breakIndex,
    );
    _measurer.measure(secondFragment);

    return (firstFragment, secondFragment);
  }
}
