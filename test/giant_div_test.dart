import "package:hyper_render/hyper_render.dart";
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HtmlAdapter - Giant Div Flattening', () {
    late HtmlAdapter adapter;

    setUp(() {
      adapter = HtmlAdapter();
    });

    test('parseToSections handles nested div wrapper correctly', () {
      // This is the "Giant Div" edge case:
      // All content wrapped in a single <div id="container">
      final html = '''
<body>
  <div id="container">
    <p>Paragraph 1</p>
    <p>Paragraph 2</p>
    <p>Paragraph 3</p>
    <p>Paragraph 4</p>
    <p>Paragraph 5</p>
    <p>Paragraph 6</p>
    <p>Paragraph 7</p>
    <p>Paragraph 8</p>
    <p>Paragraph 9</p>
    <p>Paragraph 10</p>
  </div>
</body>
''';

      // With small chunkSize, we should get multiple sections
      // NOT just 1 section containing the entire div
      final sections = adapter.parseToSections(html, chunkSize: 50);

      // Should have more than 1 section due to flattening
      expect(sections.length, greaterThan(1),
          reason: 'Giant div should be flattened into multiple sections');
    });

    test('parseToSections handles deeply nested structure', () {
      // Multiple levels of nesting
      final html = '''
<body>
  <div class="wrapper">
    <div class="container">
      <section class="content">
        <p>Paragraph 1 with some content to increase size</p>
        <p>Paragraph 2 with some content to increase size</p>
        <p>Paragraph 3 with some content to increase size</p>
        <p>Paragraph 4 with some content to increase size</p>
        <p>Paragraph 5 with some content to increase size</p>
        <p>Paragraph 6 with some content to increase size</p>
      </section>
    </div>
  </div>
</body>
''';

      final sections = adapter.parseToSections(html, chunkSize: 100);

      // Should flatten through all nested containers
      expect(sections.length, greaterThan(1),
          reason: 'Deeply nested structure should be flattened');
    });

    test('parseToSections preserves small containers', () {
      // Small containers should NOT be flattened
      final html = '''
<body>
  <div class="card">
    <h3>Card Title</h3>
    <p>Short content</p>
  </div>
  <div class="card">
    <h3>Another Card</h3>
    <p>Short content</p>
  </div>
</body>
''';

      final sections = adapter.parseToSections(html, chunkSize: 5000);

      // With large chunkSize, small divs should be preserved
      // Both cards might be in same section
      expect(sections.length, greaterThanOrEqualTo(1));

      // The structure should be preserved (cards not flattened)
      final firstSection = sections.first;
      expect(firstSection.children.isNotEmpty, true);
    });

    test('parseToSections handles real-world blog post structure', () {
      // Simulating a typical blog post wrapped in article
      final html = '''
<body>
  <article class="blog-post">
    <header>
      <h1>Blog Post Title</h1>
      <p class="meta">Posted on December 2024</p>
    </header>
    <div class="content">
      <p>Introduction paragraph with some text that spans multiple lines and contains important information for the reader to understand the context of this article.</p>
      <h2>Section 1</h2>
      <p>Content for section 1 with detailed explanation about the topic being discussed in this particular section of the blog post.</p>
      <h2>Section 2</h2>
      <p>Content for section 2 with more detailed explanation and examples that help illustrate the point being made.</p>
      <h2>Section 3</h2>
      <p>Content for section 3 with conclusion and summary of what was discussed in the previous sections.</p>
      <h2>Section 4</h2>
      <p>Additional content that extends the discussion further with more examples and use cases.</p>
    </div>
    <footer>
      <p>Author: John Doe</p>
    </footer>
  </article>
</body>
''';

      final sections = adapter.parseToSections(html, chunkSize: 200);

      // Should produce multiple sections for virtualization
      expect(sections.length, greaterThan(1),
          reason: 'Blog post should be split into multiple sections for virtualization');

      // Verify total content is preserved
      int totalChildren = 0;
      for (final section in sections) {
        totalChildren += section.children.length;
      }
      expect(totalChildren, greaterThan(0));
    });

    test('parseToSections handles article/main/section tags', () {
      // These semantic HTML5 tags should also be flattened
      final html = '''
<body>
  <main>
    <section>
      <p>Section 1 paragraph 1</p>
      <p>Section 1 paragraph 2</p>
    </section>
    <section>
      <p>Section 2 paragraph 1</p>
      <p>Section 2 paragraph 2</p>
    </section>
    <aside>
      <p>Sidebar content</p>
    </aside>
  </main>
</body>
''';

      final sections = adapter.parseToSections(html, chunkSize: 50);

      // Should flatten through main/section/aside
      expect(sections.length, greaterThan(1),
          reason: 'Semantic HTML5 containers should be flattened');
    });
  });

  group('HtmlAdapter - Edge Cases', () {
    late HtmlAdapter adapter;

    setUp(() {
      adapter = HtmlAdapter();
    });

    test('handles empty body', () {
      final html = '<body></body>';
      final sections = adapter.parseToSections(html);
      expect(sections.length, 1); // Should have at least empty section
    });

    test('handles body with only whitespace', () {
      final html = '<body>   \n\t  </body>';
      final sections = adapter.parseToSections(html);
      expect(sections.length, 1);
    });

    test('handles flat structure (no nesting)', () {
      final html = '''
<body>
  <p>Para 1</p>
  <p>Para 2</p>
  <p>Para 3</p>
</body>
''';
      final sections = adapter.parseToSections(html, chunkSize: 10);
      expect(sections.length, greaterThan(1),
          reason: 'Flat structure should still be chunked');
    });
  });
}
