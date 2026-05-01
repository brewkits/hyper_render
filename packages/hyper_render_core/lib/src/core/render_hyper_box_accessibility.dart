part of 'render_hyper_box.dart';

// ── Semantics virtualization constants ────────────────────────────────────────

/// Maximum semantic anchor nodes built per [RenderHyperBox].
///
/// A typical long article has ≤ 50 headings and ≤ 200 links, so this cap is
/// only reached on adversarially large documents. Headings that exceed the
/// cap are silently dropped (plain-text label still covers their content).
const int _kMaxSemanticAnchors = 200;

// ── Semantic anchor data ───────────────────────────────────────────────────

/// Describes one semantic anchor: a heading block, a link span, or an image.
class _SemanticAnchor {
  const _SemanticAnchor({
    required this.rect,
    required this.label,
    required this.isHeading,
    this.headingLevel = 0,
    this.href,
    this.isImage = false,
  });

  /// Bounding rect in the local coordinate system of [RenderHyperBox].
  final Rect rect;

  /// Accessible label announced by TalkBack / VoiceOver.
  final String label;

  /// `true` for h1–h6 blocks, `false` for `<a href>` spans or images.
  final bool isHeading;

  /// Heading level (1–6). 0 for links and images.
  final int headingLevel;

  /// Link URL. `null` for headings and images.
  final String? href;

  /// `true` when this anchor represents an `<img>` with non-empty `alt` text.
  ///
  /// Image nodes get a discrete [SemanticsNode] at the image's layout rect so
  /// screen-reader users can navigate to them element-by-element (WCAG 1.1.1
  /// Non-text Content).  They are NOT marked as links — just informational.
  final bool isImage;
}

// ── Accessibility extension ────────────────────────────────────────────────

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
          } else if (atomic.tagName == 'img' && atomic.alt == null) {
            // alt="" means decorative — intentionally silent per WCAG 1.1.1.
            // Only announce when the alt attribute is absent entirely (possible
            // accessibility gap that the author should fix).
            buffer.write('[Image] ');
          }
          break;
        default:
          break;
      }
    });

    return buffer.toString().trim();
  }

  // ── Semantic anchor collection ───────────────────────────────────────────

  /// Collects semantic anchors for all headings and links in the document.
  ///
  /// **Headings** are sourced from [headingAnchors] (populated by layout),
  /// so this does not re-walk fragments for heading detection.
  ///
  /// **Links** are found by iterating [_fragments] and walking each fragment's
  /// `sourceNode.parent` chain to detect an `<a href>` ancestor.  Consecutive
  /// fragments sharing the same anchor node are merged into one semantic node.
  ///
  /// The result is capped at [_kMaxSemanticAnchors] to guard against
  /// adversarially large documents filling the accessibility tree.
  List<_SemanticAnchor> _collectSemanticAnchors() {
    if (!hasSize) return const [];

    final anchors = <_SemanticAnchor>[];

    // ── Headings ─────────────────────────────────────────────────────────
    // headingAnchors is already populated by _performLineLayout so we just
    // convert each entry into a _SemanticAnchor with an estimated height.
    for (int i = 0; i < headingAnchors.length; i++) {
      final h = headingAnchors[i];
      // Height: span to next heading's y-offset, or document bottom.
      final nextY = (i + 1 < headingAnchors.length)
          ? headingAnchors[i + 1].yOffset
          : size.height;
      final height = (nextY - h.yOffset).clamp(16.0, double.infinity);
      anchors.add(_SemanticAnchor(
        rect: Rect.fromLTWH(0, h.yOffset, size.width, height),
        label: h.text,
        isHeading: true,
        headingLevel: h.level,
      ));
    }

    // ── Links ────────────────────────────────────────────────────────────
    // Walk fragments, grouping consecutive fragments that share the same
    // <a> ancestor node into a single semantic link node.
    String? currentAnchorId;
    String? currentHref;
    Rect? currentRect;
    final linkTextBuffer = StringBuffer();

    // anchorNode lookup cache: nodeId → UDTNode for aria-label reads.
    final Map<String, UDTNode> anchorNodeById = {};

    void flushLink() {
      if (currentAnchorId == null || currentRect == null) return;
      if (currentHref == null) {
        currentAnchorId = null;
        currentRect = null;
        linkTextBuffer.clear();
        return;
      }
      // Honor aria-label if present on the <a> element (WCAG 4.1.2).
      final anchorNode = anchorNodeById[currentAnchorId];
      final ariaLabel = anchorNode?.attributes['aria-label']?.trim();
      final label = (ariaLabel != null && ariaLabel.isNotEmpty)
          ? ariaLabel
          : linkTextBuffer.toString().trim();
      if (label.isNotEmpty) {
        anchors.add(_SemanticAnchor(
          rect: currentRect!,
          label: label,
          isHeading: false,
          href: currentHref,
        ));
      }
      currentAnchorId = null;
      currentHref = null;
      currentRect = null;
      linkTextBuffer.clear();
    }

    for (int i = 0; i < _fragments.length; i++) {
      final fragment = _fragments[i];
      // Block/inline markers carry no text; flush any open link.
      if (fragment is _BlockStartFragment ||
          fragment is _BlockEndFragment ||
          fragment is _InlineStartFragment ||
          fragment is _InlineEndFragment ||
          fragment is _ListMarkerFragment) {
        flushLink();
        continue;
      }

      // ── Image alt-text semantic nodes (WCAG 1.1.1) ──────────────────────
      if (fragment.type == FragmentType.atomic) {
        final srcNode = fragment.sourceNode;
        if (srcNode is AtomicNode &&
            srcNode.tagName == 'img' &&
            srcNode.alt != null &&
            srcNode.alt!.isNotEmpty) {
          final fRect = fragment.rect;
          if (fRect != null && anchors.length < _kMaxSemanticAnchors) {
            anchors.add(_SemanticAnchor(
              rect: fRect,
              label: srcNode.alt!,
              isHeading: false,
              isImage: true,
            ));
          }
        }
        flushLink();
        continue;
      }

      // Walk the source node's parent chain looking for an <a href> ancestor.
      String? href;
      String? anchorNodeId;
      UDTNode? node = fragment.sourceNode;
      while (node != null) {
        if (node.tagName == 'a') {
          final h = node.attributes['href'];
          if (h != null && h.isNotEmpty) {
            href = h;
            anchorNodeId = node.id;
            anchorNodeById[node.id] = node;
          }
          break;
        }
        node = node.parent;
      }

      if (anchorNodeId == null) {
        flushLink();
        continue;
      }

      // Different link OR Different Line → flush previous and start new.
      // This ensures multiline links have distinct hit targets per line.
      final currentLineIndex = fragment.lineIndex;
      final previousLineIndex = i > 0 ? _fragments[i - 1].lineIndex : -1;

      if (anchorNodeId != currentAnchorId ||
          currentLineIndex != previousLineIndex) {
        flushLink();
        currentAnchorId = anchorNodeId;
        currentHref = href;
      }

      // Extend bounding rect.
      final fRect = fragment.rect;
      if (fRect != null) {
        if (currentRect == null) {
          currentRect = fRect;
        } else {
          currentRect = Rect.fromLTRB(
            fRect.left < currentRect!.left ? fRect.left : currentRect!.left,
            fRect.top < currentRect!.top ? fRect.top : currentRect!.top,
            fRect.right > currentRect!.right ? fRect.right : currentRect!.right,
            fRect.bottom > currentRect!.bottom
                ? fRect.bottom
                : currentRect!.bottom,
          );
        }
      }

      // Accumulate label text.
      final text = fragment.text;
      if (text != null && text.trim().isNotEmpty) {
        if (linkTextBuffer.isNotEmpty) linkTextBuffer.write(' ');
        linkTextBuffer.write(text.trim());
      }
    }
    flushLink();

    if (anchors.length > _kMaxSemanticAnchors) {
      return anchors.sublist(0, _kMaxSemanticAnchors);
    }
    return anchors;
  }
}
