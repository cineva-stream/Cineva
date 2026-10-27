import 'package:flutter/material.dart';

/// Preset avatar item definition.
class AvatarPreset {
  final String id;
  final String name;
  final IconData icon;
  final LinearGradient gradient;
  final Color glowColor;

  const AvatarPreset({
    required this.id,
    required this.name,
    required this.icon,
    required this.gradient,
    required this.glowColor,
  });
}

/// Catalog of 10 exclusive cinematic avatar presets for Cineva.
class AvatarCatalog {
  AvatarCatalog._();

  static const List<AvatarPreset> presets = [
    AvatarPreset(
      id: 'avatar_popcorn',
      name: 'Popcorn Sinema',
      icon: Icons.movie_filter_rounded,
      gradient: LinearGradient(
        colors: [Color(0xFFFF9500), Color(0xFFFFB800)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      glowColor: Color(0xFFFF9500),
    ),
    AvatarPreset(
      id: 'avatar_director',
      name: 'Sutradara',
      icon: Icons.movie_creation_rounded,
      gradient: LinearGradient(
        colors: [Color(0xFF232526), Color(0xFF414345)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      glowColor: Color(0xFF414345),
    ),
    AvatarPreset(
      id: 'avatar_cyber',
      name: 'Cyberpunk Visor',
      icon: Icons.remove_red_eye_rounded,
      gradient: LinearGradient(
        colors: [Color(0xFF00F2FE), Color(0xFF4FACFE)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      glowColor: Color(0xFF00F2FE),
    ),
    AvatarPreset(
      id: 'avatar_astronaut',
      name: 'Cosmic Voyager',
      icon: Icons.rocket_launch_rounded,
      gradient: LinearGradient(
        colors: [Color(0xFF2E3192), Color(0xFF1BFFFF)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      glowColor: Color(0xFF1BFFFF),
    ),
    AvatarPreset(
      id: 'avatar_hero',
      name: 'Superhero Mask',
      icon: Icons.shield_rounded,
      gradient: LinearGradient(
        colors: [Color(0xFFFF416C), Color(0xFFFF4B2B)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      glowColor: Color(0xFFFF416C),
    ),
    AvatarPreset(
      id: 'avatar_detective',
      name: 'Film Noir Detective',
      icon: Icons.travel_explore_rounded,
      gradient: LinearGradient(
        colors: [Color(0xFFF7971E), Color(0xFFFFD200)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      glowColor: Color(0xFFF7971E),
    ),
    AvatarPreset(
      id: 'avatar_shinobi',
      name: 'Anime Shinobi',
      icon: Icons.bolt_rounded,
      gradient: LinearGradient(
        colors: [Color(0xFF11998E), Color(0xFF38EF7D)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      glowColor: Color(0xFF38EF7D),
    ),
    AvatarPreset(
      id: 'avatar_vip',
      name: 'Imperial VIP',
      icon: Icons.workspace_premium_rounded,
      gradient: LinearGradient(
        colors: [Color(0xFFD4AF37), Color(0xFFFFE082)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      glowColor: Color(0xFFD4AF37),
    ),
    AvatarPreset(
      id: 'avatar_retro',
      name: 'Proyektor Retro',
      icon: Icons.videocam_rounded,
      gradient: LinearGradient(
        colors: [Color(0xFFFA709A), Color(0xFFFEE140)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      glowColor: Color(0xFFFA709A),
    ),
    AvatarPreset(
      id: 'avatar_streamer',
      name: 'Stream Master',
      icon: Icons.headset_mic_rounded,
      gradient: LinearGradient(
        colors: [Color(0xFF8A2387), Color(0xFFE94057)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      glowColor: Color(0xFFE94057),
    ),
  ];

  static AvatarPreset getById(String id) {
    return presets.firstWhere(
      (preset) => preset.id == id,
      orElse: () => presets.first,
    );
  }
}
