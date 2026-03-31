enum BookType { html, markdown }

class Book {
  final String id;
  final String title;
  final String author;
  final String coverUrl;
  final String content;
  final BookType type;
  final String? description;
  
  // New persistent fields
  int lastPage;
  bool isBookmarked;

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.coverUrl,
    required this.content,
    required this.type,
    this.description,
    this.lastPage = 0,
    this.isBookmarked = false,
  });
}

class MockLibrary {
  static final List<Book> books = [
    Book(
      id: '1',
      title: 'The Great Gatsby',
      author: 'F. Scott Fitzgerald',
      coverUrl: 'https://picsum.photos/seed/gatsby/400/600',
      type: BookType.html,
      description: 'A 1925 novel by American writer F. Scott Fitzgerald.',
      content: '''
<div style="font-family: serif; padding: 20px;">
  <h1 style="text-align: center; color: #1a237e;">Chapter I</h1>
  <p><span style="float: left; font-size: 3em; line-height: 0.8; margin-right: 8px; font-weight: bold;">I</span>n my younger and more vulnerable years my father gave me some advice that I’ve been turning over in my mind ever since.</p>
  <p>“Whenever you feel like criticizing any one,” he told me, “just remember that all the people in this world haven’t had the advantages that you’ve had.”</p>
  <p>He didn’t say any more, but we’ve always been unusually communicative in a reserved way, and I understood that he meant a great deal more than that. In consequence, I’m inclined to reserve all judgments, a habit that has opened up many curious natures to me and also made me the victim of not a few veteran bores. The abnormal mind is quick to detect and attach itself to this quality when it appears in a normal person, and so it came about that in college I was unjustly accused of being a politician, because I was privy to the secret griefs of wild, unknown men.</p>
  
  <div style="background-color: #f5f5f5; padding: 15px; border-left: 5px solid #1a237e; margin: 20px 0;">
    <p style="font-style: italic; margin: 0;">"Reserving judgments is a matter of infinite hope."</p>
  </div>

  <p>Most of the confidences were unsought—frequently I have feigned sleep, preoccupation, or a hostile levity when I realized by some unmistakable sign that an intimate revelation was quivering on the horizon; for the intimate revelations of young men, or at least the terms in which they express them, are usually plagiaristic and marred by obvious suppressions.</p>
  
  <img src="https://picsum.photos/seed/mansion/800/400" alt="Gatsby Mansion" style="width: 100%; border-radius: 8px; margin: 20px 0;" />
  
  <p>Reserving judgments is a matter of infinite hope. I am still a little afraid of missing something if I forget that, as my father snobbishly suggested, and I snobbishly repeat, a sense of the fundamental decencies is parcelled out unequally at birth.</p>
  
  <h2 style="color: #1a237e;">The West Egg</h2>
  <p>And, after boasting this way of my tolerance, I come to the admission that it has a limit. Conduct may be founded on the hard rock or the wet marshes, but after a certain point I don’t care what it’s founded on. When I came back from the East last autumn I felt that I wanted the world to be in uniform and at a sort of moral attention forever; I wanted no more riotous excursions with privileged glimpses into the human heart. Only Gatsby, the man who gives his name to this book, was exempt from my reaction—Gatsby, who represented everything for which I have an unaffected scorn.</p>
</div>
''',
    ),
    Book(
      id: '2',
      title: 'Dart & Flutter Guide',
      author: 'BrewKits Team',
      coverUrl: 'https://picsum.photos/seed/flutter/400/600',
      type: BookType.markdown,
      description: 'Technical guide to high-performance rendering.',
      content: '''
# Mastering Flutter Rendering

## The Render Pipeline
Flutter's rendering pipeline is designed for **60 FPS** performance. Understanding how it works is key to building complex UIs like HyperRender.

### Key Steps:
1. **Build**: Creating the widget tree.
2. **Layout**: Determining sizes and positions.
3. **Paint**: Drawing pixels on the screen.

### Code Example: Custom Painter
```dart
class MyCirclePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.blue;
    canvas.drawCircle(size.center(Offset.zero), 20.0, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
```

> **Pro Tip:** Always use `const` constructors for static widgets to skip unnecessary build cycles.

## HyperRender v1.2.0 Features
HyperRender adds a specialized layer for document-centric apps:
- **CSS Float**: Wrap text around images naturally.
- **Dirty-flag Incremental Layout**: Only rebuild what changed.
- **A11y**: Screen-reader friendly semantic nodes.
''',
    ),
    Book(
      id: '4',
      title: 'Nature: Life on Earth',
      author: 'Documentary Series',
      coverUrl: 'https://picsum.photos/seed/nature/400/600',
      type: BookType.html,
      description: 'Showcasing video and rich media in a reading context.',
      content: '''
<div style="font-family: serif; padding: 20px; line-height: 1.8;">
  <h1 style="text-align: center; color: #2e7d32;">Chapter 1: The Living Planet</h1>

  <p>Earth is home to an extraordinary diversity of life. From the frozen tundra to
  the deepest ocean trenches, living organisms have adapted to every corner of our planet.</p>

  <video
    src="https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
    poster="https://picsum.photos/seed/bunny/800/450"
    width="640"
    height="360"
    controls>
  </video>

  <p>The rainforest, often called the "lungs of the Earth," produces more than 20% of
  the world's oxygen. Home to over half of all plant and animal species, it is the
  most biodiverse ecosystem on the planet.</p>

  <div style="background-color: #e8f5e9; padding: 16px; border-left: 4px solid #2e7d32; margin: 20px 0;">
    <p style="margin: 0; font-style: italic; color: #1b5e20;">
      "In every walk with nature, one receives far more than he seeks." — John Muir
    </p>
  </div>

  <h2 style="color: #2e7d32;">Chapter 2: Ocean Depths</h2>

  <p>Less than 20% of the ocean floor has been mapped. The deep sea, beginning
  below 200 metres, is a world of perpetual darkness, crushing pressure and
  extraordinary creatures.</p>

  <video
    src="https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4"
    poster="https://picsum.photos/seed/ocean/800/450"
    width="640"
    height="360"
    controls>
  </video>

  <p>Bioluminescent organisms light up the darkness with their own natural glow.
  From anglerfish to deep-sea jellyfish, nature has invented light in the absence
  of the sun.</p>
</div>
''',
    ),
    Book(
      id: '3',
      title: 'Japanese Literature',
      author: 'Classical Anthology',
      coverUrl: 'https://picsum.photos/seed/japan/400/600',
      type: BookType.html,
      description: 'Showcasing CJK Ruby and typography.',
      content: '''
<div style="font-family: serif; padding: 20px; line-height: 1.8;">
  <h1 style="text-align: center;">日本語の<ruby>美<rt>うつく</rt></ruby>しさ</h1>
  
  <p>HyperRenderは<ruby>日本語<rt>にほんご</rt></ruby>の<ruby>表示<rt>ひょうじ</rt></ruby>に<ruby>特化<rt>とっか</rt></ruby>したレンダリングエンジンです。</p>

  <div style="background-color: #fdf6e3; padding: 20px; border: 1px solid #eee8d5; border-radius: 4px; margin: 20px 0;">
    <p style="margin: 0;">
      <ruby>漢字<rt>かんじ</rt></ruby>の上に<ruby>振<rt>ふ</rt></ruby>り<ruby>仮名<rt>がな</rt></ruby>（ふりがな）を<ruby>表示<rt>ひょうじ</rt></ruby>することが<ruby>可能<rt>かのう</rt></ruby>です。
      これを「ルビ」と<ruby>呼<rt>よ</rt></ruby>びます。
    </p>
  </div>

  <p>
    <ruby>夏目<rt>なつめ</rt></ruby><ruby>漱石<rt>そうせき</rt></ruby>の『<ruby>吾輩<rt>わがはい</rt></ruby>は<ruby>猫<rt>ねこ</rt></ruby>である』：
  </p>
  
  <p style="font-size: 1.2em; padding-left: 20px; border-left: 3px solid #ccc;">
    <ruby>吾輩<rt>わがはい</rt></ruby>は<ruby>猫<rt>ねこ</rt></ruby>である。<ruby>名前<rt>なまえ</rt></ruby>はまだない。<br>
    どこで<ruby>生<rt>う</rt></ruby>まれたか<ruby>頓<rt>とん</rt></ruby>と<ruby>見当<rt>けんとう</rt></ruby>がつかぬ。<br>
    <ruby>何<rt>なに</rt></ruby> elementary <ruby>薄暗<rt>うすぐら</rt></ruby>いじめじめした<ruby>所<rt>ところ</rt></ruby>でニャーニャー<ruby>泣<rt>な</rt></ruby>いていた<ruby>事<rt>こと</rt></ruby>だけは<ruby>記憶<rt>きおく</rt></ruby>している。
  </p>

  <p>このように、HyperRenderはアジア<ruby>言語<rt>げんご</rt></ruby>の<ruby>組版<rt>くmihan</rt></ruby>（タイポグラフィ）に<ruby>必要<rt>ひつよう</rt></ruby>な<ruby>機能<rt>きのう</rt></ruby>をすべて<ruby>備<rt>そな</rt></ruby>えています。</p>
</div>
''',
    ),
  ];
}
