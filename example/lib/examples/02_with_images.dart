/// Example 02: HTML with Images
///
/// Demonstrates image rendering including:
/// - Network images
/// - CSS float layout (text wrapping)
/// - Image sizing and styling
/// - Alt text for accessibility
library;

import 'package:flutter/material.dart';
import 'package:hyper_render/hyper_render.dart';

class WithImagesExample extends StatelessWidget {
  const WithImagesExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('02: With Images'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: HyperViewer(
          html: '''
            <article>
              <h1>CSS Float Layout Demo</h1>

              <p>
                HyperRender is the <strong>only Flutter HTML library</strong> that
                supports true CSS float layout. This allows text to wrap naturally
                around floated images, just like in a web browser.
              </p>

              <!-- Float left example -->
              <img
                src="https://picsum.photos/200/300"
                alt="Floated image example"
                style="float: left; width: 150px; margin: 0 16px 16px 0; border-radius: 8px;"
              />

              <p>
                This image is floated to the left with CSS <code>float: left</code>.
                Notice how this text wraps naturally around the image, filling the
                available space. This is architecturally impossible in widget-tree
                based HTML renderers because they don't have a shared coordinate system.
              </p>

              <p>
                HyperRender achieves this by using a single custom RenderObject that
                lays out and paints the entire document in one pass. The text and
                images share the same coordinate space, enabling proper float layout.
              </p>

              <p>
                You can float images left or right, add margins and borders, and the
                text will flow around them naturally. This is essential for magazine-style
                layouts, blog posts with inline images, and news articles.
              </p>

              <!-- Clear floats -->
              <div style="clear: both;"></div>

              <h2>Regular Images</h2>

              <p>Images can also be displayed as regular block elements:</p>

              <img
                src="https://picsum.photos/800/400"
                alt="Full-width image"
                style="width: 100%; border-radius: 12px; margin: 16px 0;"
              />

              <p style="text-align: center; color: #666;">
                <em>Full-width image with rounded corners</em>
              </p>

              <h2>Image Gallery</h2>

              <p>Multiple images in a row:</p>

              <div style="display: flex; gap: 8px; flex-wrap: wrap;">
                <img
                  src="https://picsum.photos/200/200?1"
                  alt="Gallery image 1"
                  style="width: 100px; height: 100px; object-fit: cover; border-radius: 8px;"
                />
                <img
                  src="https://picsum.photos/200/200?2"
                  alt="Gallery image 2"
                  style="width: 100px; height: 100px; object-fit: cover; border-radius: 8px;"
                />
                <img
                  src="https://picsum.photos/200/200?3"
                  alt="Gallery image 3"
                  style="width: 100px; height: 100px; object-fit: cover; border-radius: 8px;"
                />
              </div>

              <h2>Float Right Example</h2>

              <img
                src="https://picsum.photos/180/240"
                alt="Floated right image"
                style="float: right; width: 140px; margin: 0 0 16px 16px; border-radius: 8px; box-shadow: 0 2px 8px rgba(0,0,0,0.1);"
              />

              <p>
                This image is floated to the <strong>right</strong> side. The text
                flows on the left side, filling the available space.
              </p>

              <p>
                You can add CSS styles like <code>border-radius</code> and
                <code>box-shadow</code> to make images more visually appealing.
              </p>

              <p>
                Float layout is perfect for creating professional-looking articles,
                blog posts, and documentation with inline illustrations.
              </p>

              <div style="clear: both;"></div>

              <hr>

              <p style="font-size: 14px; color: #666;">
                <strong>Note:</strong> Images are loaded from picsum.photos (placeholder service).
                In production, use your own images.
              </p>
            </article>
          ''',
          // Handle link taps
          onLinkTap: (url) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Link: $url')),
            );
          },
          // Handle image taps (if needed)
          onImageTap: (url) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Image Tapped'),
                content: Text('Image URL: $url'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
