/// HyperRender - The Universal Content Engine for Flutter
///
/// A high-performance rendering engine for HTML, Markdown, and Quill Delta
/// with perfect text selection, advanced CSS support, and CJK typography.
///
/// ## v2.0 Modular Architecture
///
/// This package is now a convenience wrapper that includes all plugins.
/// For minimal dependencies, use individual packages:
///
/// - `hyper_render_core` - Zero-dep core rendering engine
/// - `hyper_render_html` - HTML parsing with CSS support
/// - `hyper_render_markdown` - Markdown parsing (GFM)
/// - `hyper_render_highlight` - Syntax highlighting for code blocks
///
/// ## Quick Start
///
/// ```dart
/// import 'package:hyper_render/hyper_render.dart';
///
/// // Render HTML
/// HyperViewer(html: '<h1>Hello World</h1>')
///
/// // Render Markdown
/// HyperViewer.markdown(markdown: '# Hello World')
///
/// // Render Quill Delta
/// HyperViewer.delta(delta: '{"ops":[{"insert":"Hello World\\n"}]}')
/// ```
///
/// ## Features
///
/// - **HTML Rendering**: Full HTML support with CSS cascade
/// - **Markdown Rendering**: GitHub Flavored Markdown
/// - **Quill Delta**: Rich text editor format support
/// - **Text Selection**: Native-feeling selection with handles
/// - **CJK Typography**: Japanese Kinsoku and Ruby/Furigana
/// - **Tables**: Smart tables with horizontal scroll
/// - **Code Blocks**: Syntax highlighting for 180+ languages
/// - **Performance**: Virtualized rendering for long documents
library;

// ============================================
// Public API - Widgets
// ============================================

export 'src/widgets/hyper_viewer.dart'
    show HyperViewer, HyperRenderMode, HyperContentType;

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
        RenderHyperBoxSelection,
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

export 'src/widgets/hyper_render_widget.dart'
    show HyperRenderWidget, HyperImage, ImageAction, ImageActionCallback;

export 'src/widgets/hyper_selection_overlay.dart'
    show
        HyperSelectionOverlay,
        HyperSelectionOverlayState,
        HyperRenderWidgetSelectionExtension,
        SelectionMenuAction;

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

// ============================================
// Public API - Security
// ============================================

export 'src/utils/html_sanitizer.dart' show HtmlSanitizer;

// ============================================
// Public API - Plugin Interfaces
// ============================================

export 'src/interfaces/content_parser.dart'
    show
        ContentParser,
        ContentType,
        ParseResult,
        ExtendedContentParser,
        PlainTextParser;

export 'src/interfaces/css_parser.dart'
    show CssParserInterface, ParsedCssRule, SimpleInlineStyleParser;

export 'src/interfaces/code_highlighter.dart'
    show CodeHighlighter, PlainTextHighlighter;

export 'src/interfaces/image_clipboard.dart'
    show ImageClipboardHandler, DefaultImageClipboardHandler, ImageOperationResult;

// ============================================
// Public API - Default Plugin Implementations
// ============================================

export 'src/plugins/default_html_parser.dart' show DefaultHtmlParser;

export 'src/plugins/default_markdown_parser.dart' show DefaultMarkdownParser;

export 'src/plugins/default_delta_parser.dart' show DefaultDeltaParser;

export 'src/plugins/default_css_parser.dart' show DefaultCssParser;

export 'src/plugins/default_code_highlighter.dart'
    show DefaultCodeHighlighter, HighlightTheme;

// ============================================
// Public API - Clipboard Plugin (Optional - requires hyper_render_clipboard)
// ============================================

// Commented out due to share_plus/mime version conflicts
// To use clipboard features, add hyper_render_clipboard separately:
//   import 'package:hyper_render_clipboard/hyper_render_clipboard.dart';
// export 'package:hyper_render_clipboard/hyper_render_clipboard.dart'
//     show SuperClipboardHandler;
