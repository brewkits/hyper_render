import 'package:flutter/material.dart';
import 'package:hyper_render/hyper_render.dart';
import 'package:url_launcher/url_launcher.dart';
import 'book_model.dart';

/// Unified settings for the reader to avoid fragmented ValueNotifiers
class ReaderSettings {
  final double fontSize;
  final double lineHeight;
  final Color backgroundColor;
  final Color textColor;

  const ReaderSettings({
    this.fontSize = 18.0,
    this.lineHeight = 1.6,
    this.backgroundColor = const Color(0xFFFDF6E3),
    this.textColor = const Color(0xFF5B4636),
  });

  ReaderSettings copyWith({
    double? fontSize,
    double? lineHeight,
    Color? backgroundColor,
    Color? textColor,
  }) {
    return ReaderSettings(
      fontSize: fontSize ?? this.fontSize,
      lineHeight: lineHeight ?? this.lineHeight,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      textColor: textColor ?? this.textColor,
    );
  }

  String toCss() {
    final hexColor =
        '#${textColor.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';
    return '''
      body { 
        font-size: ${fontSize}px; 
        line-height: $lineHeight; 
        color: $hexColor;
      }
      h1, h2, h3 { color: $hexColor; }
    ''';
  }
}

class ReaderScreen extends StatefulWidget {
  final Book book;

  const ReaderScreen({super.key, required this.book});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  late HyperPageController _pageController;
  late Book _currentBook; // Local state for the book to handle updates
  final GlobalKey<ScaffoldMessengerState> _messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  // Settings grouped into a single ValueNotifier
  final ValueNotifier<ReaderSettings> _settings =
      ValueNotifier(const ReaderSettings());

  static const double _fontSizeMin = 12.0;
  static const double _fontSizeMax = 36.0;
  static const double _fontSizeStep = 2.0;

  @override
  void initState() {
    super.initState();
    _currentBook = widget.book;
    _pageController = HyperPageController(initialPage: _currentBook.lastPage);
    _pageController.currentPage.addListener(_onPageChanged);
  }

  void _onPageChanged() {
    // Only update progress if the page actually changed to avoid redundant writes
    if (_currentBook.lastPage != _pageController.currentPage.value) {
      _currentBook =
          _currentBook.copyWith(lastPage: _pageController.currentPage.value);
    }
  }

  void _toggleBookmark() {
    setState(() {
      _currentBook =
          _currentBook.copyWith(isBookmarked: !_currentBook.isBookmarked);
    });
  }

  void _updateFontSize(double delta) {
    final newSize =
        (_settings.value.fontSize + delta).clamp(_fontSizeMin, _fontSizeMax);
    _settings.value = _settings.value.copyWith(fontSize: newSize);
  }

  @override
  void dispose() {
    _pageController.currentPage.removeListener(_onPageChanged);
    _pageController.dispose();
    _settings.dispose();
    super.dispose();
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
          child: ValueListenableBuilder<ReaderSettings>(
            valueListenable: _settings,
            builder: (context, settings, _) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                      child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(height: 20),
                  const Text('Typography',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 15),
                  _buildSlider('Font Size: ${settings.fontSize.toInt()}px',
                      settings.fontSize, 14, 32, Icons.format_size, (v) {
                    _settings.value = settings.copyWith(fontSize: v);
                  }),
                  const SizedBox(height: 15),
                  _buildSlider(
                      'Line Height: ${settings.lineHeight.toStringAsFixed(1)}',
                      settings.lineHeight,
                      1.2,
                      2.4,
                      Icons.format_line_spacing, (v) {
                    _settings.value = settings.copyWith(lineHeight: v);
                  }, divisions: 12),
                  const Divider(height: 40),
                  const Text('Theme',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _themeOption(const Color(0xFFFFFFFF), Colors.black,
                          'Light', settings),
                      _themeOption(const Color(0xFFFDF6E3),
                          const Color(0xFF5B4636), 'Sepia', settings),
                      _themeOption(const Color(0xFF121212), Colors.white70,
                          'Dark', settings),
                    ],
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSlider(String label, double value, double min, double max,
      IconData icon, ValueChanged<double> onChanged,
      {int? divisions}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey),
            Expanded(
              child: Slider(
                value: value,
                min: min,
                max: max,
                divisions: divisions,
                onChanged: onChanged,
              ),
            ),
            Icon(icon, size: 24, color: Colors.grey),
          ],
        ),
      ],
    );
  }

  Widget _themeOption(
      Color bg, Color text, String label, ReaderSettings current) {
    final isSelected = current.backgroundColor == bg;
    return GestureDetector(
      onTap: () {
        _settings.value =
            current.copyWith(backgroundColor: bg, textColor: text);
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
            child: Center(
                child: Text('Aa',
                    style:
                        TextStyle(color: text, fontWeight: FontWeight.bold))),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ReaderSettings>(
      valueListenable: _settings,
      builder: (context, settings, _) {
        return Scaffold(
          backgroundColor: settings.backgroundColor,
          appBar: AppBar(
            title:
                Text(_currentBook.title, style: const TextStyle(fontSize: 16)),
            backgroundColor: Colors.transparent,
            elevation: 0,
            foregroundColor: settings.textColor,
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.text_decrease),
                onPressed: settings.fontSize > _fontSizeMin
                    ? () => _updateFontSize(-_fontSizeStep)
                    : null,
              ),
              IconButton(
                icon: const Icon(Icons.text_increase),
                onPressed: settings.fontSize < _fontSizeMax
                    ? () => _updateFontSize(_fontSizeStep)
                    : null,
              ),
              IconButton(
                icon: Icon(_currentBook.isBookmarked
                    ? Icons.bookmark
                    : Icons.bookmark_border),
                onPressed: _toggleBookmark,
              ),
              Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.list),
                  onPressed: () => Scaffold.of(context).openEndDrawer(),
                ),
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
                child: _currentBook.type == BookType.html
                    ? HyperViewer(
                        html: _currentBook.content,
                        mode: HyperRenderMode.paged,
                        pageController: _pageController,
                        customCss: settings.toCss(),
                        widgetBuilder: _videoWidgetBuilder,
                        onError: (e, st) {
                          debugPrint('HyperReader Error: $e');
                        },
                      )
                    : HyperViewer.markdown(
                        markdown: _currentBook.content,
                        mode: HyperRenderMode.paged,
                        pageController: _pageController,
                        customCss: settings.toCss(),
                      ),
              ),
              _buildProgressFooter(settings),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProgressFooter(ReaderSettings settings) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
            top: BorderSide(color: settings.textColor.withValues(alpha: 0.1))),
      ),
      child: ValueListenableBuilder<int>(
        valueListenable: _pageController.currentPage,
        builder: (context, page, _) {
          final pageCount = _pageController.pageCount;
          final progress = pageCount > 0 ? (page + 1) / pageCount : 0.0;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${(progress * 100).toInt()}% read',
                      style: TextStyle(
                          color: settings.textColor.withValues(alpha: 0.5),
                          fontSize: 10)),
                  Text('Page ${page + 1} of $pageCount',
                      style: TextStyle(
                          color: settings.textColor.withValues(alpha: 0.7),
                          fontSize: 11,
                          fontWeight: FontWeight.w500)),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: settings.textColor.withValues(alpha: 0.1),
                  color: settings.textColor.withValues(alpha: 0.4),
                  minHeight: 2,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget? _videoWidgetBuilder(UDTNode node) {
    if (node is AtomicNode &&
        (node.tagName == 'video' || node.tagName == 'audio')) {
      final mediaInfo = MediaInfo.fromNode(node);
      final src = mediaInfo.src;
      final poster = mediaInfo.poster;
      final isAudio = node.tagName == 'audio';

      return Semantics(
        label: isAudio ? 'Audio player for $src' : 'Video player for $src',
        button: true,
        child: GestureDetector(
          onTap: () => _handleMediaTap(src),
          child: Container(
            constraints: const BoxConstraints(maxHeight: 220),
            decoration: BoxDecoration(
                color: Colors.black87, borderRadius: BorderRadius.circular(8)),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (poster != null && !isAudio)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(poster,
                        width: double.infinity,
                        height: 220,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink()),
                  ),
                _buildPlayIcon(isAudio),
                _buildPlayOverlay(),
              ],
            ),
          ),
        ),
      );
    }
    return null;
  }

  Widget _buildPlayIcon(bool isAudio) {
    return Container(
      width: 64,
      height: 64,
      decoration:
          const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
      child: Icon(isAudio ? Icons.headphones : Icons.play_arrow,
          color: Colors.white, size: 36),
    );
  }

  Widget _buildPlayOverlay() {
    return Positioned(
      bottom: 8,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
              color: Colors.black54, borderRadius: BorderRadius.circular(4)),
          child: const Text('Tap to play in external player',
              style: TextStyle(color: Colors.white70, fontSize: 11)),
        ),
      ),
    );
  }

  Future<void> _handleMediaTap(String src) async {
    final uri = Uri.tryParse(src);
    if (uri == null) {
      _showError('Invalid media URL');
      return;
    }

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      } else {
        _showError('Could not launch media player');
      }
    } catch (e) {
      _showError('Error opening media: $e');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(message),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating),
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
                    _currentBook.title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Table of Contents',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _tocItem('Chapter I', 0),
                _tocItem('The West Egg', 2),
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
      trailing: Text('p. ${page + 1}',
          style: const TextStyle(color: Colors.grey, fontSize: 12)),
      onTap: () {
        _pageController.jumpToPage(page);
        Navigator.pop(context);
      },
    );
  }
}
