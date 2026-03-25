/// HyperRender - The Universal Content Engine for Flutter
///
/// A high-performance rendering engine for HTML, Markdown, and Quill Delta
/// with perfect text selection, advanced CSS support, and CJK typography.
///
/// ## Architecture
///
/// This package is a convenience wrapper over `hyper_render_core`.
/// For minimal dependencies, use individual packages:
///
/// - `hyper_render_core`      — Core rendering engine
/// - `hyper_render_html`      — HTML parsing with CSS support
/// - `hyper_render_markdown`  — Markdown parsing (GFM)
/// - `hyper_render_highlight` — Syntax highlighting for code blocks
///
/// ## Quick Start
///
/// ```dart
/// import 'package:hyper_render/hyper_render.dart';
///
/// HyperViewer(html: '<h1>Hello World</h1>')
/// HyperViewer.markdown(markdown: '# Hello World')
/// HyperViewer.delta(delta: '{"ops":[{"insert":"Hello World\\n"}]}')
/// ```
library;

// ============================================
// Core engine — re-exported from hyper_render_core
// ============================================

export 'package:hyper_render_core/hyper_render_core.dart'
    show
        // Models
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
        TableCellNode,
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
        HyperTransition,
        FlexDirection,
        JustifyContent,
        AlignItems,
        FlexWrap,
        Fragment,
        FragmentType,
        LineInfo,
        // Style
        StyleResolver,
        CssRule,
        // Core rendering
        RenderHyperBox,
        RenderHyperBoxSelection,
        HyperBoxParentData,
        HyperLinkTapCallback,
        HyperWidgetBuilder,
        HyperTextSelection,
        ImageLoadCallback,
        HyperImageLoader,
        ImageLoadState,
        CachedImage,
        defaultImageLoader,
        HyperRenderWidget,
        HyperImage,
        ImageAction,
        ImageActionCallback,
        GridContainerWidget,
        gridItemSpan,
        HyperSelectionOverlay,
        HyperSelectionOverlayState,
        HyperRenderWidgetSelectionExtension,
        SelectionMenuAction,
        HtmlToSpanConverter,
        LinkTapCallback,
        ImageBuilder,
        MediaWidgetBuilder,
        MediaInfo,
        MediaType,
        DefaultMediaWidget,
        AtomicNodeMediaExtension,
        RubySpan,
        RubyTextWidget,
        SmartTableWrapper,
        TableStrategy,
        HyperTable,
        KinsokuProcessor,
        HyperAnimations,
        HyperKeyframe,
        HyperKeyframes,
        HyperAnimatedWidget,
        HyperAnimationExtension,
        FormulaWidget,
        FormulaBuilder,
        FormulaInfo,
        CodeBlockWidget,
        CodeTheme,
        detectLanguageFromClass,
        // Container widgets
        FlexContainerWidget,
        FlexItemWidget,
        GridItem,
        HyperDetailsWidget,
        ErrorBoundaryWidget,
        ErrorBoundaryNode,
        // Interfaces
        ContentParser,
        ContentType,
        ParseResult,
        ExtendedContentParser,
        PlainTextParser,
        CssParserInterface,
        ParsedCssRule,
        SimpleInlineStyleParser,
        CodeHighlighter,
        PlainTextHighlighter,
        ImageClipboardHandler,
        DefaultImageClipboardHandler,
        ImageOperationResult;

// ============================================
// Unique to hyper_render — viewer & utilities
// ============================================

export 'src/widgets/hyper_viewer.dart'
    show HyperViewer, HyperRenderMode, HyperContentType;

export 'package:hyper_render_core/hyper_render_core.dart'
    show HyperRenderConfig;

export 'src/core/lazy_image_queue.dart' show LazyImageQueue;

export 'src/core/capture_extension.dart' show HyperCaptureExtension;

export 'src/utils/html_sanitizer.dart' show HtmlSanitizer;

export 'src/utils/html_heuristics.dart' show HtmlHeuristics;

export 'src/utils/svg_builder.dart' show buildSvgWidget;

// ============================================
// Parsers & adapters
// ============================================

export 'src/parser/adapter.dart'
    show DocumentAdapter, ExtendedDocumentAdapter, AdapterResult, InputType;

export 'src/parser/html/html_adapter.dart' show HtmlAdapter;

export 'src/parser/delta/delta_adapter.dart' show DeltaAdapter;

export 'src/parser/markdown/markdown_adapter.dart' show MarkdownAdapter;

// ============================================
// Default plugin implementations
// ============================================

export 'src/plugins/default_html_parser.dart' show DefaultHtmlParser;

export 'src/plugins/default_markdown_parser.dart' show DefaultMarkdownParser;

export 'src/plugins/default_delta_parser.dart' show DefaultDeltaParser;

export 'src/plugins/default_css_parser.dart' show DefaultCssParser;

export 'src/plugins/default_code_highlighter.dart'
    show DefaultCodeHighlighter, HighlightTheme;

// ============================================
// Clipboard plugin (optional — add hyper_render_clipboard separately)
// ============================================

// import 'package:hyper_render_clipboard/hyper_render_clipboard.dart';
// export 'package:hyper_render_clipboard/hyper_render_clipboard.dart'
//     show SuperClipboardHandler;
