part of 'render_hyper_box.dart';

extension _RenderHyperBoxAccessibility on RenderHyperBox {
  /// Builds a plain text representation of the content for screen readers.
  ///
  /// Used by [describeSemanticsConfiguration] to populate the top-level
  /// `label` of the semantics node so that TalkBack / VoiceOver can announce
  /// the full document text even when no finer-grained semantic children are
  /// generated.
  String _buildTextContentForSemantics() {
    if (_document == null) return '';

    final buffer = StringBuffer();
    _document!.traverse((node) {
      switch (node.type) {
        case NodeType.text:
          buffer.write((node as TextNode).text);
          break;
        case NodeType.ruby:
          final ruby = node as RubyNode;
          buffer.write('${ruby.baseText} (${ruby.rubyText})');
          break;
        case NodeType.lineBreak:
          buffer.write(' ');
          break;
        case NodeType.atomic:
          final atomic = node as AtomicNode;
          if (atomic.alt != null && atomic.alt!.isNotEmpty) {
            buffer.write('[Image: ${atomic.alt}] ');
          } else if (atomic.tagName == 'img') {
            buffer.write('[Image] ');
          }
          break;
        default:
          break;
      }
    });

    return buffer.toString().trim();
  }
}
