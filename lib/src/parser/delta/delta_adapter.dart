import 'dart:convert';

import 'package:flutter/painting.dart';

import '../../model/computed_style.dart';
import '../../model/node.dart';
import '../adapter.dart';

/// Quill Delta to UDT adapter
///
/// Converts Quill Delta JSON format into Unified Document Tree.
/// Quill Delta is a format used by Quill.js rich text editor.
///
/// ## Delta Format
///
/// ```json
/// {
///   "ops": [
///     { "insert": "Hello " },
///     { "insert": "World", "attributes": { "bold": true } },
///     { "insert": "\n" }
///   ]
/// }
/// ```
///
/// ## Supported Attributes
///
/// - bold: Bold text
/// - italic: Italic text
/// - underline: Underlined text
/// - strike: Strikethrough text
/// - color: Text color (hex or named)
/// - background: Background color
/// - font: Font family
/// - size: Font size (small, normal, large, huge or custom)
/// - link: Hyperlink
/// - header: Heading level (1-6)
/// - list: List type (ordered, bullet)
/// - align: Text alignment (left, center, right, justify)
/// - indent: Indentation level
/// - code-block: Code block
/// - blockquote: Block quote
/// - image: Embedded image
/// - video: Embedded video
///
/// Reference: https://quilljs.com/docs/delta/
class DeltaAdapter extends ExtendedDocumentAdapter {
  @override
  InputType get inputType => InputType.delta;

  @override
  AdapterResult parseExtended(String content) {
    final stopwatch = Stopwatch()..start();
    final warnings = <String>[];

    try {
      // Parse JSON
      final json = jsonDecode(content);
      if (json is! Map<String, dynamic>) {
        warnings.add('Delta content is not a valid JSON object');
        return AdapterResult(
          document: DocumentNode(),
          warnings: warnings,
          parseDuration: stopwatch.elapsed,
        );
      }

      // Get ops array
      final ops = json['ops'];
      if (ops is! List) {
        warnings.add('Delta content has no ops array');
        return AdapterResult(
          document: DocumentNode(),
          warnings: warnings,
          parseDuration: stopwatch.elapsed,
        );
      }

      // Convert ops to UDT
      final document = _convertOps(ops.cast<Map<String, dynamic>>(), warnings);

      stopwatch.stop();

      return AdapterResult(
        document: document,
        warnings: warnings,
        parseDuration: stopwatch.elapsed,
      );
    } catch (e) {
      warnings.add('Failed to parse Delta: $e');
      return AdapterResult(
        document: DocumentNode(),
        warnings: warnings,
        parseDuration: stopwatch.elapsed,
      );
    }
  }

  /// Convert ops array to DocumentNode
  DocumentNode _convertOps(
      List<Map<String, dynamic>> ops, List<String> warnings) {
    final blocks = <UDTNode>[];
    final currentLine = <UDTNode>[];
    Map<String, dynamic>? lineAttributes;

    for (final op in ops) {
      final insert = op['insert'];
      final attributes = op['attributes'] as Map<String, dynamic>?;

      if (insert is String) {
        // Text insert
        if (insert == '\n') {
          // End of line - create block with collected inline nodes
          lineAttributes = attributes;
          _flushLine(blocks, currentLine, lineAttributes, warnings);
          lineAttributes = null;
        } else if (insert.contains('\n')) {
          // Multiple lines in one insert
          final lines = insert.split('\n');
          for (int i = 0; i < lines.length; i++) {
            final line = lines[i];
            if (line.isNotEmpty) {
              currentLine.add(_createTextNode(line, attributes));
            }
            if (i < lines.length - 1) {
              _flushLine(blocks, currentLine, lineAttributes, warnings);
            }
          }
        } else {
          // Regular text
          currentLine.add(_createTextNode(insert, attributes));
        }
      } else if (insert is Map<String, dynamic>) {
        // Embed insert (image, video, etc.)
        final embedNode = _createEmbedNode(insert, attributes, warnings);
        if (embedNode != null) {
          currentLine.add(embedNode);
        }
      }
    }

    // Flush remaining content
    if (currentLine.isNotEmpty) {
      _flushLine(blocks, currentLine, null, warnings);
    }

    return DocumentNode(children: blocks);
  }

  /// Flush current line content to blocks
  void _flushLine(
    List<UDTNode> blocks,
    List<UDTNode> currentLine,
    Map<String, dynamic>? lineAttributes,
    List<String> warnings,
  ) {
    if (currentLine.isEmpty) {
      // Empty line - add line break
      blocks.add(BlockNode(
        tagName: 'p',
        children: [LineBreakNode()],
      ));
    } else {
      // Create block node based on line attributes
      final block = _createBlockNode(
        List.from(currentLine),
        lineAttributes,
        warnings,
      );
      blocks.add(block);
    }

    currentLine.clear();
  }

  /// Create text node with attributes
  UDTNode _createTextNode(String text, Map<String, dynamic>? attributes) {
    if (attributes == null || attributes.isEmpty) {
      return TextNode(text);
    }

    // Create inline node with style
    final style = _attributesToStyle(attributes);
    final textNode = TextNode(text, style: style);

    // Handle link
    if (attributes.containsKey('link')) {
      return InlineNode(
        tagName: 'a',
        attributes: {'href': attributes['link'].toString()},
        style: style.copyWith(
          color: const Color(0xFF0000EE),
          textDecoration: TextDecoration.underline,
        ),
        children: [textNode],
      );
    }

    // Check if we need to wrap in inline node
    if (_hasInlineFormatting(attributes)) {
      return InlineNode(
        tagName: 'span',
        style: style,
        children: [TextNode(text)],
      );
    }

    return textNode;
  }

  /// Create block node based on line attributes
  UDTNode _createBlockNode(
    List<UDTNode> children,
    Map<String, dynamic>? attributes,
    List<String> warnings,
  ) {
    if (attributes == null || attributes.isEmpty) {
      return BlockNode(tagName: 'p', children: children);
    }

    // Header
    if (attributes.containsKey('header')) {
      final level = attributes['header'];
      final lvl = (int.tryParse(level.toString()) ?? 1).clamp(1, 6);
      final tagName = 'h$lvl';
      return BlockNode(
        tagName: tagName,
        style: _getHeadingStyle(lvl),
        children: children,
      );
    }

    // List
    if (attributes.containsKey('list')) {
      final listType = attributes['list'];
      final isOrdered = listType == 'ordered';
      return BlockNode(
        tagName: 'li',
        attributes: {'data-list-type': isOrdered ? 'ordered' : 'bullet'},
        style: ComputedStyle(
          display: DisplayType.block,
          padding: EdgeInsets.only(
            left: 20.0 * ((attributes['indent'] as int?) ?? 0 + 1),
          ),
        ),
        children: children,
      );
    }

    // Code block
    if (attributes.containsKey('code-block')) {
      return BlockNode(
        tagName: 'pre',
        style: ComputedStyle(
          display: DisplayType.block,
          fontFamily: 'monospace',
          backgroundColor: const Color(0xFFF5F5F5),
          padding: const EdgeInsets.all(12),
        ),
        children: children,
      );
    }

    // Block quote
    if (attributes.containsKey('blockquote')) {
      return BlockNode(
        tagName: 'blockquote',
        style: ComputedStyle(
          display: DisplayType.block,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          borderWidth: const EdgeInsets.only(left: 4),
          borderColor: const Color(0xFFCCCCCC),
          backgroundColor: const Color(0xFFF9F9F9),
        ),
        children: children,
      );
    }

    // Text alignment
    HyperTextAlign? textAlign;
    if (attributes.containsKey('align')) {
      textAlign = _parseTextAlign(attributes['align'].toString());
    }

    // Indentation
    double leftPadding = 0;
    if (attributes.containsKey('indent')) {
      leftPadding = 40.0 * (attributes['indent'] as int);
    }

    return BlockNode(
      tagName: 'p',
      style: ComputedStyle(
        display: DisplayType.block,
        textAlign: textAlign ?? HyperTextAlign.left,
        padding: EdgeInsets.only(left: leftPadding),
      ),
      children: children,
    );
  }

  /// Create embed node (image, video, etc.)
  UDTNode? _createEmbedNode(
    Map<String, dynamic> embed,
    Map<String, dynamic>? attributes,
    List<String> warnings,
  ) {
    // Image
    if (embed.containsKey('image')) {
      final src = embed['image'].toString();
      return AtomicNode.img(
        src: src,
        alt: attributes?['alt']?.toString(),
        width: _parseDouble(embed['width']),
        height: _parseDouble(embed['height']),
      );
    }

    // Video
    if (embed.containsKey('video')) {
      final src = embed['video'].toString();
      return AtomicNode.video(
        src: src,
        width: _parseDouble(embed['width']),
        height: _parseDouble(embed['height']),
      );
    }

    // Formula (LaTeX)
    if (embed.containsKey('formula')) {
      final formula = embed['formula'].toString();
      return AtomicNode(
        tagName: 'formula',
        src: formula,
        attributes: {
          'formula': formula,
          'type': 'latex',
        },
      );
    }

    warnings.add('Unknown embed type: ${embed.keys.first}');
    return null;
  }

  /// Convert Delta attributes to ComputedStyle
  ComputedStyle _attributesToStyle(Map<String, dynamic> attributes) {
    var style = ComputedStyle();

    // Bold
    if (attributes['bold'] == true) {
      style = style.copyWith(fontWeight: FontWeight.bold);
    }

    // Italic
    if (attributes['italic'] == true) {
      style = style.copyWith(fontStyle: FontStyle.italic);
    }

    // Underline
    if (attributes['underline'] == true) {
      style.textDecoration = TextDecoration.underline;
    }

    // Strike
    if (attributes['strike'] == true) {
      style.textDecoration = TextDecoration.lineThrough;
    }

    // Color
    if (attributes.containsKey('color')) {
      final color = _parseColor(attributes['color'].toString());
      if (color != null) {
        style = style.copyWith(color: color);
      }
    }

    // Background color
    if (attributes.containsKey('background')) {
      final bgColor = _parseColor(attributes['background'].toString());
      if (bgColor != null) {
        style = style.copyWith(backgroundColor: bgColor);
      }
    }

    // Font family
    if (attributes.containsKey('font')) {
      style.fontFamily = attributes['font'].toString();
    }

    // Font size
    if (attributes.containsKey('size')) {
      final size = _parseFontSize(attributes['size']);
      if (size != null) {
        style = style.copyWith(fontSize: size);
      }
    }

    return style;
  }

  /// Check if attributes have inline formatting
  bool _hasInlineFormatting(Map<String, dynamic> attributes) {
    return attributes.containsKey('bold') ||
        attributes.containsKey('italic') ||
        attributes.containsKey('underline') ||
        attributes.containsKey('strike') ||
        attributes.containsKey('color') ||
        attributes.containsKey('background') ||
        attributes.containsKey('font') ||
        attributes.containsKey('size');
  }

  /// Get heading style
  ComputedStyle _getHeadingStyle(dynamic level) {
    final lvl = int.tryParse(level.toString()) ?? 1;
    switch (lvl) {
      case 1:
        return ComputedStyle(
          display: DisplayType.block,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        );
      case 2:
        return ComputedStyle(
          display: DisplayType.block,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        );
      case 3:
        return ComputedStyle(
          display: DisplayType.block,
          fontSize: 18.72,
          fontWeight: FontWeight.bold,
        );
      case 4:
        return ComputedStyle(
          display: DisplayType.block,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        );
      case 5:
        return ComputedStyle(
          display: DisplayType.block,
          fontSize: 13.28,
          fontWeight: FontWeight.bold,
        );
      case 6:
        return ComputedStyle(
          display: DisplayType.block,
          fontSize: 10.72,
          fontWeight: FontWeight.bold,
        );
      default:
        return ComputedStyle(display: DisplayType.block);
    }
  }

  /// Parse text alignment
  HyperTextAlign _parseTextAlign(String value) {
    switch (value.toLowerCase()) {
      case 'center':
        return HyperTextAlign.center;
      case 'right':
        return HyperTextAlign.right;
      case 'justify':
        return HyperTextAlign.justify;
      default:
        return HyperTextAlign.left;
    }
  }

  /// Parse color from string (hex or named)
  Color? _parseColor(String value) {
    // Hex color
    if (value.startsWith('#')) {
      final hex = value.substring(1);
      if (hex.length == 6) {
        final intValue = int.tryParse(hex, radix: 16);
        if (intValue != null) {
          return Color(0xFF000000 | intValue);
        }
      } else if (hex.length == 8) {
        final intValue = int.tryParse(hex, radix: 16);
        if (intValue != null) {
          return Color(intValue);
        }
      }
    }

    // Named colors (common ones)
    final namedColors = {
      'red': const Color(0xFFFF0000),
      'green': const Color(0xFF00FF00),
      'blue': const Color(0xFF0000FF),
      'black': const Color(0xFF000000),
      'white': const Color(0xFFFFFFFF),
      'yellow': const Color(0xFFFFFF00),
      'orange': const Color(0xFFFFA500),
      'purple': const Color(0xFF800080),
      'pink': const Color(0xFFFFC0CB),
      'gray': const Color(0xFF808080),
      'grey': const Color(0xFF808080),
    };

    return namedColors[value.toLowerCase()];
  }

  /// Parse font size (small, normal, large, huge or numeric)
  double? _parseFontSize(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    final strValue = value.toString().toLowerCase();
    switch (strValue) {
      case 'small':
        return 10;
      case 'normal':
        return 13;
      case 'large':
        return 18;
      case 'huge':
        return 32;
      default:
        // Try parsing as number with px suffix
        final cleaned = strValue.replaceAll(RegExp(r'px$'), '');
        return double.tryParse(cleaned);
    }
  }

  /// Parse double from dynamic value
  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}
