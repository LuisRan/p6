import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class _Particle {
  _Particle(this.pos, this.vel, this.color, this.life, this.size);
  Offset pos;
  Offset vel;
  final Color color;
  final double life;
  final double size;
  double age = 0;
}

/// Campo de partículas simple: un Ticker avanza la simulación y un
/// CustomPainter dibuja círculos que se desvanecen. Se lanza con [emit].
class ParticleField extends StatefulWidget {
  const ParticleField({super.key});
  @override
  State<ParticleField> createState() => ParticleFieldState();
}

class ParticleFieldState extends State<ParticleField>
    with SingleTickerProviderStateMixin {
  final List<_Particle> _ps = [];
  final Random _rng = Random();
  late final Ticker _ticker;
  Duration _last = Duration.zero;
  final ValueNotifier<int> _repaint = ValueNotifier(0);

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
  }

  void _onTick(Duration t) {
    final dt = ((t - _last).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _last = t;
    for (final p in _ps) {
      p.age += dt;
      p.pos += p.vel * dt;
      p.vel = Offset(p.vel.dx * 0.97, p.vel.dy * 0.97 + 120 * dt); // gravedad
    }
    _ps.removeWhere((p) => p.age >= p.life);
    _repaint.value++;
    if (_ps.isEmpty) {
      _ticker.stop();
    }
  }

  /// Lanza [count] partículas desde [origin] con el color dado.
  void emit(Offset origin, Color color, {int count = 12, double speed = 140}) {
    for (var i = 0; i < count; i++) {
      final a = _rng.nextDouble() * 2 * pi;
      final v = speed * (0.4 + _rng.nextDouble());
      _ps.add(_Particle(origin, Offset(cos(a) * v, sin(a) * v), color,
          0.5 + _rng.nextDouble() * 0.6, 2 + _rng.nextDouble() * 3));
    }
    if (!_ticker.isActive) {
      _last = Duration.zero;
      _ticker.start();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _repaint.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: CustomPaint(
          painter: _ParticlePainter(_ps, _repaint),
          size: Size.infinite,
        ),
      );
}

class _ParticlePainter extends CustomPainter {
  _ParticlePainter(this.ps, Listenable repaint) : super(repaint: repaint);
  final List<_Particle> ps;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final p in ps) {
      final k = 1 - p.age / p.life;
      paint.color = p.color.withValues(alpha: k.clamp(0.0, 1.0));
      canvas.drawCircle(p.pos, p.size * (0.5 + k / 2), paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => true;
}
