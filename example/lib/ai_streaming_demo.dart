import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hyper_render/hyper_render.dart';

/// Interactive AI & LLM Streaming Demo for HyperRender v1.8.0.
class AiStreamingDemo extends StatefulWidget {
  const AiStreamingDemo({super.key});

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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _startSimulation,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Start Stream'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: _stopSimulation,
                      icon: const Icon(Icons.stop),
                      label: const Text('Stop'),
                    ),
                    const Spacer(),
                    ValueListenableBuilder<HyperStreamingState>(
                      valueListenable: _controller,
                      builder: (context, state, _) {
                        Color badgeColor = Colors.grey;
                        String statusLabel = 'IDLE';

                        switch (state.status) {
                          case HyperStreamingStatus.streaming:
                            badgeColor = Colors.green;
                            statusLabel =
                                'STREAMING (${state.tokenCount} chunks)';
                            break;
                          case HyperStreamingStatus.completed:
                            badgeColor = Colors.blue;
                            statusLabel = 'DONE (${state.tokenCount} chunks)';
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
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: badgeColor.withAlpha(30),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: badgeColor),
                          ),
                          child: Text(
                            statusLabel,
                            style: TextStyle(
                              color: badgeColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('Caret Style: ',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    DropdownButton<HyperTypingCaretStyle>(
                      value: _caretStyle,
                      underline: const SizedBox.shrink(),
                      items: const [
                        DropdownMenuItem(
                          value: HyperTypingCaretStyle.bar,
                          child: Text('Bar (▍)'),
                        ),
                        DropdownMenuItem(
                          value: HyperTypingCaretStyle.block,
                          child: Text('Block (█)'),
                        ),
                        DropdownMenuItem(
                          value: HyperTypingCaretStyle.underscore,
                          child: Text('Underscore (_)'),
                        ),
                        DropdownMenuItem(
                          value: HyperTypingCaretStyle.dot,
                          child: Text('Dot (●)'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _caretStyle = val);
                      },
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        const Text('Auto Scroll: '),
                        Switch(
                          value: _autoScroll,
                          onChanged: (v) => setState(() => _autoScroll = v),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    Row(
                      children: [
                        const Text('Auto Repair: '),
                        Switch(
                          value: _autoRepair,
                          onChanged: (v) => setState(() => _autoRepair = v),
                        ),
                      ],
                    ),
                  ],
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
