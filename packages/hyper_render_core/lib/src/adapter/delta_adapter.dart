import 'dart:convert';
import 'package:flutter/painting.dart';
import '../interfaces/content_parser.dart';
import '../model/node.dart';
import '../model/computed_style.dart';

/// Adapter for Quill Delta JSON content
class DeltaAdapter extends ContentParser {
  @override
  ContentType get contentType => ContentType.delta;

  @override
  DocumentNode parse(String content) {
    if (content.isEmpty) return DocumentNode();

    try {
      final Map<String, dynamic> delta = jsonDecode(content);
      final List<dynamic> ops = delta['ops'] ?? [];
      
      final root = DocumentNode();
      
      for (final op in ops) {
        final insert = op['insert'];
        if (insert == null) continue;
        
        final attributes = op['attributes'] as Map<String, dynamic>?;
        
          if (insert is String) {
            final textNode = TextNode(insert);
            if (attributes != null) {
              _applyAttributes(textNode.style, attributes);
            }
            root.appendChild(textNode);
          } else if (insert is Map<String, dynamic>) {
            // Handle embeds (formula, image, etc.)
            final type = insert.keys.first;
            final value = insert[type];
            
            if (type == 'formula') {
              final formulaNode = InlineNode(tagName: 'formula', attributes: {'value': value.toString()});
              root.appendChild(formulaNode);
            } else if (type == 'image') {
              final imageNode = AtomicNode(tagName: 'img', src: value.toString());
              root.appendChild(imageNode);
            }
          }
      }
      
      return root;
    } catch (e) {
      // P0-4: JSON error handling - Return empty DocumentNode on error
      return DocumentNode();
    }
  }

  void _applyAttributes(ComputedStyle style, Map<String, dynamic> attributes) {
    if (attributes['bold'] == true) style.fontWeight = FontWeight.bold;
    if (attributes['italic'] == true) style.fontStyle = FontStyle.italic;
    if (attributes['color'] != null) {
      // Simple color parsing
      final colorStr = attributes['color'].toString();
      if (colorStr.startsWith('#')) {
        final hex = colorStr.replaceFirst('#', '');
        if (hex.length == 6) {
          style.color = Color(int.parse('0xFF$hex'));
        } else if (hex.length == 8) {
          style.color = Color(int.parse('0x$hex'));
        }
      }
    }
    if (attributes['size'] != null) {
      final size = attributes['size'].toString();
      if (size == 'small') style.fontSize = 12;
      else if (size == 'large') style.fontSize = 18;
      else if (size == 'huge') style.fontSize = 24;
    }
  }
}
