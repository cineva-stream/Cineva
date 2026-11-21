import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/watch_party_provider.dart';

/// Floating live stream style emoji reaction overlay.
///
/// Listens to [watchPartyEmojiReactionStreamProvider] and floats animated emoji
/// particles from the bottom right towards the top with natural curves, scale-pop,
/// slight rotation, and smooth fade-out.
///
/// Designed to be wrapped in [IgnorePointer] so it does not interfere with video player controls.
class WatchPartyFloatingReactions extends ConsumerStatefulWidget {
  const WatchPartyFloatingReactions({super.key});

  @override
  ConsumerState<WatchPartyFloatingReactions> createState() =>
      _WatchPartyFloatingReactionsState();
}

class _WatchPartyFloatingReactionsState
    extends ConsumerState<WatchPartyFloatingReactions>
    with TickerProviderStateMixin {
  final List<_ReactionParticle> _particles = [];
  final Random _random = Random();
  StreamSubscription<String>? _sub;

  @override
  void initState() {
    super.initState();
    // Subscribe to service emoji reaction stream
    final service = ref.read(watchPartyServiceProvider);
    _sub = service.emojiReactionStream.listen((emoji) {
      if (mounted) {
        _spawnParticle(emoji);
      }
    });
  }

  void _spawnParticle(String emoji) {
    if (!mounted) return;

    // Limit maximum concurrent active particles for 60fps performance
    if (_particles.length > 25) {
      final oldest = _particles.removeAt(0);
      oldest.controller.dispose();
    }

    final controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 2400 + _random.nextInt(600)),
    );

    final particle = _ReactionParticle(
      id: UniqueKey().toString(),
      emoji: emoji,
      controller: controller,
      horizontalJitter: (_random.nextDouble() - 0.5) * 44,
      wobbleFrequency: 2.0 + _random.nextDouble() * 2.0,
      wobbleAmplitude: 8.0 + _random.nextDouble() * 12.0,
      rotation: (_random.nextDouble() - 0.5) * 0.35,
      targetHeight: 240.0 + _random.nextDouble() * 100.0,
    );

    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (mounted) {
          setState(() {
            _particles.remove(particle);
          });
        }
        particle.controller.dispose();
      }
    });

    setState(() {
      _particles.add(particle);
    });

    controller.forward();
  }

  @override
  void dispose() {
    _sub?.cancel();
    for (final p in _particles) {
      p.controller.dispose();
    }
    _particles.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_particles.isEmpty) {
      return const SizedBox.shrink();
    }

    return Stack(
      fit: StackFit.expand,
      children: _particles.map((particle) {
        return _FloatingEmojiWidget(
          key: ValueKey(particle.id),
          particle: particle,
        );
      }).toList(),
    );
  }
}

class _ReactionParticle {
  final String id;
  final String emoji;
  final AnimationController controller;
  final double horizontalJitter;
  final double wobbleFrequency;
  final double wobbleAmplitude;
  final double rotation;
  final double targetHeight;

  _ReactionParticle({
    required this.id,
    required this.emoji,
    required this.controller,
    required this.horizontalJitter,
    required this.wobbleFrequency,
    required this.wobbleAmplitude,
    required this.rotation,
    required this.targetHeight,
  });
}

class _FloatingEmojiWidget extends StatelessWidget {
  final _ReactionParticle particle;

  const _FloatingEmojiWidget({
    super.key,
    required this.particle,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: particle.controller,
      builder: (context, child) {
        final progress = particle.controller.value;

        // 1. Vertical upward drift with easeOut curve
        final curvedProgress = Curves.easeOutCubic.transform(progress);
        final translateY = -curvedProgress * particle.targetHeight;

        // 2. Horizontal sinusoidal wobble
        final translateX = particle.horizontalJitter +
            sin(progress * pi * particle.wobbleFrequency) *
                particle.wobbleAmplitude;

        // 3. Pop-in scale animation (starts at 0.5, pops to 1.25, settles to 1.0)
        double scale = 1.0;
        if (progress < 0.15) {
          scale = 0.5 + (progress / 0.15) * 0.75;
        } else if (progress < 0.3) {
          scale = 1.25 - ((progress - 0.15) / 0.15) * 0.25;
        }

        // 4. Smooth fade out near the top
        double opacity = 1.0;
        if (progress > 0.65) {
          opacity = (1.0 - (progress - 0.65) / 0.35).clamp(0.0, 1.0);
        }

        return Positioned(
          bottom: 56,
          right: 36,
          child: Transform.translate(
            offset: Offset(translateX, translateY),
            child: Transform.rotate(
              angle: particle.rotation,
              child: Transform.scale(
                scale: scale,
                child: Opacity(
                  opacity: opacity,
                  child: Text(
                    particle.emoji,
                    style: const TextStyle(
                      fontSize: 34,
                      shadows: [
                        Shadow(
                          color: Colors.black54,
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
