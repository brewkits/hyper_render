import 'package:flutter/material.dart';
import 'package:hyper_render_core/hyper_render_core.dart';
import 'package:hyper_render_math/hyper_render_math.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HyperRender Math Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MathExamplePage(),
    );
  }
}

class MathExamplePage extends StatelessWidget {
  const MathExamplePage({super.key});

  static final _registry = HyperPluginRegistry()
    ..register(const MathNodePlugin());

  static final _document = DocumentNode(children: [
    BlockNode(
      tagName: 'p',
      children: [TextNode('Quadratic formula:')],
    ),
    BlockNode(
      tagName: 'div',
      children: [
        AtomicNode(
          tagName: 'math',
          attributes: const {
            'src': r'x = \frac{-b \pm \sqrt{b^2 - 4ac}}{2a}',
          },
        ),
      ],
    ),
    BlockNode(
      tagName: 'p',
      children: [TextNode("Euler's identity:")],
    ),
    BlockNode(
      tagName: 'div',
      children: [
        AtomicNode(
          tagName: 'math',
          attributes: const {'src': r'e^{i\pi} + 1 = 0'},
        ),
      ],
    ),
  ]);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Math Rendering'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: HyperRenderWidget(
          document: _document,
          pluginRegistry: _registry,
          config: const HyperRenderConfig(),
        ),
      ),
    );
  }
}
