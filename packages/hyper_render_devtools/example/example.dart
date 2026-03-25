// ignore_for_file: avoid_print

import 'package:flutter/material.dart';

import '../lib/hyper_render_devtools.dart';

/// Example: integrating HyperRender DevTools in an app.
///
/// 1. Call [HyperRenderDevtools.register] before [runApp].
/// 2. Run your app in debug mode: `flutter run`
/// 3. Open Flutter DevTools and select the **HyperRender** tab.
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Register service extensions — debug mode only, no-op in release/profile.
  assert(() {
    HyperRenderDevtools.register();
    return true;
  }());

  runApp(const _ExampleApp());
}

class _ExampleApp extends StatelessWidget {
  const _ExampleApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HyperRender DevTools Example',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const _HomePage(),
    );
  }
}

class _HomePage extends StatelessWidget {
  const _HomePage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('DevTools Inspector Demo')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.developer_mode, size: 64, color: Colors.indigo),
              SizedBox(height: 16),
              Text(
                'HyperRender DevTools',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Open Flutter DevTools and navigate to the\n'
                '"HyperRender" tab to inspect UDT trees,\n'
                'computed styles, and layout fragments.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              SizedBox(height: 24),
              _InstructionCard(),
            ],
          ),
        ),
      ),
    );
  }
}

class _InstructionCard extends StatelessWidget {
  const _InstructionCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Start',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...[
              '1. flutter run (debug mode)',
              '2. Open Flutter DevTools',
              '3. Select HyperRender tab',
              '4. Select a renderer from the dropdown',
            ].map(
              (s) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(s, style: const TextStyle(fontFamily: 'monospace')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
