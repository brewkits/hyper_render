import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hyper_render/hyper_render.dart';
import 'package:url_launcher/url_launcher.dart';
import 'book_model.dart';

class ReaderScreen extends StatefulWidget {
  final Book book;

  const ReaderScreen({super.key, required this.book});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  late HyperPageController _pageController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  // Settings
  final ValueNotifier<double> _fontSize = ValueNotifier(18.0);
  final ValueNotifier<double> _lineHeight = ValueNotifier(1.6);
  final ValueNotifier<Color> _backgroundColor = ValueNotifier(const Color(0xFFFDF6E3));
  final ValueNotifier<Color> _textColor = ValueNotifier(const Color(0xFF5B4636));

  static const double _fontSizeMin = 12.0;
  static const double _fontSizeMax = 36.0;
  static const double _fontSizeStep = 2.0;

  @override
  void initState() {
    super.initState();
    // Initialize with saved progress
    _pageController = HyperPageController(initialPage: widget.book.lastPage);
    _pageController.currentPage.addListener(_saveProgress);
  }

  void _saveProgress() {
    widget.book.lastPage = _pageController.currentPage.value;
  }

  void _decreaseFontSize() {
    _fontSize.value = (_fontSize.value - _fontSizeStep).clamp(_fontSizeMin, _fontSizeMax);
  }

  void _increaseFontSize() {
    _fontSize.value = (_fontSize.value + _fontSizeStep).clamp(_fontSizeMin, _fontSizeMax);
  }

  @override
  void dispose() {
    _pageController.currentPage.removeListener(_saveProgress);
    _pageController.dispose();
    super.dispose();
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Typography', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 10),
              ValueListenableBuilder<double>(
                valueListenable: _fontSize,
                builder: (context, size, _) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Font Size: ${size.toInt()}px', style: const TextStyle(fontSize: 12)),
                    Row(
                      children: [
                        const Icon(Icons.format_size, size: 16),
                        Expanded(
                          child: Slider(
                            value: size,
                            min: 14,
                            max: 32,
                            onChanged: (v) => _fontSize.value = v,
                          ),
                        ),
                        const Icon(Icons.format_size, size: 24),
                      ],
                    ),
                  ],
                ),
              ),
              ValueListenableBuilder<double>(
                valueListenable: _lineHeight,
                builder: (context, lh, _) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Line Height: ${lh.toStringAsFixed(1)}', style: const TextStyle(fontSize: 12)),
                    Row(
                      children: [
                        const Icon(Icons.format_line_spacing, size: 16),
                        Expanded(
                          child: Slider(
                            value: lh,
                            min: 1.2,
                            max: 2.4,
                            divisions: 12,
                            onChanged: (v) => _lineHeight.value = v,
                          ),
                        ),
                        const Icon(Icons.format_line_spacing, size: 24),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 24),
              const Text('Theme', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _themeOption(const Color(0xFFFFFFFF), Colors.black, 'Light'),
                  _themeOption(const Color(0xFFFDF6E3), const Color(0xFF5B4636), 'Sepia'),
                  _themeOption(const Color(0xFF121212), Colors.white70, 'Dark'),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _themeOption(Color bg, Color text, String label) {
    return ValueListenableBuilder<Color>(
      valueListenable: _backgroundColor,
      builder: (context, currentBg, _) {
        final isSelected = currentBg == bg;
        return GestureDetector(
          onTap: () {
            _backgroundColor.value = bg;
            _textColor.value = text;
          },
          child: Column(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: bg,
                  border: Border.all(
                    color: isSelected ? Colors.blue : Colors.grey.shade300,
                    width: isSelected ? 2 : 1,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(child: Text('Aa', style: TextStyle(color: text))),
              ),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(fontSize: 12)),
            ],
          ),
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiValueListenableBuilder(
      listenables: [_fontSize, _lineHeight, _backgroundColor, _textColor],
      builder: (context) {
        final css = '''
          body { 
            font-size: ${_fontSize.value}px; 
            line-height: ${_lineHeight.value}; 
            color: ${_colorToHex(_textColor.value)};
          }
          h1, h2, h3 { color: ${_colorToHex(_textColor.value)}; }
        ''';

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: _backgroundColor.value,
          appBar: AppBar(
            title: Text(widget.book.title, style: const TextStyle(fontSize: 16)),
            backgroundColor: Colors.transparent,
            elevation: 0,
            foregroundColor: _textColor.value,
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              // Font-size zoom — tap once per step, hold to repeat
              IconButton(
                icon: const Icon(Icons.text_decrease),
                tooltip: 'Smaller text',
                onPressed: _fontSize.value > _fontSizeMin ? _decreaseFontSize : null,
              ),
              IconButton(
                icon: const Icon(Icons.text_increase),
                tooltip: 'Larger text',
                onPressed: _fontSize.value < _fontSizeMax ? _increaseFontSize : null,
              ),
              IconButton(
                icon: Icon(widget.book.isBookmarked ? Icons.bookmark : Icons.bookmark_border),
                onPressed: () => setState(() => widget.book.isBookmarked = !widget.book.isBookmarked),
              ),
              IconButton(
                icon: const Icon(Icons.list),
                onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
              ),
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: _showSettings,
              ),
            ],
          ),
          endDrawer: _buildTocDrawer(),
          body: Column(
            children: [
              Expanded(
                child: widget.book.type == BookType.html
                    ? HyperViewer(
                        html: widget.book.content,
                        mode: HyperRenderMode.paged,
                        pageController: _pageController,
                        customCss: css,
                        widgetBuilder: _videoWidgetBuilder,
                        onError: (e, st) {
                          debugPrint('HyperReader Error: $e');
                        },
                      )
                    : HyperViewer.markdown(
                        markdown: widget.book.content,
                        mode: HyperRenderMode.paged,
                        pageController: _pageController,
                        customCss: css,
                      ),
              ),
              // Progress Footer
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: _textColor.value.withValues(alpha: 0.1))),
                ),
                child: ValueListenableBuilder<int>(
                  valueListenable: _pageController.currentPage,
                  builder: (context, page, _) {
                    final progress = _pageController.pageCount > 0 
                        ? (page + 1) / _pageController.pageCount 
                        : 0.0;
                    
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${(progress * 100).toInt()}% read',
                              style: TextStyle(color: _textColor.value.withValues(alpha: 0.5), fontSize: 10),
                            ),
                            Text(
                              'Page ${page + 1} of ${_pageController.pageCount}',
                              style: TextStyle(color: _textColor.value.withValues(alpha: 0.7), fontSize: 11, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: _textColor.value.withValues(alpha: 0.1),
                            color: _textColor.value.withValues(alpha: 0.4),
                            minHeight: 2,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTocDrawer() {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Theme.of(context).primaryColor),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.auto_stories, color: Colors.white, size: 40),
                  const SizedBox(height: 12),
                  Text(
                    widget.book.title,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Table of Contents', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // Example TOC entries
                _tocItem('Chapter I', 0),
                _tocItem('The West Egg', 2), // Mock positions
                _tocItem('Chapter II', 5),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tocItem(String title, int page) {
    return ListTile(
      title: Text(title),
      trailing: Text('p. ${page + 1}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
      onTap: () {
        _pageController.jumpToPage(page);
        Navigator.pop(context);
      },
    );
  }

  Widget? _videoWidgetBuilder(UDTNode node) {
    if (node is AtomicNode && (node.tagName == 'video' || node.tagName == 'audio')) {
      final mediaInfo = MediaInfo.fromNode(node);
      final src = mediaInfo.src;
      final poster = mediaInfo.poster;
      final isAudio = node.tagName == 'audio';

      return GestureDetector(
        onTap: () async {
          final uri = Uri.tryParse(src);
          if (uri != null) {
            await launchUrl(uri, mode: LaunchMode.platformDefault);
          }
        },
        child: Container(
          constraints: const BoxConstraints(maxHeight: 220),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (poster != null && !isAudio)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    poster,
                    width: double.infinity,
                    height: 220,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isAudio ? Icons.headphones : Icons.play_arrow,
                  color: Colors.white,
                  size: 36,
                ),
              ),
              Positioned(
                  bottom: 8,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Tap to play in external player',
                        style: const TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }
    return null;
  }

  String _colorToHex(Color color) {
    return '#${color.toARGB32().toRadixString(16).substring(2)}';
  }
}

class MultiValueListenableBuilder extends StatelessWidget {
  final List<ValueListenable> listenables;
  final Widget Function(BuildContext context) builder;

  const MultiValueListenableBuilder({
    super.key,
    required this.listenables,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge(listenables),
      builder: (context, _) => builder(context),
    );
  }
}
