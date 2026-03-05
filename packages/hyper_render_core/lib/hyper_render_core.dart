/// HyperRender Core - Zero External Dependencies
///
/// This is the core rendering engine for HyperRender.
library;

// Model
export 'src/model/node.dart';
export 'src/model/computed_style.dart';
export 'src/model/fragment.dart';
export 'src/model/fragment_types.dart';

// Interfaces
export 'src/interfaces/content_parser.dart';
export 'src/interfaces/code_highlighter.dart';
export 'src/interfaces/css_parser.dart';
export 'src/interfaces/selection_types.dart';
export 'src/interfaces/image_clipboard.dart';

// Exceptions
export 'src/exceptions/hyper_render_exceptions.dart';

// Style
export 'src/style/resolver.dart';
export 'src/style/css_rule_index.dart';
export 'src/style/design_tokens.dart';

// Layout
export 'src/layout/layout_cache.dart';
export 'src/layout/layout_engines.dart'; // Pure Dart engines (God Object refactoring)

// Configuration
export 'src/core/render_config.dart';

// Core rendering
export 'src/adapter/delta_adapter.dart';
export 'src/core/capture_extension.dart';
export 'src/core/render_hyper_box.dart' show RenderHyperBox, RenderHyperBoxSelection, HyperLinkTapCallback, HyperWidgetBuilder, ImageLoadCallback, HyperTextSelection, HyperBoxParentData;
export 'src/core/span_converter.dart';
export 'src/core/kinsoku_processor.dart';
export 'src/core/image_provider.dart';
export 'src/core/render_ruby.dart';
export 'src/core/render_table.dart';
export 'src/core/render_media.dart';
export 'src/core/render_formula.dart';
export 'src/core/animation_controller.dart';
export 'src/core/performance_monitor.dart';
export 'src/core/performance_warnings.dart';
export 'src/core/production_monitor.dart'; // Week 3-4: Production validation monitoring
export 'src/core/production_diagnostic.dart'; // Week 3-4: Diagnostic tools
export 'src/core/edge_case_detector.dart'; // Week 3-4: Edge case detection

// Widgets
export 'src/widgets/hyper_render_widget.dart';
export 'src/widgets/hyper_selection_overlay.dart';
export 'src/widgets/code_block_widget.dart';
export 'src/widgets/details_widget.dart';
export 'src/widgets/error_boundary_widget.dart';
export 'src/widgets/hyper_error_widget.dart';
export 'src/widgets/loading_skeleton.dart';
