import 'package:flutter/material.dart';
import 'package:hyper_render/hyper_render.dart';

import 'demo_colors.dart';

class ZeroPaddingImageDemo extends StatelessWidget {
  const ZeroPaddingImageDemo({super.key});

  static const html = '''
<style>
  .article-header {
    background: #1A56DB;
    color: white;
    padding: 32px 20px;
    margin-bottom: 0;
  }
  
  .article-title {
    font-size: 28px;
    font-weight: 800;
    margin: 0;
    line-height: 1.2;
  }
  
  .article-meta {
    font-size: 14px;
    opacity: 0.8;
    margin-top: 12px;
  }

  /* IMMERSIVE IMAGE: Truly edge-to-edge */
  .immersive-img {
    width: 100%;
    display: block;
    margin: 0;
    padding: 0;
    /* Explicit height since height:auto isn't supported yet */
    height: 240px;
    object-fit: cover;
  }
  
  .content-section {
    padding: 24px 20px;
    background: white;
  }
  
  .paragraph {
    font-size: 17px;
    line-height: 1.7;
    color: #374151;
    margin-bottom: 20px;
  }
  
  /* STANDARD IMAGE: Respects container padding */
  .standard-img {
    width: 100%;
    height: 180px;
    border-radius: 12px;
    margin: 24px 0;
    box-shadow: 0 4px 20px rgba(0,0,0,0.1);
  }
  
  .caption {
    font-size: 13px;
    color: #6B7280;
    text-align: center;
    margin-top: -16px;
    margin-bottom: 24px;
    font-style: italic;
  }
  
  .accent-box {
    background: #EFF6FF;
    border-left: 4px solid #3B82F6;
    padding: 16px;
    margin: 24px 0;
    border-radius: 0 8px 8px 0;
  }
</style>

<div style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; background: #f8f9fa; margin: 0; padding: 0;">
  <div class="article-header">
    <h1 class="article-title">Edge-to-Edge Typography</h1>
    <div class="article-meta">Published May 14, 2026 • 5 min read</div>
  </div>

  <!-- IMMERSIVE IMAGE: BREAKS OUT OF PADDING -->
  <img src="https://picsum.photos/seed/edge_main/1200/600" class="immersive-img" alt="Main hero">

  <div class="content-section">
    <p class="paragraph">
      HyperRender 2.0 now supports <strong>true edge-to-edge</strong> images. 
      By setting <code>_kImageMargin</code> to 0.0 in the core engine, 
      <code>width: 100%</code> images now fill the entire available width of their container.
    </p>
    
    <div class="accent-box">
      <strong>Developer Tip:</strong> To create the "Modern Reader" look, wrap your <code>HyperViewer</code> 
      without any Flutter-level padding, and handle horizontal spacing entirely within your CSS.
    </div>

    <p class="paragraph">
      In this demo, the header and this text section have 20px of horizontal padding defined in CSS, 
      while the hero image above and the secondary image below span the full width of your device.
    </p>
  </div>

  <!-- ANOTHER IMMERSIVE IMAGE -->
  <img src="https://picsum.photos/seed/edge_mid/1200/600" class="immersive-img" style="height: 200px;" alt="Mid article image">

  <div class="content-section" style="padding-top: 24px;">
    <p class="paragraph">
      Below is a <strong>standard image</strong>. It is placed inside a container with padding, 
      so it respects the margins. We've also added a <code>border-radius</code> and <code>box-shadow</code> 
      to demonstrate high-end visual styling.
    </p>
    
    <!-- STANDARD PADDED IMAGE -->
    <img src="https://picsum.photos/seed/standard/800/400" class="standard-img" alt="Standard image">
    <div class="caption">Figure 1: A standard image respecting container padding.</div>
    
    <p class="paragraph">
      The combination of immersive full-bleed imagery and perfectly aligned typography 
      makes HyperRender the choice for premium publishing applications.
    </p>
    
    <div style="height: 60px;"></div>
  </div>
</div>
''';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: buildDemoAppBar(
        context,
        title: 'Edge-to-Edge Layout',
        accent: const Color(0xFF1A56DB),
      ),
      body: SafeArea(
        top: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: const HyperViewer(
              html: html,
              selectable: true,
            ),
          ),
        ),
      ),
    );
  }
}
