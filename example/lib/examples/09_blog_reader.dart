/// Example 09: Blog Reader
///
/// Demonstrates HyperRender for blog/markdown content:
/// - Syntax highlighting for code blocks
/// - Table of contents generation
/// - Reading progress indicator
/// - Estimated reading time
/// - Social sharing
/// - Comment section preview
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hyper_render/hyper_render.dart';

class BlogReaderExample extends StatefulWidget {
  const BlogReaderExample({super.key});

  @override
  State<BlogReaderExample> createState() => _BlogReaderExampleState();
}

class _BlogReaderExampleState extends State<BlogReaderExample> {
  final ScrollController _scrollController = ScrollController();
  double _readingProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateProgress);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _updateProgress() {
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    setState(() {
      _readingProgress = maxScroll > 0 ? (currentScroll / maxScroll).clamp(0.0, 1.0) : 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Collapsing app bar with hero image
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('Blog Post'),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    'https://picsum.photos/800/400?random=10',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey.shade300,
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () => _sharePost(context),
              ),
              IconButton(
                icon: const Icon(Icons.bookmark_border),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Bookmarked!')),
                  );
                },
              ),
            ],
          ),

          // Reading progress indicator
          SliverToBoxAdapter(
            child: LinearProgressIndicator(
              value: _readingProgress,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).primaryColor,
              ),
            ),
          ),

          // Blog metadata
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Building High-Performance Flutter Apps: A Deep Dive',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 20,
                        child: Icon(Icons.person),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Alex Thompson',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Mar 3, 2026 · 8 min read',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Tags
                  Wrap(
                    spacing: 8,
                    children: [
                      _Tag(label: 'Flutter'),
                      _Tag(label: 'Performance'),
                      _Tag(label: 'Tutorial'),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: Divider()),

          // Table of contents
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.list, color: Colors.blue.shade900),
                          const SizedBox(width: 8),
                          Text(
                            'Table of Contents',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _TocItem(title: '1. Introduction to Performance'),
                      _TocItem(title: '2. Rendering Pipeline Optimization'),
                      _TocItem(title: '3. Memory Management'),
                      _TocItem(title: '4. Code Examples'),
                      _TocItem(title: '5. Conclusion'),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Blog content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: HyperViewer(
                html: _blogHtmlContent,
                customCss: _blogCss,
                onLinkTap: (url) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Link: $url')),
                  );
                },
                onError: (error, stackTrace) {
                  debugPrint('Render error: $error');
                },
              ),
            ),
          ),

          // Author bio
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 30,
                        child: Icon(Icons.person, size: 30),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Alex Thompson',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Senior Flutter Developer with 8 years of experience '
                              'building high-performance mobile apps.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () {},
                              child: const Text('Follow'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Comments section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Comments (23)',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _CommentCard(
                    author: 'Sarah M.',
                    comment: 'Excellent article! The code examples were really helpful.',
                    timeAgo: '2h ago',
                  ),
                  _CommentCard(
                    author: 'John D.',
                    comment: 'Can you write more about state management optimization?',
                    timeAgo: '5h ago',
                  ),
                  _CommentCard(
                    author: 'Emily R.',
                    comment: 'This solved my performance issues. Thanks!',
                    timeAgo: '1d ago',
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton(
                      onPressed: () {},
                      child: const Text('Load More Comments'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom spacing
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  void _sharePost(BuildContext context) {
    Clipboard.setData(
      const ClipboardData(text: 'Building High-Performance Flutter Apps: A Deep Dive'),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Title copied to clipboard')),
    );
  }

  static const _blogHtmlContent = '''
    <article>
      <h2 id="introduction">1. Introduction to Performance</h2>

      <p>
        Performance optimization is crucial for delivering exceptional user experiences.
        In this comprehensive guide, we'll explore advanced techniques for building
        lightning-fast Flutter applications.
      </p>

      <p>
        Modern users expect apps to be responsive, smooth, and instant. Even a 100ms
        delay can negatively impact user satisfaction. Let's dive into how to achieve
        60fps performance consistently.
      </p>

      <h2 id="rendering">2. Rendering Pipeline Optimization</h2>

      <p>
        Flutter's rendering pipeline is remarkably efficient, but it requires understanding
        to optimize properly. The pipeline consists of three main phases:
      </p>

      <ol>
        <li><strong>Build:</strong> Creating widget tree</li>
        <li><strong>Layout:</strong> Computing sizes and positions</li>
        <li><strong>Paint:</strong> Rendering to screen</li>
      </ol>

      <h3>Minimize Widget Rebuilds</h3>

      <p>
        The #1 performance killer is unnecessary widget rebuilds. Here's a critical example:
      </p>

      <pre style="background: #f5f5f5; padding: 16px; border-radius: 8px; overflow-x: auto; font-family: 'Courier New', monospace; font-size: 14px;">
// ❌ Bad: Entire widget rebuilds on every setState
class MyWidget extends StatefulWidget {
  Widget build(BuildContext context) {
    return ExpensiveWidget(
      child: AnimatedCounter(count: _count),
    );
  }
}

// ✅ Good: Only counter rebuilds
class MyWidget extends StatefulWidget {
  Widget build(BuildContext context) {
    return const ExpensiveWidget(
      child: _Counter(),
    );
  }
}

class _Counter extends StatefulWidget {
  // Only this rebuilds
}
      </pre>

      <blockquote>
        <strong>Pro Tip:</strong> Use <code>const</code> constructors aggressively.
        They prevent rebuilds and improve performance significantly.
      </blockquote>

      <h2 id="memory">3. Memory Management</h2>

      <p>
        Efficient memory management prevents crashes and ensures smooth performance
        even on low-end devices. Key strategies include:
      </p>

      <ul>
        <li><strong>Dispose properly:</strong> Always dispose controllers, streams, and listeners</li>
        <li><strong>Use weak references:</strong> Prevent memory leaks in callbacks</li>
        <li><strong>Implement caching:</strong> LRU caches for images and data</li>
        <li><strong>Lazy load:</strong> Don't load what you don't need</li>
      </ul>

      <div style="background: #FFF3CD; padding: 16px; border-radius: 8px; margin: 16px 0; border-left: 4px solid #FFC107;">
        <strong>⚠️ Warning:</strong> Memory leaks are often caused by forgetting to
        remove listeners. Always use <code>removeListener()</code> in <code>dispose()</code>.
      </div>

      <h2 id="examples">4. Code Examples</h2>

      <h3>Efficient List Rendering</h3>

      <p>
        When displaying large lists, always use <code>ListView.builder</code> instead
        of <code>ListView</code>. Builder creates widgets lazily:
      </p>

      <pre style="background: #f5f5f5; padding: 16px; border-radius: 8px; overflow-x: auto; font-family: 'Courier New', monospace; font-size: 14px;">
// ✅ Efficient: Only visible items are built
ListView.builder(
  itemCount: 10000,
  itemBuilder: (context, index) {
    return ListTile(title: Text('Item \$index'));
  },
)

// ❌ Inefficient: All 10,000 items built at once
ListView(
  children: List.generate(
    10000,
    (index) => ListTile(title: Text('Item \$index')),
  ),
)
      </pre>

      <h3>Image Optimization</h3>

      <p>
        Images are often the heaviest assets. Optimize them properly:
      </p>

      <pre style="background: #f5f5f5; padding: 16px; border-radius: 8px; overflow-x: auto; font-family: 'Courier New', monospace; font-size: 14px;">
// ✅ Good: Specify dimensions, use caching
Image.network(
  'https://example.com/image.jpg',
  width: 200,
  height: 200,
  cacheWidth: 400,  // 2x for high-DPI
  cacheHeight: 400,
  fit: BoxFit.cover,
)
      </pre>

      <h2 id="conclusion">5. Conclusion</h2>

      <p>
        Performance optimization is an ongoing process. Profile regularly, optimize
        bottlenecks, and always test on real devices. The techniques covered here
        will help you build apps that delight users with their speed and responsiveness.
      </p>

      <div style="background: #E3F2FD; padding: 20px; border-radius: 8px; margin-top: 24px;">
        <h3 style="margin-top: 0;">Key Takeaways</h3>
        <ul>
          <li>Use <code>const</code> constructors to prevent rebuilds</li>
          <li>Lazy load with <code>ListView.builder</code></li>
          <li>Dispose resources properly</li>
          <li>Profile before optimizing</li>
          <li>Test on real devices, not just simulators</li>
        </ul>
      </div>

      <p style="margin-top: 24px; padding-top: 24px; border-top: 2px solid #eee; text-align: center; color: #666;">
        Thanks for reading! If you found this helpful, please share it with your team.
      </p>
    </article>
  ''';

  static const _blogCss = '''
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
      line-height: 1.7;
      color: #1a1a1a;
      font-size: 17px;
    }
    h2 {
      color: #1a1a1a;
      font-size: 26px;
      font-weight: 700;
      margin: 32px 0 16px 0;
      line-height: 1.3;
    }
    h3 {
      color: #333;
      font-size: 20px;
      font-weight: 600;
      margin: 24px 0 12px 0;
    }
    p {
      margin: 16px 0;
    }
    code {
      background: #f5f5f5;
      color: #E74C3C;
      padding: 3px 7px;
      border-radius: 4px;
      font-family: 'Courier New', monospace;
      font-size: 15px;
    }
    pre {
      line-height: 1.5;
    }
    blockquote {
      border-left: 4px solid #1976D2;
      padding-left: 20px;
      margin: 20px 0;
      color: #555;
      font-style: italic;
    }
    ul, ol {
      margin: 16px 0;
      padding-left: 24px;
    }
    li {
      margin: 8px 0;
    }
  ''';
}

class _Tag extends StatelessWidget {
  final String label;

  const _Tag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      backgroundColor: Colors.grey.shade200,
      labelStyle: const TextStyle(fontSize: 12),
    );
  }
}

class _TocItem extends StatelessWidget {
  final String title;

  const _TocItem({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Jump to: $title')),
          );
        },
        child: Row(
          children: [
            Icon(Icons.chevron_right, size: 16, color: Colors.blue.shade700),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.blue.shade900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommentCard extends StatelessWidget {
  final String author;
  final String comment;
  final String timeAgo;

  const _CommentCard({
    required this.author,
    required this.comment,
    required this.timeAgo,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 16,
                  child: Icon(Icons.person, size: 16),
                ),
                const SizedBox(width: 8),
                Text(
                  author,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  timeAgo,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(comment),
            const SizedBox(height: 8),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.thumb_up_outlined, size: 16),
                  label: const Text('Like'),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(50, 30),
                  ),
                ),
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.reply, size: 16),
                  label: const Text('Reply'),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(50, 30),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
