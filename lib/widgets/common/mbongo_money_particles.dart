import 'dart:math';
import 'package:flutter/material.dart';

class MbongoMoneyParticles extends StatefulWidget {
  final double height;
  final Color color;
  final int count;
  final double opacity;

  const MbongoMoneyParticles({
    super.key,
    this.height = 160,
    required this.color,
    this.count = 18,
    this.opacity = 0.10,
  });

  @override
  State<MbongoMoneyParticles> createState() => _MbongoMoneyParticlesState();
}

class _MbongoMoneyParticlesState extends State<MbongoMoneyParticles>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final Random _random = Random();
  late final List<_ParticleNode> _nodes;

  @override
  void initState() {
    super.initState();
    _nodes = List.generate(
      widget.count,
      (_) => _ParticleNode(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        r: 2 + _random.nextDouble() * 3.5,
        dx: (_random.nextDouble() - 0.5) * 0.02,
        dy: (_random.nextDouble() - 0.5) * 0.02,
      ),
    );

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _tick() {
    for (final n in _nodes) {
      n.x += n.dx;
      n.y += n.dy;

      if (n.x < 0 || n.x > 1) n.dx *= -1;
      if (n.y < 0 || n.y > 1) n.dy *= -1;

      n.x = n.x.clamp(0.0, 1.0);
      n.y = n.y.clamp(0.0, 1.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) {
          _tick();
          return CustomPaint(
            painter: _MbongoMoneyParticlesPainter(
              nodes: _nodes,
              color: widget.color.withValues(alpha: widget.opacity),            
            ),
            child: const SizedBox.expand(),
          );
        },
      ),
    );
  }
}

class _ParticleNode {
  double x;
  double y;
  double r;
  double dx;
  double dy;

  _ParticleNode({
    required this.x,
    required this.y,
    required this.r,
    required this.dx,
    required this.dy,
  });
}

class _MbongoMoneyParticlesPainter extends CustomPainter {
  final List<_ParticleNode> nodes;
  final Color color;

  _MbongoMoneyParticlesPainter({
    required this.nodes,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()
      ..color = color.withValues(alpha: 0.95)
      ..style = PaintingStyle.fill;

    final positions = nodes
        .map((n) => Offset(n.x * size.width, n.y * size.height))
        .toList();

    for (int i = 0; i < positions.length; i++) {
      for (int j = i + 1; j < positions.length; j++) {
        final d = (positions[i] - positions[j]).distance;
        if (d < 90) {
          canvas.drawLine(positions[i], positions[j], linePaint);
        }
      }
    }

    for (int i = 0; i < nodes.length; i++) {
      canvas.drawCircle(positions[i], nodes[i].r, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}