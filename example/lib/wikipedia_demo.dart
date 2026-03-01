import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:hyper_render/hyper_render.dart';

import 'demo_colors.dart';

class WikipediaDemo extends StatefulWidget {
  const WikipediaDemo({super.key});

  @override
  State<WikipediaDemo> createState() => _WikipediaDemoState();
}

class _WikipediaDemoState extends State<WikipediaDemo>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Real-World Wikipedia HTML'),
        backgroundColor: DemoColors.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.auto_stories, size: 16), text: 'Harry Potter'),
            Tab(icon: Icon(Icons.forest, size: 16), text: 'Lord of the Rings'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _ArticleTab(
            title: 'Harry Potter',
            url: 'https://en.wikipedia.org/api/rest_v1/page/html/Harry_Potter',
            emoji: '⚡',
          ),
          _ArticleTab(
            title: 'Lord of the Rings',
            url:
                'https://en.wikipedia.org/api/rest_v1/page/html/The_Lord_of_the_Rings',
            emoji: '💍',
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _ArticleTab extends StatefulWidget {
  final String title;
  final String url;
  final String emoji;

  const _ArticleTab({
    required this.title,
    required this.url,
    required this.emoji,
  });

  @override
  State<_ArticleTab> createState() => _ArticleTabState();
}

class _ArticleTabState extends State<_ArticleTab>
    with AutomaticKeepAliveClientMixin {
  String? _html;
  bool _loading = false;
  String? _error;
  int? _charCount;
  int? _fetchMs;

  static const _mobileOverrideCss = '''
    body { font-family: -apple-system, "Segoe UI", Roboto, sans-serif; font-size: 15px; line-height: 1.7; }
    .infobox, .infobox_v3, .sidebar { float: none !important; width: 100% !important; margin: 16px 0 !important; }
    .mw-editsection { display: none; }
    .reflist, .references { font-size: 12px; line-height: 1.5; }
    .mw-references-wrap { margin-top: 8px; }
    figure { margin: 12px 0; }
    .thumb { float: none !important; margin: 12px auto !important; }
  ''';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final sw = Stopwatch()..start();
    try {
      final response = await http.get(
        Uri.parse(widget.url),
        headers: {'Accept': 'text/html; charset=utf-8'},
      );
      sw.stop();
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _html = response.body;
            _charCount = response.body.length;
            _fetchMs = sw.elapsedMilliseconds;
            _loading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _error = 'HTTP ${response.statusCode}';
            _loading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_loading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Fetching ${widget.title} from Wikipedia…',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              Text(
                'Could not load article',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                _error!,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _fetch,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_html == null) return const SizedBox.shrink();

    return Column(
      children: [
        _StatsBar(
          emoji: widget.emoji,
          charCount: _charCount!,
          fetchMs: _fetchMs!,
        ),
        Expanded(
          child: HyperViewer(
            html: _html!,
            baseUrl: 'https://en.wikipedia.org',
            sanitize: false,
            customCss: _mobileOverrideCss,
            selectable: true,
            onLinkTap: (url) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Link: $url'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _StatsBar extends StatelessWidget {
  final String emoji;
  final int charCount;
  final int fetchMs;

  const _StatsBar({
    required this.emoji,
    required this.charCount,
    required this.fetchMs,
  });

  @override
  Widget build(BuildContext context) {
    final kb = (charCount / 1024).toStringAsFixed(0);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFFF5F5F5),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Text(
            '$kb KB',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 6),
          const Text('·', style: TextStyle(color: Colors.grey)),
          const SizedBox(width: 6),
          Text(
            'fetched in ${fetchMs}ms',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              border: Border.all(color: Colors.green.shade200),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, size: 11, color: Colors.green.shade700),
                const SizedBox(width: 3),
                Text(
                  'Wikipedia CC BY-SA',
                  style: TextStyle(fontSize: 10, color: Colors.green.shade700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
