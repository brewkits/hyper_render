import 'package:hyper_render_core/hyper_render_core.dart';

/// Serializes UDT nodes and computed styles to JSON-compatible maps
/// for DevTools inspection.
class UdtSerializer {
  /// Serialize a [UDTNode] tree to a JSON-compatible map.
  ///
  /// Includes: id, tagName, nodeType, attributes, style properties, children.
  static Map<String, dynamic> serializeNode(UDTNode node, {int depth = 0}) {
    final map = <String, dynamic>{
      'id': node.id,
      'type': node.type.name,
      'tagName': node.tagName ?? '(text)',
      'attributes': Map<String, String>.from(node.attributes),
      'style': serializeStyle(node.style),
      'childCount': node.children.length,
    };

    // Add text content for text nodes
    if (node is TextNode) {
      map['text'] = node.text.substring(0, node.text.length.clamp(0, 200));
    }

    // Add atomic node fields
    if (node is AtomicNode) {
      map['src'] = node.src;
      map['alt'] = node.alt;
      map['intrinsicWidth'] = node.intrinsicWidth;
      map['intrinsicHeight'] = node.intrinsicHeight;
    }

    // Recurse into children (limit depth to avoid huge payloads)
    if (depth < 20) {
      map['children'] = node.children
          .map((child) => serializeNode(child, depth: depth + 1))
          .toList();
    } else {
      map['children'] = <dynamic>[];
      map['childrenTruncated'] = true;
    }

    return map;
  }

  /// Serialize a [ComputedStyle] to a JSON-compatible map.
  static Map<String, dynamic> serializeStyle(ComputedStyle style) {
    return <String, dynamic>{
      // Box model
      'width': style.width,
      'height': style.height,
      'minWidth': style.minWidth,
      'maxWidth': style.maxWidth,
      'margin': _edgeInsetsToMap(style.margin),
      'padding': _edgeInsetsToMap(style.padding),
      'borderWidth': _edgeInsetsToMap(style.borderWidth),
      'borderColor': style.borderColor?.toARGB32(),
      'borderRadius': style.borderRadius?.toString(),
      // Text
      'color': style.color.toARGB32(),
      'fontSize': style.fontSize,
      'fontWeight': style.fontWeight.index,
      'fontStyle': style.fontStyle.index,
      'fontFamily': style.fontFamily,
      'lineHeight': style.lineHeight,
      'letterSpacing': style.letterSpacing,
      'textAlign': style.textAlign.name,
      // Layout
      'display': style.display.name,
      'position': style.position,
      'float': style.float.name,
      'opacity': style.opacity,
      // Background
      'backgroundColor': style.backgroundColor?.toARGB32(),
      // Grid
      'gridTemplateColumns': style.gridTemplateColumns,
      'gridTemplateRows': style.gridTemplateRows,
      'gridColumnSpan': style.gridColumnSpan,
      'gridRowSpan': style.gridRowSpan,
      // CSS Variables
      'customProperties': Map<String, String>.from(style.customProperties),
    };
  }

  static Map<String, double> _edgeInsetsToMap(dynamic edgeInsets) {
    if (edgeInsets == null) return {};
    try {
      final e = edgeInsets as dynamic;
      return {
        'top': (e.top as num).toDouble(),
        'right': (e.right as num).toDouble(),
        'bottom': (e.bottom as num).toDouble(),
        'left': (e.left as num).toDouble(),
      };
    } catch (_) {
      return {};
    }
  }

  /// Serialize a list of nodes to a flat JSON array (for the tree view).
  static List<Map<String, dynamic>> serializeTree(DocumentNode document) {
    return [serializeNode(document)];
  }
}
