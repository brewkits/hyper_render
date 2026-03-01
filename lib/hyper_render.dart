/// HyperRender - The Universal Content Engine for Flutter
///
/// A high-performance rendering engine for HTML, Markdown, and Quill Delta
/// with perfect text selection, advanced CSS support, and CJK typography.
library;

// ============================================
// Public API - Sub-packages
// ============================================

export 'package:hyper_render_core/hyper_render_core.dart';
export 'package:hyper_render_html/hyper_render_html.dart';
export 'package:hyper_render_markdown/hyper_render_markdown.dart';
export 'package:hyper_render_highlight/hyper_render_highlight.dart';

// ============================================
// Public API - Top-level Widgets & Enums
// ============================================

export 'src/widgets/hyper_viewer.dart' 
  show HyperViewer, HyperRenderMode, HyperContentType;
