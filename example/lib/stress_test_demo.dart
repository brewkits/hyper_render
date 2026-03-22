import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart' as flutter_html;
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart' as fwfh;
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart'
    as fwfh_core;
import 'package:http/http.dart' as http;
import 'package:hyper_render/hyper_render.dart';

import 'demo_colors.dart';

// =============================================================================
// Stress Test Demo — Manga · Fairy Tale · Novel · URL
// =============================================================================

enum _ContentType { manga, fairyTale, novel, url }

class StressTestDemo extends StatefulWidget {
  const StressTestDemo({super.key});

  @override
  State<StressTestDemo> createState() => _StressTestDemoState();
}

class _StressTestDemoState extends State<StressTestDemo> {
  _ContentType _contentType = _ContentType.manga;
  int _pageCount = 10;
  String _selectedLibrary = 'HyperRender';

  bool _isLoading = false;
  String? _loadedContent;
  int? _characterCount;
  String? _errorMessage;
  double? _renderMs;
  int? _domNodeCount;

  final _urlController = TextEditingController(
    text: 'https://www.gutenberg.org/files/11/11-h/11-h.htm',
  );

  // Page count options per content type
  static const _mangaPageCounts = [5, 10, 20, 50, 100];
  static const _fairyTalePageCounts = [1, 3, 5, 10, 20];
  static const _novelPageCounts = [10, 50, 100, 500, 1000];
  static const _libraries = ['HyperRender', 'flutter_html', 'fwfh', 'fwfh_core'];

  List<int> get _pageCounts => switch (_contentType) {
        _ContentType.manga => _mangaPageCounts,
        _ContentType.fairyTale => _fairyTalePageCounts,
        _ContentType.novel => _novelPageCounts,
        _ContentType.url => [],
      };

  // ── Content Generators ─────────────────────────────────────────────────────

  static String _generateMangaContent(int pages) {
    final buf = StringBuffer();
    // Use seed-based picsum URLs (no redirect, stable images).
    // All text uses light colours so it stays readable on the dark #0d0d0d bg.
    buf.write('''
<style>
  .manga-page { padding:6px 0; border-bottom:2px solid #1e1e1e; margin-bottom:10px; }
  .manga-label { color:#6b6b6b; font-size:10px; text-align:right; margin:0 0 4px 0; letter-spacing:1px; }
  .manga-panel { display:block; width:100%; border-radius:2px; margin-bottom:3px; }
  .manga-dialogue { border-left:4px solid; padding:10px 14px; margin:8px 0 0 0; border-radius:0 4px 4px 0; }
  .manga-speaker { font-weight:bold; font-size:11px; letter-spacing:2px; }
  .manga-line { color:#e0e0e0; margin:4px 0 0 0; font-size:14px; font-style:italic; }
</style>
<div style="background:#0d0d0d;font-family:'Helvetica Neue',Arial,sans-serif;max-width:800px;margin:0 auto;">
  <div style="background:#1a0000;border-bottom:3px solid #e53935;padding:16px;text-align:center;">
    <h1 style="color:#e53935;margin:0;font-size:22px;letter-spacing:4px;">SHADOW BLADE</h1>
    <p style="color:#aaa;font-size:11px;margin:6px 0 0 0;letter-spacing:2px;">VOLUME 5 · CHAPTER 47 · THE FINAL DUEL</p>
    <div style="display:flex;justify-content:space-between;margin-top:10px;font-size:12px;">
      <span style="color:#e53935;">← Ch. 46</span>
      <span style="color:#aaa;">$pages pages</span>
      <span style="color:#e53935;">Ch. 48 →</span>
    </div>
  </div>
''');

    final dialogues = [
      ('RYŪ', '#e53935', '#ff8a80',
          '"You cannot escape your destiny, Shadow Blade!"'),
      ('KIRA', '#42a5f5', '#90caf9',
          '"This ends here... I will protect everyone!"'),
      ('ELDER', '#ab47bc', '#ce93d8',
          '"The ancient seal has been broken. Darkness awakens."'),
      ('SHADOW', '#78909c', '#b0bec5',
          '"Hmph. Is that all the power you have, old man?"'),
      ('MASTER', '#66bb6a', '#a5d6a7',
          '"Remember your training. Fear is the enemy within."'),
    ];

    for (int p = 1; p <= pages; p++) {
      buf.write('<div class="manga-page">');
      buf.write(
          '<p class="manga-label">— PAGE $p / $pages —</p>');

      final layout = (p - 1) % 5;
      // Use seed-based picsum (no 302 redirect, consistent images per seed)
      final seed = p * 7;
      switch (layout) {
        // Layout 0: single tall full-width panel
        case 0:
          buf.write(
              '<img src="https://picsum.photos/seed/${seed}a/800/600" width="800" height="600" class="manga-panel" alt="Full panel"/>');
          break;
        // Layout 1: 2 vertical panels side-by-side
        case 1:
          buf.write('<div style="display:flex;gap:3px;margin-bottom:3px;">');
          buf.write(
              '<img src="https://picsum.photos/seed/${seed}b/400/520" width="400" height="520" style="flex:1;min-width:0;display:block;border-radius:2px;" alt="Panel L"/>');
          buf.write(
              '<img src="https://picsum.photos/seed/${seed}c/400/520" width="400" height="520" style="flex:1;min-width:0;display:block;border-radius:2px;" alt="Panel R"/>');
          buf.write('</div>');
          break;
        // Layout 2: wide shot + 2 smaller panels
        case 2:
          buf.write(
              '<img src="https://picsum.photos/seed/${seed}d/800/360" width="800" height="360" class="manga-panel" alt="Wide"/>');
          buf.write('<div style="display:flex;gap:3px;margin-bottom:3px;">');
          buf.write(
              '<img src="https://picsum.photos/seed/${seed}e/400/300" width="400" height="300" style="flex:1;min-width:0;display:block;border-radius:2px;" alt="Panel B-L"/>');
          buf.write(
              '<img src="https://picsum.photos/seed/${seed}f/400/300" width="400" height="300" style="flex:1;min-width:0;display:block;border-radius:2px;" alt="Panel B-R"/>');
          buf.write('</div>');
          break;
        // Layout 3: 3-column row + full-width bottom
        case 3:
          buf.write('<div style="display:flex;gap:3px;margin-bottom:3px;">');
          buf.write(
              '<img src="https://picsum.photos/seed/${seed}g/260/380" width="260" height="380" style="flex:1;min-width:0;display:block;border-radius:2px;" alt="Panel 1"/>');
          buf.write(
              '<img src="https://picsum.photos/seed/${seed}h/260/380" width="260" height="380" style="flex:1;min-width:0;display:block;border-radius:2px;" alt="Panel 2"/>');
          buf.write(
              '<img src="https://picsum.photos/seed/${seed}i/260/380" width="260" height="380" style="flex:1;min-width:0;display:block;border-radius:2px;" alt="Panel 3"/>');
          buf.write('</div>');
          buf.write(
              '<img src="https://picsum.photos/seed/${seed}j/800/240" width="800" height="240" class="manga-panel" alt="Bottom strip"/>');
          break;
        // Layout 4: tall main + 3 stacked side panels
        case 4:
          buf.write('<div style="display:flex;gap:3px;margin-bottom:3px;">');
          buf.write(
              '<img src="https://picsum.photos/seed/${seed}k/450/660" width="450" height="660" style="flex:1;min-width:0;display:block;border-radius:2px;" alt="Main"/>');
          buf.write(
              '<div style="flex:1;display:flex;flex-direction:column;gap:3px;min-width:0;">');
          buf.write(
              '<img src="https://picsum.photos/seed/${seed}l/300/210" width="300" height="210" style="width:100%;display:block;border-radius:2px;" alt="Side 1"/>');
          buf.write(
              '<img src="https://picsum.photos/seed/${seed}m/300/210" width="300" height="210" style="width:100%;display:block;border-radius:2px;" alt="Side 2"/>');
          buf.write(
              '<img src="https://picsum.photos/seed/${seed}n/300/210" width="300" height="210" style="width:100%;display:block;border-radius:2px;" alt="Side 3"/>');
          buf.write('</div>');
          buf.write('</div>');
          break;
      }

      // Dialogue box every 2 pages (more frequent = more text visible)
      if (p % 2 == 0) {
        final d = dialogues[p % dialogues.length];
        buf.write(
            '<div class="manga-dialogue" style="background:#111;border-left-color:${d.$2};">');
        buf.write(
            '<p class="manga-speaker" style="color:${d.$2};">${d.$1}</p>');
        buf.write(
            '<p class="manga-line" style="color:${d.$3};">${d.$4}</p>');
        buf.write('</div>');
      }

      buf.write('</div>'); // .manga-page
    }

    buf.write('''
  <div style="background:#1a0000;padding:24px;text-align:center;margin-top:8px;">
    <p style="color:#e53935;font-size:16px;font-weight:bold;margin:0;letter-spacing:2px;">— END OF CHAPTER 47 —</p>
    <p style="color:#aaa;font-size:12px;margin:8px 0 0 0;">Shadow Blade Vol.5 · $pages pages · HyperRender CSS class demo</p>
  </div>
</div>
''');
    return buf.toString();
  }

  static String _generateFairyTaleContent(int sections) {
    // Each "section" = heading + illustration (block, not float) + two paragraphs.
    // Images use HTML width/height attrs so HyperImage widget is used (reliable).
    // seed-based picsum URLs avoid 302 redirects.
    const story = [
      (
        'Once Upon a Time',
        '🌄',
        'In a kingdom nestled between misty mountains and an enchanted forest, there lived a young girl named Elara. Her hair was the colour of autumn leaves and her eyes shone like morning stars. She was known throughout the land for her kindness to every creature — from the smallest field mouse to the oldest oak tree.',
        'One morning, while gathering herbs near the forest edge, Elara discovered a tiny silver key half-buried in the roots of a gnarled willow tree. The key hummed faintly, as if whispering a secret only she could hear.',
      ),
      (
        'The Enchanted Forest',
        '🌲',
        'Elara followed the humming deeper into the forest, where the trees grew so tall their canopies blotted out the sun. Fireflies danced between fern fronds. A family of foxes watched her pass with intelligent amber eyes. The forest was alive in a way the village never was.',
        'At the heart of the forest stood an ancient oak wider than ten men with arms outstretched. At its base was a small iron door, green with moss. The silver key fit perfectly into its lock. As Elara turned it, a warm golden light spilled out from within.',
      ),
      (
        'The Dragon\'s Chamber',
        '🐉',
        'Beyond the door lay a cavern filled with treasure — not gold or jewels, but books. Thousands upon thousands of books, their spines gleaming in every colour imaginable, stacked floor to ceiling in towering shelves carved from living wood. At the centre, curled around the largest shelf, slept a small dragon no bigger than a hound.',
        'The dragon\'s scales were deep violet, and with each breath it exhaled tiny puffs of purple smoke that smelled of cinnamon and old paper. As Elara stepped closer, its golden eyes opened slowly. "A visitor at last," it murmured in a voice like rustling pages. "I have been waiting three hundred years."',
      ),
      (
        'A Bargain is Struck',
        '🤝',
        '"What do you want from me?" Elara asked, though she felt no fear — only wonder. The dragon blinked slowly. "Every book in this library holds a story that must be told. But I cannot leave this place. I need a Voice — someone to carry the stories out into the world."',
        '"And in return?" she asked. The dragon smiled. "In return, you will never be lonely. Every story ever written will be yours to know. And when your own story ends, it too will have a place on these shelves — never forgotten."',
      ),
      (
        'The Journey Home',
        '🏡',
        'Elara accepted. The dragon breathed a single flame over her heart — not burning, but warm as a hearth on a winter\'s night. She felt the stories settle inside her like old friends. When she walked back through the village, children gathered to listen.',
        'Seasons passed. Elara told stories of brave knights and gentle giants, of lost stars that found their way home and rivers that remembered every secret dropped into them. The kingdom grew kinder, brighter, richer in a way that gold never could provide.',
      ),
      (
        'The Library Lives On',
        '📚',
        'Years later, when Elara\'s granddaughter found the silver key among her grandmother\'s things, she followed the same humming path through the same ancient forest. The small dragon still slept between the shelves — but now, on the topmost shelf, a new book gleamed.',
        '"Whose story is that?" the girl asked. The dragon opened one golden eye. "Your grandmother\'s," it said. "Would you like to read it?" She reached up, opened the cover, and began. And so the library — and the stories — lived on forever.',
      ),
    ];

    final buf = StringBuffer();
    buf.write('''
<style>
  .tale-section { padding:0 16px 28px 16px; }
  .tale-heading { color:#6B2D0C; font-size:20px; margin:0 0 14px 0; padding-bottom:8px; border-bottom:2px solid #D4B896; font-style:italic; }
  .tale-emoji { color:#C19A6B; margin-right:6px; }
  .tale-img { display:block; margin:0 auto 18px auto; border-radius:10px; border:3px solid #D4B896; }
  .tale-caption { text-align:center; color:#C19A6B; font-size:12px; margin:-12px 0 16px 0; font-style:italic; }
  .tale-para { margin:0 0 14px 0; font-size:15px; text-align:justify; color:#3a2010; }
  .tale-quote { border-left:4px solid #C19A6B; margin:16px 0; padding:12px 16px; background:#FEF9F0; border-radius:0 8px 8px 0; }
  .tale-quote p { color:#7B4F2E; font-style:italic; margin:0; font-size:14px; }
  .tale-quote cite { color:#C19A6B; font-size:12px; margin-top:6px; display:block; }
  .tale-sep { text-align:center; color:#C19A6B; font-size:20px; padding:8px 0 16px 0; }
</style>
<article style="font-family:Georgia,'Times New Roman',serif;line-height:1.85;color:#2c1810;background:#fdf6ee;max-width:720px;">
  <div style="background:#8B4513;padding:32px 24px;text-align:center;border-bottom:4px solid #8B4513;">
    <p style="color:rgba(255,255,255,0.85);font-size:12px;letter-spacing:3px;margin:0 0 8px 0;">A STORY OF MAGIC &amp; WONDER</p>
    <h1 style="color:#FFF8DC;font-size:28px;margin:0;line-height:1.3;">The Dragon's Library</h1>
    <p style="color:rgba(255,255,255,0.7);font-size:13px;margin:10px 0 0 0;font-style:italic;">A fairy tale in $sections chapters</p>
  </div>
  <div style="padding:20px 16px 8px 16px;text-align:center;">
    <p style="font-size:13px;color:#8B6914;border-top:1px solid #D4B896;border-bottom:1px solid #D4B896;padding:8px 0;margin:0 0 20px 0;letter-spacing:1px;">✦ &nbsp; Once read, never forgotten &nbsp; ✦</p>
  </div>
''');

    for (int s = 0; s < sections; s++) {
      final scene = story[s % story.length];
      // Use seed-based URL: no redirect, stable image per seed
      final imgSeed = 'tale${s + 1}';
      final imgW = 340;
      final imgH = 220;

      buf.write('<div class="tale-section">');
      buf.write(
          '<h2 class="tale-heading"><span class="tale-emoji">${scene.$2}</span>${scene.$1}</h2>');

      // Block-centered image with HTML width/height attrs → HyperImage widget
      buf.write(
          '<img src="https://picsum.photos/seed/$imgSeed/$imgW/$imgH" width="$imgW" height="$imgH" class="tale-img" alt="${scene.$1}"/>');
      buf.write(
          '<p class="tale-caption">Illustration: ${scene.$1}</p>');

      buf.write('<p class="tale-para">${scene.$3}</p>');
      buf.write('<p class="tale-para">${scene.$4}</p>');

      if (s % 2 == 1) {
        buf.write('''<div class="tale-quote">
  <p>"Every book ever written is a door. Every story, a key."</p>
  <cite>— The Dragon of the Enchanted Library</cite>
</div>''');
      }

      buf.write('</div>');

      if (s < sections - 1) {
        buf.write('<p class="tale-sep">✦ &nbsp; ✦ &nbsp; ✦</p>');
      }
    }

    buf.write('''
  <div style="text-align:center;padding:32px 16px;background:#6B2D0C;margin-top:8px;">
    <p style="color:#FFF8DC;font-size:18px;margin:0;font-style:italic;">~ The End ~</p>
    <p style="color:rgba(255,248,220,0.65);font-size:12px;margin:8px 0 0 0;">$sections of 6 scenes · HyperRender CSS class showcase</p>
  </div>
</article>
''');
    return buf.toString();
  }

  static String _generateNovelContent(int pages) {
    final buf = StringBuffer();
    buf.write('''
<style>
  .novel-chapter { margin:0 0 32px 0; }
  .novel-h2 { color:#1565C0; font-size:20px; margin:0 0 4px 0; padding-bottom:6px; border-bottom:2px solid #BBDEFB; }
  .novel-meta { color:#90A4AE; font-size:11px; margin:0 0 14px 0; letter-spacing:1px; }
  .novel-para { margin:10px 0; line-height:1.8; text-align:justify; color:#212121; }
  .novel-drop { font-size:48px; font-weight:bold; color:#1565C0; float:left; line-height:0.85; margin:6px 8px 0 0; }
  .novel-highlight { background:#E3F2FD; padding:12px 16px; border-radius:8px; margin:16px 0; border-left:4px solid #1976D2; }
  .novel-highlight strong { color:#1565C0; }
  .novel-img { display:block; margin:0 auto 16px auto; border-radius:10px; }
  .novel-hr { margin:28px 0; border:none; border-top:1px solid #E0E0E0; }
  .novel-tag { display:inline-block; background:#E3F2FD; color:#1565C0; border-radius:12px; padding:2px 8px; font-size:11px; margin:0 4px 4px 0; }
</style>
<article style="font-family:Georgia,serif;line-height:1.8;padding:4px;background:#FAFAFA;">
  <div style="background:#1565C0;padding:32px 20px;text-align:center;border-radius:8px;margin-bottom:24px;">
    <h1 style="color:white;margin:0;font-size:24px;">📖 The Infinite Archive</h1>
    <p style="color:rgba(255,255,255,0.75);font-size:13px;margin:8px 0 0 0;">$pages chapters · Performance &amp; rendering showcase</p>
  </div>
''');

    const paras = [
      'In the old city, where cobblestones remembered every footstep, the archivist moved quietly between stacks that reached the ceiling. Dust motes drifted in shafts of amber light. Each book was a locked room, and she held the keys.',
      'The records spoke of a time before the great silence, when the streets had been full of merchants and scholars. Now only the archives remained, patient and indifferent, indifferent as stone. She had come to understand their language over the years.',
      'Outside, rain traced slow lines down the tall windows. She did not mind the rain. It kept visitors away, and visitors, however well-intentioned, always left things out of order. Order was the only religion she practised.',
      'There are things that cannot be named without changing them. She wrote this in the margin of a book she would never finish, in an ink that would outlast the paper. Somewhere below, a clock chimed the hour no one was counting.',
      'Tiếng mưa rơi trên mái ngói cũ, mỗi giọt như một dấu chấm trong câu chuyện dài chưa kết thúc. Bà thủ thư ngồi lặng, ngón tay lướt qua những trang sách đã vàng ố theo năm tháng.',
      'The letters she never sent were filed alphabetically under R for Regret. Beside them, the letters she had sent but never explained were filed under S for Silence. Both drawers were very full.',
    ];

    for (int i = 0; i < pages; i++) {
      if (i > 0) {
        buf.write('<hr class="novel-hr"/>');
      }
      buf.write('<div class="novel-chapter">');
      buf.write(
          '<h2 class="novel-h2">Chapter ${i + 1}: ${_chapterTitle(i)}</h2>');
      buf.write(
          '<p class="novel-meta">Part ${(i ~/ 5) + 1} · Section ${(i % 5) + 1}</p>');

      // Chapter illustration every 5 chapters (uses HTML attrs → HyperImage)
      if (i % 5 == 0) {
        final seed = 'novel${i + 1}';
        buf.write(
            '<img src="https://picsum.photos/seed/$seed/400/200" width="400" height="200" class="novel-img" alt="Chapter ${i + 1} illustration"/>');
      }

      // Drop cap on first paragraph
      final firstPara = paras[i % paras.length];
      buf.write(
          '<p class="novel-para"><span class="novel-drop">${firstPara[0]}</span>${firstPara.substring(1)}</p>');
      for (int j = 1; j < 3; j++) {
        buf.write(
            '<p class="novel-para">${paras[(i + j) % paras.length]}</p>');
      }

      // Highlight note every 4 chapters
      if (i % 4 == 0) {
        buf.write(
            '<p class="novel-highlight"><strong>Editor\'s note:</strong> Chapter ${i + 1} introduces a key theme explored throughout the remainder of the text.</p>');
      }

      // Tags every 3 chapters
      if (i % 3 == 0) {
        buf.write('<p>');
        for (final tag in ['literary', 'archive', 'mystery', 'Chapter ${i + 1}']) {
          buf.write('<span class="novel-tag">$tag</span>');
        }
        buf.write('</p>');
      }

      buf.write('</div>');
    }

    buf.write('''
  <div style="text-align:center;margin-top:20px;padding:28px 20px;background:#263238;border-radius:12px;">
    <p style="color:white;margin:0;font-size:18px;">📖 The End</p>
    <p style="color:#90A4AE;margin:8px 0 0 0;font-size:13px;">$pages chapters · HyperRender CSS class + drop cap demo</p>
  </div>
</article>
''');
    return buf.toString();
  }

  static String _chapterTitle(int i) {
    const titles = [
      'The First Door',
      'Dust and Memory',
      'Letters Never Sent',
      'The Amber Hour',
      'What Rain Remembers',
      'Keys and Silences',
      'The Unnamed Room',
      'Margins',
      'Archive Fever',
      'The Last Index',
    ];
    return titles[i % titles.length];
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _startGenerated() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _loadedContent = null;
    });

    final String content;
    switch (_contentType) {
      case _ContentType.manga:
        content = await compute(_generateMangaContent, _pageCount);
      case _ContentType.fairyTale:
        content = await compute(_generateFairyTaleContent, _pageCount);
      case _ContentType.novel:
        content = await compute(_generateNovelContent, _pageCount);
      case _ContentType.url:
        return; // handled by _fetchUrl
    }

    if (mounted) {
      setState(() {
        _loadedContent = content;
        _characterCount = content.length;
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchUrl() async {
    final rawUrl = _urlController.text.trim();
    if (rawUrl.isEmpty) return;

    final uri = Uri.tryParse(rawUrl);
    if (uri == null || !uri.hasScheme) {
      setState(() => _errorMessage = 'Invalid URL. Include http:// or https://');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _loadedContent = null;
    });

    try {
      final response = await http.get(
        uri,
        headers: {
          'User-Agent':
              'Mozilla/5.0 (compatible; HyperRender-Demo/1.0; +https://pub.dev/packages/hyper_render)',
          'Accept':
              'text/html,application/xhtml+xml;q=0.9,*/*;q=0.8',
          'Accept-Language': 'en-US,en;q=0.5',
        },
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        // Try UTF-8 first, fall back to latin-1
        String html;
        try {
          html = utf8.decode(response.bodyBytes);
        } catch (_) {
          html = latin1.decode(response.bodyBytes);
        }

        if (mounted) {
          setState(() {
            _loadedContent = html;
            _characterCount = html.length;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = 'HTTP ${response.statusCode}: ${response.reasonPhrase}';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  void _reset() => setState(() {
        _loadedContent = null;
        _characterCount = null;
        _errorMessage = null;
        _renderMs = null;
        _domNodeCount = null;
      });

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stress Test'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          if (_loadedContent != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _reset,
              tooltip: 'Reset',
            ),
        ],
      ),
      body: _loadedContent == null ? _buildConfigPanel() : _buildRenderPanel(),
    );
  }

  // ── Config Panel ───────────────────────────────────────────────────────────

  Widget _buildConfigPanel() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildContentTypeSelector(),
          const SizedBox(height: 20),
          if (_contentType != _ContentType.url) ...[
            _buildPageCountSelector(),
            const SizedBox(height: 20),
          ],
          if (_contentType == _ContentType.url) ...[
            _buildUrlInput(),
            const SizedBox(height: 20),
          ],
          _buildLibrarySelector(),
          const SizedBox(height: 24),
          if (_errorMessage != null) ...[
            _buildErrorBanner(_errorMessage!),
            const SizedBox(height: 16),
          ],
          _buildStartButton(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final (title, subtitle, icon, colors) = switch (_contentType) {
      _ContentType.manga => (
          'Manga Reader Test',
          'Panel grid, dark theme, float images',
          Icons.menu_book,
          [Colors.red.shade800, Colors.deepOrange.shade700],
        ),
      _ContentType.fairyTale => (
          'Fairy Tale Test',
          'Float illustrations, serif typography, quotes',
          Icons.auto_stories,
          [const Color(0xFF6B2D0C), const Color(0xFF8D4E25)],
        ),
      _ContentType.novel => (
          'Novel / Book Test',
          'Long plain text, chapters, Lorem Ipsum',
          Icons.library_books,
          [Colors.indigo.shade800, Colors.blue.shade600],
        ),
      _ContentType.url => (
          'Load from URL',
          'Fetch & render any real-world HTML page',
          Icons.language,
          [Colors.teal.shade700, Colors.cyan.shade600],
        ),
    };

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colors.first.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 13, color: Colors.white)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Content Type',
            style:
                TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _typeChip(_ContentType.manga, '🎌 Manga', Colors.red.shade700),
            _typeChip(_ContentType.fairyTale, '✨ Fairy Tale',
                const Color(0xFF6B2D0C)),
            _typeChip(_ContentType.novel, '📚 Novel', Colors.indigo),
            _typeChip(_ContentType.url, '🌐 From URL', Colors.teal),
          ],
        ),
      ],
    );
  }

  Widget _typeChip(_ContentType type, String label, Color color) {
    final selected = _contentType == type;
    return GestureDetector(
      onTap: () => setState(() {
        _contentType = type;
        // reset page count to default for new type
        _pageCount = switch (type) {
          _ContentType.manga => 10,
          _ContentType.fairyTale => 3,
          _ContentType.novel => 50,
          _ContentType.url => 0,
        };
        _errorMessage = null;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected ? color : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3))
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight:
                selected ? FontWeight.w600 : FontWeight.normal,
            color: selected ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  Widget _buildPageCountSelector() {
    final label = switch (_contentType) {
      _ContentType.manga => 'Pages (manga pages)',
      _ContentType.fairyTale => 'Scenes (story sections)',
      _ContentType.novel => 'Chapters',
      _ContentType.url => '',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          children: _pageCounts.map((count) {
            final isSelected = _pageCount == count;
            return ChoiceChip(
              label: Text('$count'),
              selected: isSelected,
              selectedColor:
                  Theme.of(context).colorScheme.primary,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : null,
                fontWeight: isSelected
                    ? FontWeight.w600
                    : FontWeight.normal,
              ),
              onSelected: (selected) {
                if (selected) setState(() => _pageCount = count);
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildUrlInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Page URL',
            style:
                TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        const Text(
          'Tip: try Project Gutenberg or Wikipedia articles for realistic HTML',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _urlController,
          keyboardType: TextInputType.url,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            hintText: 'https://example.com/article',
            border: const OutlineInputBorder(),
            filled: true,
            fillColor: Colors.grey.shade50,
            prefixIcon: const Icon(Icons.link, size: 20),
            suffixIcon: IconButton(
              icon: const Icon(Icons.clear, size: 18),
              onPressed: () => _urlController.clear(),
            ),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 14),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            _quickUrl(
                'Alice in Wonderland',
                'https://www.gutenberg.org/files/11/11-h/11-h.htm'),
            _quickUrl(
                'Grimm\'s Fairy Tales',
                'https://www.gutenberg.org/files/2591/2591-h/2591-h.htm'),
            _quickUrl('Moby Dick',
                'https://www.gutenberg.org/files/2701/2701-h/2701-h.htm'),
          ],
        ),
      ],
    );
  }

  Widget _quickUrl(String label, String url) {
    return InkWell(
      onTap: () => setState(() => _urlController.text = url),
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.teal.shade200),
          borderRadius: BorderRadius.circular(4),
          color: Colors.teal.shade50,
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12, color: Colors.teal.shade800)),
      ),
    );
  }

  Widget _buildLibrarySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Render Library',
            style:
                TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          children: _libraries.map((lib) {
            final isSelected = _selectedLibrary == lib;
            return ChoiceChip(
              label: Text(lib),
              selected: isSelected,
              selectedColor: DemoColors.success,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : null,
                fontWeight: isSelected
                    ? FontWeight.w600
                    : FontWeight.normal,
              ),
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedLibrary = lib);
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        border: Border.all(color: Colors.red.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style: TextStyle(
                    color: Colors.red.shade800, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildStartButton() {
    final isUrl = _contentType == _ContentType.url;
    final label = isUrl ? 'Fetch & Render' : 'Generate & Render';
    final icon = isUrl ? Icons.download : Icons.play_arrow;
    final action = isUrl ? _fetchUrl : _startGenerated;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : action,
        icon: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : Icon(icon),
        label:
            Text(_isLoading ? 'Loading…' : label),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.all(16),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  // ── Render Panel ───────────────────────────────────────────────────────────

  Widget _buildRenderPanel() {
    return Column(
      children: [
        _buildStatsBar(),
        Expanded(child: _buildRenderedContent()),
      ],
    );
  }

  Widget _buildStatsBar() {
    final chars = _characterCount ?? 0;
    final typeLabel = switch (_contentType) {
      _ContentType.manga => 'Manga',
      _ContentType.fairyTale => 'Fairy Tale',
      _ContentType.novel => 'Novel',
      _ContentType.url => 'URL',
    };

    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Colors.grey.shade100,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _stat(typeLabel,
              _contentType == _ContentType.url ? 'web' : '$_pageCount pg'),
          _stat('Size',
              chars > 999 ? '${(chars / 1000).toStringAsFixed(0)}K' : '$chars'),
          _stat('Library', _selectedLibrary, small: true),
          if (_renderMs != null)
            _stat('Render', '${_renderMs!.toStringAsFixed(0)} ms'),
          if (_domNodeCount != null) _stat('Nodes', '$_domNodeCount'),
        ],
      ),
    );
  }

  Widget _stat(String label, String value, {bool small = false}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: small ? 12 : 15,
                color: Theme.of(context).colorScheme.primary)),
        Text(label,
            style:
                TextStyle(fontSize: 11, color: Colors.grey.shade600)),
      ],
    );
  }

  Widget _buildRenderedContent() {
    final content = _loadedContent!;

    // Measure render time
    WidgetsBinding.instance.addPostFrameCallback((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final sw = Stopwatch()..start();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _renderMs == null) {
            setState(() => _renderMs = sw.elapsedMilliseconds.toDouble());
          }
        });
      });
    });

    switch (_selectedLibrary) {
      case 'HyperRender':
        return HyperViewer(
          html: content,
          mode: HyperRenderMode.auto,
          selectable: true,
          placeholderBuilder: (context) => _buildLoadingPlaceholder(content.length),
        );
      case 'flutter_html':
        return ClipRect(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: flutter_html.Html(data: content),
          ),
        );
      case 'fwfh':
        return ClipRect(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: fwfh.HtmlWidget(content),
          ),
        );
      case 'fwfh_core':
        return ClipRect(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: fwfh_core.HtmlWidget(content),
          ),
        );
      default:
        return const Center(child: Text('Unknown library'));
    }
  }

  Widget _buildLoadingPlaceholder(int charCount) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Parsing ${(charCount / 1000).toStringAsFixed(0)}K characters…',
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 6),
          const Text(
            'Large documents may take a few seconds',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
