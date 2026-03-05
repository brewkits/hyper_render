/// Example 08: Complete News App
///
/// A production-ready news reader demonstrating:
/// - Article fetching with loading/error/success states
/// - Article list with thumbnails
/// - Full article view with images and formatting
/// - Pull-to-refresh
/// - Share functionality
/// - Bookmark/favorite feature
/// - Dark mode support
///
/// This is a COMPLETE example showing all HyperRender features together.
library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hyper_render/hyper_render.dart';

// Mock news article model
class NewsArticle {
  final String id;
  final String title;
  final String summary;
  final String htmlContent;
  final String imageUrl;
  final String author;
  final DateTime publishedAt;
  final String category;

  NewsArticle({
    required this.id,
    required this.title,
    required this.summary,
    required this.htmlContent,
    required this.imageUrl,
    required this.author,
    required this.publishedAt,
    required this.category,
  });
}

// Mock news service
class NewsService {
  static Future<List<NewsArticle>> fetchArticles() async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    return [
      NewsArticle(
        id: '1',
        title: 'Flutter Announces Revolutionary HTML Rendering Library',
        summary: 'New library promises 60fps performance with full CSS float support',
        imageUrl: 'https://picsum.photos/800/400?random=1',
        author: 'Sarah Johnson',
        publishedAt: DateTime.now().subtract(const Duration(hours: 2)),
        category: 'Technology',
        htmlContent: '''
          <article>
            <img src="https://picsum.photos/800/400?random=1"
                 style="width: 100%; border-radius: 12px; margin-bottom: 16px;" />

            <p class="lead">
              The Flutter team has unveiled HyperRender, a groundbreaking HTML rendering
              library that achieves true 60fps scrolling performance while supporting
              advanced features like CSS float layout.
            </p>

            <h2>Revolutionary Architecture</h2>

            <img src="https://picsum.photos/300/200?random=2"
                 style="float: right; width: 200px; margin: 0 0 16px 16px; border-radius: 8px;" />

            <p>
              Unlike traditional widget-tree based renderers, HyperRender uses a single
              custom <code>RenderObject</code> that paints the entire document in one pass.
              This architectural choice enables features that are impossible in other libraries.
            </p>

            <p>
              The most notable feature is full CSS float support. Images can float left or right,
              with text naturally wrapping around them—just like in a web browser. This has been
              a long-standing limitation in Flutter HTML rendering.
            </p>

            <div style="clear: both;"></div>

            <h2>Performance Benchmarks</h2>

            <p>
              Internal benchmarks show impressive results:
            </p>

            <ul>
              <li>10KB HTML document parses in just 69ms</li>
              <li>Maintains 60fps during scrolling on large documents</li>
              <li>2.6× faster than competing libraries</li>
              <li>Efficient memory usage with LRU caching</li>
            </ul>

            <blockquote>
              "HyperRender changes everything for Flutter developers building content-heavy
              applications. The performance is remarkable."
              <br><em>— Tech Review Weekly</em>
            </blockquote>

            <h2>Built-in Security</h2>

            <p>
              Security was a top priority. HyperRender includes built-in HTML sanitization
              to prevent XSS attacks, making it safe to render user-generated content.
            </p>

            <h3>Typography Excellence</h3>

            <p>
              The library includes best-in-class CJK typography support, including Ruby
              annotations and Kinsoku line-breaking rules following JIS X 4051 standards.
            </p>

            <div style="background: #E3F2FD; padding: 20px; border-radius: 8px; margin: 20px 0;">
              <strong>Developer Reaction</strong><br><br>
              Early adopters are praising the library's ease of use and performance.
              "Just drop in the widget and it works," said one developer. "The float
              layout support alone is worth switching for."
            </div>

            <h2>Availability</h2>

            <p>
              HyperRender is available now on pub.dev under the MIT license. The team
              has also released comprehensive documentation and 10+ example projects
              to help developers get started.
            </p>
          </article>
        ''',
      ),
      NewsArticle(
        id: '2',
        title: 'Mobile Performance Optimization: Best Practices for 2026',
        summary: 'Learn how to build lightning-fast mobile apps with these proven techniques',
        imageUrl: 'https://picsum.photos/800/400?random=3',
        author: 'Michael Chen',
        publishedAt: DateTime.now().subtract(const Duration(hours: 5)),
        category: 'Development',
        htmlContent: '''
          <article>
            <img src="https://picsum.photos/800/400?random=3"
                 style="width: 100%; border-radius: 12px; margin-bottom: 16px;" />

            <p class="lead">
              Performance optimization is critical for mobile app success. Here are the
              top techniques professional developers use to build fast, responsive apps.
            </p>

            <h2>1. Minimize Widget Rebuilds</h2>

            <p>
              Unnecessary widget rebuilds are the #1 performance killer in Flutter apps.
              Use <code>const</code> constructors wherever possible and leverage
              <code>ValueNotifier</code> or <code>Provider</code> for granular updates.
            </p>

            <h2>2. Optimize Image Loading</h2>

            <img src="https://picsum.photos/250/200?random=4"
                 style="float: left; width: 180px; margin: 0 16px 16px 0; border-radius: 8px;" />

            <p>
              Images are often the heaviest assets in mobile apps. Use appropriate formats
              (WebP for photos, SVG for icons), implement lazy loading, and leverage caching
              strategies like LRU caches.
            </p>

            <p>
              Consider using placeholder images while loading full-size versions, and always
              specify width/height to prevent layout shifts.
            </p>

            <div style="clear: both;"></div>

            <h2>3. Profile Before Optimizing</h2>

            <blockquote>
              "Premature optimization is the root of all evil in programming."
              <br><em>— Donald Knuth</em>
            </blockquote>

            <p>
              Always profile your app before optimizing. Flutter DevTools provides excellent
              performance profiling tools that show exactly where your app spends time.
            </p>

            <h3>Key Metrics to Monitor</h3>

            <ul>
              <li>Frame rendering time (target: &lt;16ms for 60fps)</li>
              <li>Memory usage and garbage collection</li>
              <li>Network request latency</li>
              <li>App startup time</li>
            </ul>

            <h2>4. Lazy Load Everything</h2>

            <p>
              Don't load what you don't need. Implement lazy loading for:
            </p>

            <ol>
              <li>List items (use ListView.builder, not ListView)</li>
              <li>Heavy widgets (load on-demand)</li>
              <li>Large assets (images, videos, fonts)</li>
              <li>API data (paginate responses)</li>
            </ol>

            <div style="background: #FFF3CD; padding: 16px; border-radius: 8px; margin: 16px 0;">
              <strong>💡 Pro Tip:</strong> Use Flutter's AutomaticKeepAliveClientMixin
              sparingly. It keeps widgets in memory even when off-screen, which can
              lead to memory bloat.
            </div>

            <h2>Conclusion</h2>

            <p>
              Performance optimization is an ongoing process, not a one-time task. Profile
              regularly, optimize the bottlenecks, and always test on real devices—not just
              simulators.
            </p>
          </article>
        ''',
      ),
      NewsArticle(
        id: '3',
        title: 'Understanding CSS Float Layout in Mobile Apps',
        summary: 'Deep dive into how float layout works and why it matters',
        imageUrl: 'https://picsum.photos/800/400?random=5',
        author: 'Emily Rodriguez',
        publishedAt: DateTime.now().subtract(const Duration(hours: 8)),
        category: 'Tutorial',
        htmlContent: '''
          <article>
            <img src="https://picsum.photos/800/400?random=5"
                 style="width: 100%; border-radius: 12px; margin-bottom: 16px;" />

            <h1>Understanding CSS Float Layout</h1>

            <p class="lead">
              CSS float layout has been a cornerstone of web design for decades. Now,
              with HyperRender, you can bring this powerful layout technique to Flutter.
            </p>

            <h2>What is Float Layout?</h2>

            <img src="https://picsum.photos/200/200?random=6"
                 style="float: right; width: 150px; margin: 0 0 16px 16px; border-radius: 8px;" />

            <p>
              Float layout allows elements (typically images) to "float" to the left or
              right side of their container, with text flowing naturally around them.
              This creates magazine-style layouts that are visually appealing and
              space-efficient.
            </p>

            <p>
              The key advantage is natural text wrapping. Instead of having images and
              text in separate columns, text intelligently fills the space around floated
              elements, creating a more organic, professional look.
            </p>

            <div style="clear: both;"></div>

            <h2>Why It's Hard in Flutter</h2>

            <p>
              Traditional Flutter HTML renderers use a widget tree approach where each
              HTML element becomes a separate widget. The problem? Widgets don't share
              a common coordinate system, making true float layout impossible.
            </p>

            <blockquote>
              "Float layout requires a shared coordinate space where text and images
              can be positioned relative to each other. Widget trees don't provide this."
            </blockquote>

            <h2>The HyperRender Solution</h2>

            <p>
              HyperRender solves this by using a single custom <code>RenderObject</code>
              that paints the entire document. Text and images exist in the same coordinate
              system, enabling proper float layout.
            </p>

            <h3>Example Usage</h3>

            <p>
              Using float layout in HyperRender is simple:
            </p>

            <p>
              <code>&lt;img src="..." style="float: left; margin: 0 16px 16px 0;"&gt;</code>
            </p>

            <div style="background: #E8F5E9; padding: 16px; border-radius: 8px; margin: 16px 0;">
              <strong>✅ Use Cases for Float Layout:</strong>
              <ul>
                <li>Blog posts with inline illustrations</li>
                <li>News articles with thumbnail images</li>
                <li>Product descriptions with product shots</li>
                <li>Documentation with diagrams</li>
                <li>Magazine-style content</li>
              </ul>
            </div>

            <h2>Best Practices</h2>

            <ol>
              <li>Always specify image width to prevent layout shifts</li>
              <li>Add appropriate margins to create space between image and text</li>
              <li>Use <code>clear: both</code> to end float sections</li>
              <li>Test with different screen sizes</li>
              <li>Consider mobile vs desktop layouts</li>
            </ol>

            <p>
              Float layout is a powerful tool when used correctly. It creates professional,
              polished layouts that engage readers and make efficient use of screen space.
            </p>
          </article>
        ''',
      ),
    ];
  }
}

class NewsAppExample extends StatefulWidget {
  const NewsAppExample({super.key});

  @override
  State<NewsAppExample> createState() => _NewsAppExampleState();
}

class _NewsAppExampleState extends State<NewsAppExample> {
  List<NewsArticle>? _articles;
  bool _isLoading = true;
  String? _error;
  final Set<String> _bookmarkedIds = {};

  @override
  void initState() {
    super.initState();
    _loadArticles();
  }

  Future<void> _loadArticles() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final articles = await NewsService.fetchArticles();
      setState(() {
        _articles = articles;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('08: News App'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadArticles,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadArticles,
      child: ListView.builder(
        itemCount: _articles!.length,
        itemBuilder: (context, index) {
          final article = _articles![index];
          return _ArticleCard(
            article: article,
            isBookmarked: _bookmarkedIds.contains(article.id),
            onTap: () => _openArticle(article),
            onBookmark: () => _toggleBookmark(article.id),
          );
        },
      ),
    );
  }

  void _openArticle(NewsArticle article) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _ArticleView(
          article: article,
          isBookmarked: _bookmarkedIds.contains(article.id),
          onBookmark: () => _toggleBookmark(article.id),
        ),
      ),
    );
  }

  void _toggleBookmark(String id) {
    setState(() {
      if (_bookmarkedIds.contains(id)) {
        _bookmarkedIds.remove(id);
      } else {
        _bookmarkedIds.add(id);
      }
    });
  }
}

// Article card widget
class _ArticleCard extends StatelessWidget {
  final NewsArticle article;
  final bool isBookmarked;
  final VoidCallback onTap;
  final VoidCallback onBookmark;

  const _ArticleCard({
    required this.article,
    required this.isBookmarked,
    required this.onTap,
    required this.onBookmark,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
                article.imageUrl,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 200,
                  color: Colors.grey.shade300,
                  child: const Icon(Icons.image_not_supported, size: 64),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      article.category,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade900,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Title
                  Text(
                    article.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Summary
                  Text(
                    article.summary,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 12),

                  // Author and date
                  Row(
                    children: [
                      Icon(Icons.person, size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        article.author,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        _formatTime(article.publishedAt),
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(
                          isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                          color: isBookmarked ? Colors.blue : Colors.grey,
                        ),
                        onPressed: onBookmark,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

// Full article view
class _ArticleView extends StatelessWidget {
  final NewsArticle article;
  final bool isBookmarked;
  final VoidCallback onBookmark;

  const _ArticleView({
    required this.article,
    required this.isBookmarked,
    required this.onBookmark,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Article'),
        actions: [
          IconButton(
            icon: Icon(isBookmarked ? Icons.bookmark : Icons.bookmark_border),
            onPressed: onBookmark,
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareArticle(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Article metadata
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      article.category,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade900,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    article.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.person, size: 16),
                      const SizedBox(width: 4),
                      Text(article.author),
                      const SizedBox(width: 16),
                      const Icon(Icons.access_time, size: 16),
                      const SizedBox(width: 4),
                      Text(_formatDate(article.publishedAt)),
                    ],
                  ),
                ],
              ),
            ),

            const Divider(),

            // Article content (HTML)
            Padding(
              padding: const EdgeInsets.all(16),
              child: HyperViewer(
                html: article.htmlContent,
                customCss: isDark ? _darkCss : _lightCss,
                onLinkTap: (url) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Link: $url')),
                  );
                },
                onImageTap: (url) {
                  // Could open image viewer
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Image tapped')),
                  );
                },
                onError: (error, stackTrace) {
                  debugPrint('Render error: $error');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _shareArticle(BuildContext context) {
    Clipboard.setData(ClipboardData(text: article.title));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Article title copied to clipboard')),
    );
  }

  static const _lightCss = '''
    body { font-family: -apple-system, sans-serif; line-height: 1.6; color: #1a1a1a; }
    .lead { font-size: 18px; color: #333; font-weight: 500; }
    h1, h2, h3 { color: #1a1a1a; margin-top: 24px; }
    img { max-width: 100%; }
    code { background: #f5f5f5; padding: 2px 6px; border-radius: 4px; }
    blockquote { border-left: 4px solid #1976D2; padding-left: 16px; color: #555; font-style: italic; }
  ''';

  static const _darkCss = '''
    body { font-family: -apple-system, sans-serif; line-height: 1.6; color: #e0e0e0; }
    .lead { font-size: 18px; color: #ccc; font-weight: 500; }
    h1, h2, h3 { color: #ffffff; margin-top: 24px; }
    img { max-width: 100%; }
    code { background: #2a2a2a; padding: 2px 6px; border-radius: 4px; color: #90CAF9; }
    blockquote { border-left: 4px solid #90CAF9; padding-left: 16px; color: #aaa; font-style: italic; }
  ''';
}
