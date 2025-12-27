/// HyperRender - The Universal Content Engine for Flutter
///
/// A high-performance rendering engine for HTML, Markdown, and Quill Delta
/// with perfect text selection, advanced CSS support, and CJK typography.
///
/// ## Features
///
/// - **Perfect Text Selection**: Single InlineSpan tree architecture ensures
///   smooth, crash-free text selection across the entire document.
///
/// - **Advanced CSS Support**: Comprehensive CSS parsing and resolution
///   following the W3C cascade specification.
///
/// - **Multi-Format Input**: Supports HTML, Quill Delta (future), and
///   Markdown (future) through a unified adapter system.
///
/// - **CJK Typography**: Proper line-breaking and Ruby/Furigana support
///   for Japanese, Chinese, and Korean text.
///
/// - **High Performance**: Custom RenderObject-based rendering for
///   optimal performance with large documents.
///
/// ## Basic Usage
///
/// ```dart
/// import 'package:hyper_render/hyper_render.dart';
///
/// // Simple HTML rendering
/// HyperViewer(
///   html: '<p>Hello <strong>World</strong></p>',
/// )
///
/// // With link handling
/// HyperViewer(
///   html: '<a href="https://example.com">Click me</a>',
///   onLinkTap: (url) => print('Link tapped: $url'),
/// )
///
/// // With custom styling
/// HyperViewer(
///   html: htmlContent,
///   baseStyle: TextStyle(fontSize: 18),
///   customCss: 'p { margin: 16px 0; }',
/// )
/// ```
///
/// ## Architecture
///
/// HyperRender uses a multi-layer architecture:
///
/// 1. **Parser Layer**: Converts input (HTML/Delta/Markdown) to UDT
/// 2. **Style Resolver**: Applies CSS cascade to compute final styles
/// 3. **Layout Engine**: Calculates positions using BFC/IFC algorithms
/// 4. **Painting Layer**: Renders directly to Canvas
///
/// See the [architecture documentation](https://github.com/user/hyper_render)
/// for more details.
library;

// ============================================
// Public API - Widgets
// ============================================

export 'src/widgets/hyper_viewer.dart' show HyperViewer, HyperRenderMode;

// ============================================
// Public API - Models
// ============================================

export 'src/model/node.dart'
    show
        NodeType,
        UDTNode,
        DocumentNode,
        BlockNode,
        InlineNode,
        TextNode,
        LineBreakNode,
        AtomicNode,
        RubyNode,
        TableNode,
        TableRowNode,
        TableCellNode;

export 'src/model/computed_style.dart'
    show
        ComputedStyle,
        DisplayType,
        HyperTextAlign,
        HyperVerticalAlign,
        HyperOverflow,
        HyperFloat,
        HyperClear,
        HyperTimingFunction,
        HyperAnimationDirection,
        HyperAnimationFillMode,
        HyperTransition;

export 'src/model/fragment.dart' show Fragment, FragmentType, LineInfo;

// ============================================
// Public API - Parsers
// ============================================

export 'src/parser/adapter.dart'
    show DocumentAdapter, ExtendedDocumentAdapter, AdapterResult, InputType;

export 'src/parser/html/html_adapter.dart' show HtmlAdapter;

export 'src/parser/delta/delta_adapter.dart' show DeltaAdapter;

export 'src/parser/markdown/markdown_adapter.dart' show MarkdownAdapter;

// ============================================
// Public API - Style
// ============================================

export 'src/style/resolver.dart' show StyleResolver, CssRule;

// ============================================
// Public API - Core Rendering
// ============================================

export 'src/core/render_hyper_box.dart'
    show
        RenderHyperBox,
        HyperBoxParentData,
        HyperLinkTapCallback,
        HyperWidgetBuilder,
        HyperTextSelection,
        ImageLoadCallback;

export 'src/core/image_provider.dart'
    show
        HyperImageLoader,
        ImageLoadState,
        CachedImage,
        defaultImageLoader;

export 'src/widgets/hyper_render_widget.dart' show HyperRenderWidget;

export 'src/widgets/hyper_selection_overlay.dart'
    show
        HyperSelectionOverlay,
        HyperSelectionOverlayState,
        HyperRenderWidgetSelectionExtension;

export 'src/core/span_converter.dart'
    show HtmlToSpanConverter, LinkTapCallback, ImageBuilder;

export 'src/core/render_media.dart'
    show MediaWidgetBuilder, MediaInfo, MediaType, DefaultMediaWidget;

export 'src/core/render_ruby.dart' show RubySpan, RubyTextWidget;

export 'src/core/render_table.dart'
    show SmartTableWrapper, TableStrategy, HyperTable;

export 'src/core/kinsoku_processor.dart' show KinsokuProcessor;

export 'src/core/animation_controller.dart'
    show
        HyperAnimations,
        HyperKeyframe,
        HyperKeyframes,
        HyperAnimatedWidget,
        HyperAnimationExtension;

export 'src/core/render_formula.dart'
    show FormulaWidget, FormulaBuilder, FormulaInfo;

export 'src/widgets/code_block_widget.dart'
    show CodeBlockWidget, CodeTheme, detectLanguageFromClass;
