import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:hyper_render_epub/hyper_render_epub.dart';

void main() {
  runApp(const EpubExampleApp());
}

class EpubExampleApp extends StatelessWidget {
  const EpubExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'HyperRender EPUB Demo',
      home: EpubReaderScreen(),
    );
  }
}

class EpubReaderScreen extends StatefulWidget {
  const EpubReaderScreen({super.key});

  @override
  State<EpubReaderScreen> createState() => _EpubReaderScreenState();
}

class _EpubReaderScreenState extends State<EpubReaderScreen> {
  EpubBook? _book;
  EpubReaderController? _controller;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSampleBook();
  }

  Future<void> _loadSampleBook() async {
    // In a real application, load bytes from assets or local filesystem:
    // final bytes = await rootBundle.load('assets/sample.epub');
    final dummyBytes = Uint8List(0);

    try {
      final book = await EpubBook.open(dummyBytes);
      setState(() {
        _book = book;
        _controller = EpubReaderController(book: book);
        _loading = false;
      });
    } catch (_) {
      // Fallback state for example
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_book == null || _controller == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('EPUB Reader Example')),
        body: const Center(
          child:
              Text('Provide a valid .epub archive to render with EpubReader.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_book!.title ?? 'EPUB Reader'),
      ),
      body: Column(
        children: [
          Expanded(
            child: EpubReader(
              controller: _controller!,
              onExternalLinkTap: (url) =>
                  debugPrint('External link tapped: $url'),
            ),
          ),
          SafeArea(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Previous'),
                  onPressed: _controller!.hasPrevious
                      ? () => _controller!.previous()
                      : null,
                ),
                TextButton.icon(
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Next'),
                  onPressed:
                      _controller!.hasNext ? () => _controller!.next() : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
