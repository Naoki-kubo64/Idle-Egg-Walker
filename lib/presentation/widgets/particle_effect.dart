import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';

/// 背景パーティクルエフェクト
/// 
/// 星や光の粒子がふわふわ浮遊する演出
class ParticleEffect extends StatefulWidget {
  const ParticleEffect({super.key});

  @override
  State<ParticleEffect> createState() => _ParticleEffectState();
}

class _ParticleEffectState extends State<ParticleEffect>
    with SingleTickerProviderStateMixin {
  final List<Particle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _generateParticles();
  }

  void _generateParticles() {
    for (int i = 0; i < 20; i++) {
      _particles.add(Particle(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        size: _random.nextDouble() * 4 + 2,
        speed: _random.nextDouble() * 0.3 + 0.1,
        opacity: _random.nextDouble() * 0.5 + 0.1,
        delay: _random.nextInt(5000),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Stack(
      children: _particles.map((particle) {
        return Positioned(
          left: particle.x * size.width,
          top: particle.y * size.height,
          child: _ParticleWidget(particle: particle),
        );
      }).toList(),
    );
  }
}

class _ParticleWidget extends StatelessWidget {
  final Particle particle;

  const _ParticleWidget({required this.particle});

  @override
  Widget build(BuildContext context) {
    final colors = [
      AppTheme.primaryColor,
      AppTheme.secondaryColor,
      AppTheme.accentGold,
      AppTheme.accentPink,
    ];
    final color = colors[particle.delay % colors.length];

    return Container(
      width: particle.size,
      height: particle.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: particle.opacity),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: particle.opacity * 0.5),
            blurRadius: particle.size * 2,
            spreadRadius: particle.size * 0.5,
          ),
        ],
      ),
    )
    .animate(
      delay: Duration(milliseconds: particle.delay),
      onPlay: (controller) => controller.repeat(reverse: true),
    )
    .moveY(
      begin: 0,
      end: -50 * particle.speed,
      duration: Duration(milliseconds: (3000 / particle.speed).round()),
      curve: Curves.easeInOut,
    )
    .fadeIn(duration: 1.seconds)
    .then()
    .fadeOut(duration: 1.seconds);
  }
}

class Particle {
  final double x;
  final double y;
  final double size;
  final double speed;
  final double opacity;
  final int delay;

  Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
    required this.delay,
  });
}
