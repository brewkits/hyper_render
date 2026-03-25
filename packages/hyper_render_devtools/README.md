# hyper_render_devtools

Flutter DevTools extension for [HyperRender](https://github.com/brewkits/hyper_render) — inspect UDT node trees, computed styles, layout fragments, and performance metrics directly inside Flutter DevTools.

## Features

- **UDT Tree Inspector** — browse the full Universal Document Tree with node types, tag names, and inline text content
- **Computed Style Viewer** — inspect every CSS property resolved on any node (font, box model, display, float, grid, CSS variables)
- **Layout Fragment & Line Data** — see every inline fragment with its width/height/offset, and every line with its baseline
- **Performance Summary** — fragment count, line count, and phase timing (when wired with `HyperRenderDebugHooks.getPerformanceData`)
- **Auto-discovery** — all `HyperViewer` / `HyperRenderWidget` instances register automatically; no per-widget setup needed
- **Demo Mode** — open the panel without a running app to explore the inspector UI with sample data

## Getting started

Add the package to your app's `dev_dependencies` (debug-only usage):

```yaml
dev_dependencies:
  hyper_render_devtools: ^1.1.3
```

Or add to `dependencies` if you want it available in profile builds:

```yaml
dependencies:
  hyper_render_devtools: ^1.1.3
```

## Usage

Call `HyperRenderDevtools.register()` once at app startup, **before** `runApp`:

```dart
import 'package:flutter/material.dart';
import 'package:hyper_render/hyper_render.dart';
import 'package:hyper_render_devtools/hyper_render_devtools.dart';

void main() {
  // Register DevTools service extensions (debug mode only, no-op in release).
  assert(() {
    HyperRenderDevtools.register();
    return true;
  }());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: HyperViewer(
          html: '<h1>Hello <strong>HyperRender</strong></h1>'
                '<p>Open Flutter DevTools → HyperRender tab to inspect.</p>',
        ),
      ),
    );
  }
}
```

## Opening the DevTools panel

1. Run your app in debug mode: `flutter run`
2. Open Flutter DevTools (via IDE or `flutter devtools`)
3. Select the **HyperRender** tab in the sidebar
4. Use the dropdown to pick an active renderer instance

## Service extensions

The package registers five VM service extensions:

| Extension | Description |
|---|---|
| `ext.hyperRender.listRenderers` | List all active renderer IDs |
| `ext.hyperRender.getUdt` | Full UDT node tree for a renderer |
| `ext.hyperRender.getNodeStyle` | Computed style for a specific node |
| `ext.hyperRender.getFragments` | Layout fragments + lines from last pass |
| `ext.hyperRender.getPerformance` | Performance summary (fragment/line counts + timing) |

## Manual registration

If you need to expose a custom document source that does not go through `RenderHyperBox`, use the manual API:

```dart
HyperRenderDevtools.registerRenderer('my-id', () => myDocument);
// ...
HyperRenderDevtools.unregisterRenderer('my-id');
```

## Architecture

```
hyper_render_devtools (this package)
├── lib/src/service_extensions.dart  — VM service extension registration
│                                      + HyperRenderDebugHooks wiring
├── lib/src/udt_serializer.dart      — UDT → JSON serialization
└── extension/devtools/
    ├── config.yaml                  — DevTools panel metadata
    └── build/                       — compiled Flutter Web panel (devtools_ui)
```

The `devtools_ui` sub-directory contains the Flutter Web source for the panel UI. It is pre-compiled and included in `extension/devtools/build/` so no extra build step is required for package consumers.

## Additional information

- [HyperRender main package](https://pub.dev/packages/hyper_render)
- [Issue tracker](https://github.com/brewkits/hyper_render/issues)
- [Source code](https://github.com/brewkits/hyper_render/tree/main/packages/hyper_render_devtools)
