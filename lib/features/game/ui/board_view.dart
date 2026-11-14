import 'dart:math';

import 'package:flutter/material.dart';

import '../game/game_controller.dart';
import '../game/pipes.dart';
import 'particles.dart';

/// Dibuja una loseta: tubos hacia cada lado conectado, nodo central y,
/// si es la fuente, un núcleo brillante.
class TilePainter extends CustomPainter {
  TilePainter({
    required this.mask,
    required this.powered,
    required this.isSource,
    required this.onColor,
    required this.offColor,
    required this.bgColor,
    required this.glow,
  });

  final int mask;
  final bool powered;
  final bool isSource;
  final Color onColor;
  final Color offColor;
  final Color bgColor;
  final double glow; // 0..1 pulso de energía

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final c = Offset(s / 2, s / 2);
    final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(1.5, 1.5, s - 3, s - 3), Radius.circular(s * 0.16));
    canvas.drawRRect(rrect, Paint()..color = bgColor);

    final color = powered ? onColor : offColor;
    final stroke = s * 0.2;
    final pipe = Paint()
      ..color = color
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    if (powered) {
      // Resplandor suave detrás de los tubos energizados.
      final g = Paint()
        ..color = onColor.withValues(alpha: 0.25 + 0.2 * glow)
        ..strokeWidth = stroke * 1.9
        ..strokeCap = StrokeCap.round
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.08);
      for (final d in const [kN, kE, kS, kW]) {
        if (mask & d != 0) canvas.drawLine(c, _edge(c, s, d), g);
      }
    }
    for (final d in const [kN, kE, kS, kW]) {
      if (mask & d != 0) canvas.drawLine(c, _edge(c, s, d), pipe);
    }
    canvas.drawCircle(c, stroke * 0.65, Paint()..color = color);
    if (bitCount(mask) == 1) {
      // Extremo (hoja): un anillo para distinguirlo.
      canvas.drawCircle(
          c,
          stroke * 0.95,
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = s * 0.05);
    }
    if (isSource) {
      canvas.drawCircle(c, stroke * 1.05, Paint()..color = onColor);
      canvas.drawCircle(c, stroke * 0.5, Paint()..color = Colors.white);
    }
  }

  Offset _edge(Offset c, double s, int d) {
    final dl = kDelta[d]!;
    return c + Offset(dl[0] * s / 2, dl[1] * s / 2);
  }

  @override
  bool shouldRepaint(TilePainter o) =>
      o.mask != mask ||
      o.powered != powered ||
      o.isSource != isSource ||
      o.glow != glow ||
      o.onColor != onColor ||
      o.bgColor != bgColor;
}

/// Loseta con animación de giro: al cambiar la máscara, anima desde
/// -90° (giro horario) o +90° (deshacer) hasta 0°.
class _TileCell extends StatefulWidget {
  const _TileCell({
    required this.mask,
    required this.powered,
    required this.isSource,
    required this.onTap,
  });
  final int mask;
  final bool powered;
  final bool isSource;
  final VoidCallback onTap;
  @override
  State<_TileCell> createState() => _TileCellState();
}

class _TileCellState extends State<_TileCell> with TickerProviderStateMixin {
  late final AnimationController _rot =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 180), value: 1);
  late final AnimationController _pulse = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1600));
  double _startAngle = 0;

  @override
  void initState() {
    super.initState();
    if (widget.powered) _pulse.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_TileCell old) {
    super.didUpdateWidget(old);
    if (old.mask != widget.mask) {
      _startAngle = rotateCw(old.mask) == widget.mask ? -pi / 2 : pi / 2;
      _rot.forward(from: 0);
    }
    if (widget.powered && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (!widget.powered && _pulse.isAnimating) {
      _pulse.stop();
    }
  }

  @override
  void dispose() {
    _rot.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([_rot, _pulse]),
        builder: (_, _) {
          final k = Curves.easeOutBack.transform(_rot.value);
          return Transform.rotate(
            angle: _startAngle * (1 - k),
            child: CustomPaint(
              size: Size.infinite, // sin esto la loseta mediría 0x0
              painter: TilePainter(
                mask: widget.mask,
                powered: widget.powered,
                isSource: widget.isSource,
                onColor: cs.tertiary == cs.primary ? cs.secondary : cs.primary,
                offColor: cs.outline,
                bgColor: cs.surfaceContainerHighest,
                glow: _pulse.value,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Tablero completo: cuadrícula de losetas + capa de partículas.
class BoardView extends StatefulWidget {
  const BoardView({super.key, required this.controller});
  final GameController controller;
  @override
  State<BoardView> createState() => BoardViewState();
}

class BoardViewState extends State<BoardView> {
  final GlobalKey<ParticleFieldState> _particles = GlobalKey();
  double _cell = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.onTileEffect = (i, gained) {
      final n = widget.controller.state.size;
      final o = Offset(((i % n) + 0.5) * _cell, ((i ~/ n) + 0.5) * _cell);
      final cs = Theme.of(context).colorScheme;
      _particles.currentState
          ?.emit(o, gained ? cs.primary : cs.outline, count: gained ? 14 : 5);
    };
  }

  /// Lluvia de partículas al ganar.
  void celebrate() {
    final cs = Theme.of(context).colorScheme;
    final n = widget.controller.state.size;
    final rng = Random();
    final colors = [cs.primary, cs.secondary, cs.tertiary, Colors.amber];
    for (var k = 0; k < 10; k++) {
      _particles.currentState?.emit(
        Offset(rng.nextDouble() * n * _cell, rng.nextDouble() * n * _cell),
        colors[k % colors.length],
        count: 18,
        speed: 220,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    return ListenableBuilder(
      listenable: c,
      builder: (context, _) {
        final n = c.state.size;
        return AspectRatio(
          aspectRatio: 1,
          child: LayoutBuilder(builder: (context, box) {
            _cell = box.maxWidth / n;
            return Stack(children: [
              Column(children: [
                for (var y = 0; y < n; y++)
                  Expanded(
                    child: Row(children: [
                      for (var x = 0; x < n; x++)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(1),
                            child: _TileCell(
                              mask: c.state.tiles[y * n + x],
                              powered: c.powered.contains(y * n + x),
                              isSource: c.state.source == y * n + x,
                              onTap: () => c.rotate(y * n + x),
                            ),
                          ),
                        ),
                    ]),
                  ),
              ]),
              Positioned.fill(child: ParticleField(key: _particles)),
            ]);
          }),
        );
      },
    );
  }
}
