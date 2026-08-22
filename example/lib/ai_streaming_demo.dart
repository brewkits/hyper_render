import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hyper_render/hyper_render.dart';

/// Interactive AI & LLM Streaming Demo for HyperRender v1.8.0.
class AiStreamingDemo extends StatefulWidget {
  final bool autoStart;
  const AiStreamingDemo({super.key, this.autoStart = false});

  @override
  State<AiStreamingDemo> createState() => _AiStreamingDemoState();
}

class _AiStreamingDemoState extends State<AiStreamingDemo> {
  final HyperStreamingController _controller = HyperStreamingController(
    throttleDuration: const Duration(milliseconds: 16),
  );

  HyperTypingCaretStyle _caretStyle = HyperTypingCaretStyle.bar;
  bool _autoRepair = true;
  bool _autoScroll = true;
  Timer? _streamTimer;
  int _chunkIndex = 0;

  @override
  void initState() {
    super.initState();
    if (widget.autoStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _startSimulation());
    }
  }

  static const List<String> _sampleTokens = [
    '# 🧠 HyperRender AI Assistant\n\n',
    'Hello! I am your **HyperRender AI** assistant streaming responses directly into Flutter.\n\n',
    '### Key Capabilities of v1.8.0 Streaming Engine:\n\n',
    '- **60 FPS Frame-Aligned Throttling**: Eliminates UI stutter during high-speed SSE bursts.\n',
    '- **Transient Syntax Normalization**: Auto-repairs unclosed markdown fences and formatting.\n',
    '- **Stick-to-Bottom Auto Scroll**: Smoothly follows output tail in real-time.\n',
    '- **Native Blinking Carets**: Customizable bar, block, underscore, and dot styles.\n\n',
    'Here is an example code snippet generated on-the-fly:\n\n',
    '```dart\n',
    '// Initialize AI Streaming Controller\n',
    'final controller = HyperStreamingController();\n',
    'controller.bindStream(geminiStream);\n\n',
    '// Render with HyperViewer.streaming\n',
    'HyperViewer.streaming(\n',
    '  streamingController: controller,\n',
    '  contentType: HyperContentType.markdown,\n',
    '  showTypingCaret: true,\n',
    ')\n',
    '```\n\n',
    '### Engine Benchmark Performance:\n\n',
    '| Metric | HyperRender 1.8 | Standard Flutter |\n',
    '|---|---|---|\n',
    '| Memory Footprint | **2.1 MB** | 18.4 MB |\n',
    '| Re-parse Overhead | **Incremental Tail** | Full Re-layout |\n',
    '| FPS during Burst | **60.0 FPS** | 24-32 FPS |\n\n',
    '✨ *Streaming generation finished successfully with zero frame drops.*',
  ];

  @override
  void dispose() {
    _streamTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _startSimulation() {
    _streamTimer?.cancel();
    _controller.reset();
    _chunkIndex = 0;

    _streamTimer = Timer.periodic(const Duration(milliseconds: 120), (timer) {
      if (_chunkIndex < _sampleTokens.length) {
        _controller.append(_sampleTokens[_chunkIndex]);
        _chunkIndex++;
      } else {
        _controller.complete();
        timer.cancel();
      }
    });
  }

  void _stopSimulation() {
    _streamTimer?.cancel();
    _controller.complete();
  }

  void _resetSimulation() {
    _streamTimer?.cancel();
    _controller.reset();
    _chunkIndex = 0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI / LLM Streaming Engine (v1.8.0)'),
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetSimulation,
            tooltip: 'Reset Stream',
          ),
        ],
      ),
      body: Column(
        children: [
          // Control Panel
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  alignment: WrapAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _startSimulation,
                          icon: const Icon(Icons.play_arrow, size: 18),
                          label: const Text('Start Stream'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: _stopSimulation,
                          icon: const Icon(Icons.stop, size: 18),
                          label: const Text('Stop'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                      ],
                    ),
                    ValueListenableBuilder<HyperStreamingState>(
                      valueListenable: _controller,
                      builder: (context, state, _) {
                        Color badgeColor = Colors.grey;
                        String statusLabel = 'IDLE';

                        switch (state.status) {
                          case HyperStreamingStatus.streaming:
                            badgeColor = Colors.green;
                            statusLabel =
                                'STREAMING (${state.tokenCount} tokens · ${state.tokensPerSecond.toStringAsFixed(1)} tps)';
                            break;
                          case HyperStreamingStatus.completed:
                            badgeColor = Colors.blue;
                            statusLabel =
                                'DONE (${state.tokenCount} tokens · ${state.tokensPerSecond.toStringAsFixed(1)} tps avg)';
                            break;
                          case HyperStreamingStatus.error:
                            badgeColor = Colors.red;
                            statusLabel = 'ERROR';
                            break;
                          case HyperStreamingStatus.idle:
                            break;
                        }

                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: badgeColor.withAlpha(25),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: badgeColor),
                          ),
                          child: Text(
                            statusLabel,
                            style: TextStyle(
                              color: badgeColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      const Text('Caret: ',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      DropdownButton<HyperTypingCaretStyle>(
                        value: _caretStyle,
                        underline: const SizedBox.shrink(),
                        isDense: true,
                        items: const [
                          DropdownMenuItem(
                            value: HyperTypingCaretStyle.bar,
                            child: Text('Bar (▍)', style: TextStyle(fontSize: 13)),
                          ),
                          DropdownMenuItem(
                            value: HyperTypingCaretStyle.block,
                            child: Text('Block (█)', style: TextStyle(fontSize: 13)),
                          ),
                          DropdownMenuItem(
                            value: HyperTypingCaretStyle.underscore,
                            child: Text('Underscore (_)', style: TextStyle(fontSize: 13)),
                          ),
                          DropdownMenuItem(
                            value: HyperTypingCaretStyle.dot,
                            child: Text('Dot (●)', style: TextStyle(fontSize: 13)),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _caretStyle = val);
                        },
                      ),
                      const SizedBox(width: 16),
                      const Text('Auto Scroll: ', style: TextStyle(fontSize: 13)),
                      Switch(
                        value: _autoScroll,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        onChanged: (v) => setState(() => _autoScroll = v),
                      ),
                      const SizedBox(width: 16),
                      const Text('Auto Repair: ', style: TextStyle(fontSize: 13)),
                      Switch(
                        value: _autoRepair,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        onChanged: (v) => setState(() => _autoRepair = v),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Main Streaming Viewer
          Expanded(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: HyperViewer.streaming(
                streamingController: _controller,
                contentType: HyperContentType.markdown,
                caretStyle: _caretStyle,
                autoRepairSyntax: _autoRepair,
                autoScrollToBottom: _autoScroll,
                showTypingCaret: true,
                caretColor: theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
