import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/watch_party_provider.dart';

class _Particle {
  final Key key;
  final String emoji;
  final double startX;
  final double driftX;
  final double scale;

  _Particle({
    required this.key,
    required this.emoji,
    required this.startX,
    required this.driftX,
    required this.scale,
  });
}

/// Floating animated emoji reactions rendered over the video player screen.
class FloatingEmojiParticles extends ConsumerStatefulWidget {
  const FloatingEmojiParticles({super.key});

  @override
  ConsumerState<FloatingEmojiParticles> createState() =>
      _FloatingEmojiParticlesState();
}

class _FloatingEmojiParticlesState extends ConsumerState<FloatingEmojiParticles>
    with TickerProviderStateMixin {
  final List<_Particle> _activeParticles = [];
  final Random _random = Random();

  @override
  Widget build(BuildContext context) {
    ref.listen<String?>(
      watchPartyProvider.select((s) => s.latestEmoji),
      (prev, next) {
        if (next != null && next.isNotEmpty) {
          _spawnParticles(next);
          ref.read(watchPartyProvider.notifier).clearLatestEmoji();
        }
      },
    );

    if (_activeParticles.isEmpty) {
      return const SizedBox.shrink();
    }

    return IgnorePointer(
      child: Stack(
        children: _activeParticles.map((p) {
          return _SingleParticleWidget(
            key: p.key,
            particle: p,
            onComplete: () {
              if (mounted) {
                setState(() {
                  _activeParticles.removeWhere((item) => item.key == p.key);
                });
              }
            },
          );
        }).toList(),
      ),
    );
  }

  void _spawnParticles(String emoji) {
    setState(() {
      for (int i = 0; i < 4; i++) {
        _activeParticles.add(_Particle(
          key: UniqueKey(),
          emoji: emoji,
          startX: _random.nextDouble() * 80 - 40,
          driftX: _random.nextDouble() * 60 - 30,
          scale: 0.8 + _random.nextDouble() * 0.5,
        ));
      }
    });
  }
}

class _SingleParticleWidget extends StatefulWidget {
  final _Particle particle;
  final VoidCallback onComplete;

  const _SingleParticleWidget({
    super.key,
    required this.particle,
    required this.onComplete,
  });

  @override
  State<_SingleParticleWidget> createState() => _SingleParticleWidgetState();
}

class _SingleParticleWidgetState extends State<_SingleParticleWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _translateY;
  late Animation<double> _opacity;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1600 + Random().nextInt(500)),
    );

    _translateY = Tween<double>(begin: 0.0, end: -260.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _opacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.0), weight: 15),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.0), weight: 55),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(_controller);

    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.4, end: widget.particle.scale),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: widget.particle.scale, end: widget.particle.scale * 1.2),
        weight: 80,
      ),
    ]).animate(_controller);

    _controller.forward().then((_) => widget.onComplete());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          right: 48 + widget.particle.startX + (widget.particle.driftX * _controller.value),
          bottom: 110 - _translateY.value,
          child: Opacity(
            opacity: _opacity.value.clamp(0.0, 1.0),
            child: Transform.scale(
              scale: _scale.value,
              child: Text(
                widget.particle.emoji,
                style: const TextStyle(fontSize: 32),
              ),
            ),
          ),
        );
      },
    );
  }
}

