import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hyper_render/hyper_render.dart';

class FloatHellDemo extends StatefulWidget {
  const FloatHellDemo({super.key});

  @override
  State<FloatHellDemo> createState() => _FloatHellDemoState();
}

class _FloatHellDemoState extends State<FloatHellDemo>
    with SingleTickerProviderStateMixin {
  late String _html;
  late AnimationController _ctrl;
  bool _animateWidth = false;

  @override
  void initState() {
    super.initState();
    _generate();
    _ctrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 4))
          ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _generate() {
    final buf = StringBuffer();
    buf.write('<div style="font-family: sans-serif; padding: 10px;">');
    buf.write('<h1>Float Hell Stress Test</h1>');
    buf.write(
        '<p>This document contains 2000 paragraphs and floats to test virtualized rendering memory limits and float carryover logic.</p>');

    final r = Random(42);
    // 2000 blocks -> roughly 300-500KB of HTML, perfect for virtualization
    for (int i = 0; i < 2000; i++) {
      final isLeft = r.nextBool();
      final width = 50 + r.nextInt(100);
      final height = 50 + r.nextInt(150);
      final color = isLeft ? '#e53935' : '#1e88e5';

      if (r.nextDouble() < 0.4) {
        buf.write('''
          <div style="float: ${isLeft ? 'left' : 'right'}; width: ${width}px; height: ${height}px; background: $color; margin: 5px; color: white; display: flex; align-items: center; justify-content: center; font-size: 10px;">
            ${isLeft ? 'L' : 'R'}-$i
          </div>
        ''');
      }

      final textLen = 10 + r.nextInt(150);
      buf.write(
          '<p style="color: #333; margin-bottom: 10px;"><b>Block $i:</b> ');
      for (int j = 0; j < textLen; j++) {
        final word = r.nextBool() ? 'float' : 'layout';
        buf.write('$word ');
      }
      buf.write('</p>');

      if (r.nextDouble() < 0.05) {
        buf.write(
            '<div style="clear: both; background: #eee; padding: 5px; text-align: center; border: 1px solid #ccc;">--- Clear Both ---</div>');
      }
    }
    buf.write('</div>');
    _html = buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sprint 1: Float & Memory Stress'),
        actions: [
          Row(
            children: [
              const Text('Animate Width:', style: TextStyle(fontSize: 12)),
              Switch(
                value: _animateWidth,
                onChanged: (v) => setState(() => _animateWidth = v),
              ),
            ],
          )
        ],
      ),
      body: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, child) {
          final padding = _animateWidth ? (_ctrl.value * 150.0) : 0.0;
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: padding),
            child: child,
          );
        },
        child: HyperViewer(
          html: _html,
          mode: HyperRenderMode.virtualized,
          selectable: true,
        ),
      ),
    );
  }
}
