import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Renders one of 10 handcrafted cartoon character avatars using vector graphics.
///
/// Avatars:
/// 1. `avatar_popcorn` - Popcorn Cine-Kid with 3D glasses & cheerful smile
/// 2. `avatar_director` - The Film Director with classic beret & sunglasses
/// 3. `avatar_cyber` - Cyberpunk Hacker with glowing visor & earpiece
/// 4. `avatar_astronaut` - Cosmic Explorer inside bubble space helmet
/// 5. `avatar_hero` - Masked Superhero with comic cowl & hero smile
/// 6. `avatar_detective` - Film Noir Detective with fedora hat & trench collar
/// 7. `avatar_shinobi` - Anime Ninja with headband & fabric mask
/// 8. `avatar_retro` - Retro 80s Cinephile with round shades & headband
/// 9. `avatar_vip` - The Cinema King with golden crown & star shades
/// 10. `avatar_action` - Secret Agent with slick shades & tuxedo bowtie
class CartoonAvatarWidget extends StatelessWidget {
  final String avatarId;
  final double size;

  const CartoonAvatarWidget({
    super.key,
    required this.avatarId,
    this.size = 50.0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: CartoonAvatarPainter(avatarId: avatarId),
        size: Size(size, size),
      ),
    );
  }
}

class CartoonAvatarPainter extends CustomPainter {
  final String avatarId;

  CartoonAvatarPainter({required this.avatarId});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Clip to circle so all drawing stays nicely inside the avatar
    canvas.save();
    final circlePath = Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius));
    canvas.clipPath(circlePath);

    switch (avatarId) {
      case 'avatar_director':
        _paintDirector(canvas, size, center, radius);
        break;
      case 'avatar_cyber':
        _paintCyber(canvas, size, center, radius);
        break;
      case 'avatar_astronaut':
        _paintAstronaut(canvas, size, center, radius);
        break;
      case 'avatar_hero':
        _paintHero(canvas, size, center, radius);
        break;
      case 'avatar_detective':
        _paintDetective(canvas, size, center, radius);
        break;
      case 'avatar_shinobi':
        _paintShinobi(canvas, size, center, radius);
        break;
      case 'avatar_retro':
        _paintRetro(canvas, size, center, radius);
        break;
      case 'avatar_vip':
        _paintVip(canvas, size, center, radius);
        break;
      case 'avatar_action':
        _paintAction(canvas, size, center, radius);
        break;
      case 'avatar_popcorn':
      default:
        _paintPopcornKid(canvas, size, center, radius);
        break;
    }

    canvas.restore();
  }

  // ── 1. Popcorn Cine-Kid (Boy with 3D Glasses & Popcorn Cap) ──
  void _paintPopcornKid(Canvas canvas, Size size, Offset center, double radius) {
    final s = size.width / 100.0;

    // Background Gradient (Warm Amber / Gold)
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFF9500), Color(0xFFFFB800)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawCircle(center, radius, bgPaint);

    // Body / Hoodie
    final bodyPaint = Paint()..color = const Color(0xFFE65100);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(center.dx, 105 * s), width: 75 * s, height: 45 * s),
      bodyPaint,
    );

    // Head / Face (warm skin tone)
    final skinPaint = Paint()..color = const Color(0xFFFFD1A9);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(center.dx, 56 * s), width: 56 * s, height: 52 * s),
      skinPaint,
    );

    // Messy Hair (Brown)
    final hairPaint = Paint()..color = const Color(0xFF5D4037);
    final hairPath = Path()
      ..moveTo(22 * s, 48 * s)
      ..quadraticBezierTo(25 * s, 24 * s, 50 * s, 24 * s)
      ..quadraticBezierTo(75 * s, 24 * s, 78 * s, 48 * s)
      ..quadraticBezierTo(68 * s, 36 * s, 54 * s, 38 * s)
      ..quadraticBezierTo(40 * s, 34 * s, 22 * s, 48 * s);
    canvas.drawPath(hairPath, hairPaint);

    // Big 3D Glasses Frame (White)
    final framePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final frameStroke = Paint()
      ..color = const Color(0xFF263238)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5 * s;

    // Left Frame (Red Lens)
    final leftRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(36 * s, 52 * s), width: 24 * s, height: 20 * s),
      Radius.circular(5 * s),
    );
    canvas.drawRRect(leftRect, framePaint);
    canvas.drawRRect(leftRect, frameStroke);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(36 * s, 52 * s), width: 18 * s, height: 14 * s),
        Radius.circular(3 * s),
      ),
      Paint()..color = const Color(0xFFFF1744),
    );

    // Right Frame (Cyan Lens)
    final rightRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(64 * s, 52 * s), width: 24 * s, height: 20 * s),
      Radius.circular(5 * s),
    );
    canvas.drawRRect(rightRect, framePaint);
    canvas.drawRRect(rightRect, frameStroke);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(64 * s, 52 * s), width: 18 * s, height: 14 * s),
        Radius.circular(3 * s),
      ),
      Paint()..color = const Color(0xFF00E5FF),
    );

    // Bridge between glasses
    canvas.drawRect(
      Rect.fromLTWH(46 * s, 50 * s, 8 * s, 4 * s),
      framePaint,
    );
    canvas.drawLine(Offset(46 * s, 50 * s), Offset(54 * s, 50 * s), frameStroke);

    // Glint on Lenses
    final glintPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8 * s
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(31 * s, 48 * s), Offset(35 * s, 48 * s), glintPaint);
    canvas.drawLine(Offset(59 * s, 48 * s), Offset(63 * s, 48 * s), glintPaint);

    // Cheerful Smile
    final smilePaint = Paint()
      ..color = const Color(0xFF8D4004)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8 * s
      ..strokeCap = StrokeCap.round;
    final smilePath = Path()
      ..moveTo(40 * s, 70 * s)
      ..quadraticBezierTo(50 * s, 78 * s, 60 * s, 70 * s);
    canvas.drawPath(smilePath, smilePaint);

    // Cheeks (blush)
    final blushPaint = Paint()..color = const Color(0xFFFF8A80).withValues(alpha: 0.5);
    canvas.drawCircle(Offset(28 * s, 64 * s), 4.5 * s, blushPaint);
    canvas.drawCircle(Offset(72 * s, 64 * s), 4.5 * s, blushPaint);
  }

  // ── 2. The Film Director (Beret Hat & Sunglasses) ──
  void _paintDirector(Canvas canvas, Size size, Offset center, double radius) {
    final s = size.width / 100.0;

    final bgPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF2C3E50), Color(0xFF1A252F)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawCircle(center, radius, bgPaint);

    // Dark Turtleneck
    canvas.drawOval(
      Rect.fromCenter(center: Offset(center.dx, 105 * s), width: 80 * s, height: 46 * s),
      Paint()..color = const Color(0xFF1E1E24),
    );

    // Face
    canvas.drawOval(
      Rect.fromCenter(center: Offset(center.dx, 58 * s), width: 54 * s, height: 50 * s),
      Paint()..color = const Color(0xFFFFD6B0),
    );

    // Director Beret Hat (Tilted Charcoal)
    final beretPaint = Paint()..color = const Color(0xFF1E272C);
    final beretPath = Path()
      ..moveTo(16 * s, 42 * s)
      ..quadraticBezierTo(20 * s, 16 * s, 60 * s, 20 * s)
      ..quadraticBezierTo(88 * s, 26 * s, 82 * s, 46 * s)
      ..quadraticBezierTo(50 * s, 36 * s, 16 * s, 42 * s);
    canvas.drawPath(beretPath, beretPaint);
    // Beret tip
    canvas.drawCircle(Offset(58 * s, 18 * s), 3 * s, beretPaint);

    // Dark Sunglasses
    final shadesPaint = Paint()..color = const Color(0xFF111111);
    final shadesFrame = Paint()
      ..color = const Color(0xFFFF9500)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * s;

    final leftShade = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(36 * s, 54 * s), width: 22 * s, height: 16 * s),
      Radius.circular(5 * s),
    );
    final rightShade = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(64 * s, 54 * s), width: 22 * s, height: 16 * s),
      Radius.circular(5 * s),
    );
    canvas.drawRRect(leftShade, shadesPaint);
    canvas.drawRRect(leftShade, shadesFrame);
    canvas.drawRRect(rightShade, shadesPaint);
    canvas.drawRRect(rightShade, shadesFrame);
    canvas.drawLine(Offset(45 * s, 52 * s), Offset(55 * s, 52 * s), shadesFrame);

    // White glare on shades
    final glarePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..strokeWidth = 1.6 * s
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(30 * s, 49 * s), Offset(35 * s, 49 * s), glarePaint);
    canvas.drawLine(Offset(58 * s, 49 * s), Offset(63 * s, 49 * s), glarePaint);

    // Director Stylish Goatee Mustache
    final mustachePaint = Paint()
      ..color = const Color(0xFF2B3A42)
      ..style = PaintingStyle.fill;
    final mustachePath = Path()
      ..moveTo(40 * s, 68 * s)
      ..quadraticBezierTo(50 * s, 66 * s, 60 * s, 68 * s)
      ..quadraticBezierTo(50 * s, 73 * s, 40 * s, 68 * s);
    canvas.drawPath(mustachePath, mustachePaint);
    // Goatee chin dot
    canvas.drawOval(
      Rect.fromCenter(center: Offset(50 * s, 76 * s), width: 7 * s, height: 5 * s),
      mustachePaint,
    );
  }

  // ── 3. Cyberpunk Hacker (Neon Visor & Earpiece) ──
  void _paintCyber(Canvas canvas, Size size, Offset center, double radius) {
    final s = size.width / 100.0;

    final bgPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawCircle(center, radius, bgPaint);

    // Cyber Jacket
    canvas.drawOval(
      Rect.fromCenter(center: Offset(center.dx, 105 * s), width: 76 * s, height: 44 * s),
      Paint()..color = const Color(0xFF1A1C29),
    );

    // Face
    canvas.drawOval(
      Rect.fromCenter(center: Offset(center.dx, 56 * s), width: 52 * s, height: 50 * s),
      Paint()..color = const Color(0xFFFFE0BD),
    );

    // Spiky Cyber Hair (Dark Violet)
    final hairPaint = Paint()..color = const Color(0xFF4A148C);
    final hairPath = Path()
      ..moveTo(22 * s, 46 * s)
      ..lineTo(18 * s, 28 * s)
      ..lineTo(32 * s, 32 * s)
      ..lineTo(36 * s, 16 * s)
      ..lineTo(52 * s, 26 * s)
      ..lineTo(64 * s, 18 * s)
      ..lineTo(70 * s, 32 * s)
      ..lineTo(82 * s, 28 * s)
      ..lineTo(78 * s, 48 * s)
      ..quadraticBezierTo(50 * s, 36 * s, 22 * s, 46 * s);
    canvas.drawPath(hairPath, hairPaint);

    // Neon Cyber Visor (Cyan Glowing Bar)
    final visorRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(center.dx, 52 * s), width: 62 * s, height: 18 * s),
      Radius.circular(6 * s),
    );
    // Outer Glow
    canvas.drawRRect(
      visorRect,
      Paint()
        ..color = const Color(0xFF00F2FE).withValues(alpha: 0.5)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 5 * s),
    );
    // Visor Body
    canvas.drawRRect(
      visorRect,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF00F2FE), Color(0xFF4FACFE)],
        ).createShader(visorRect.outerRect),
    );
    // Digital Scanline on Visor
    canvas.drawLine(
      Offset(24 * s, 52 * s),
      Offset(76 * s, 52 * s),
      Paint()
        ..color = Colors.white
        ..strokeWidth = 2 * s,
    );

    // Earpiece Mic on Cheek
    final micPaint = Paint()..color = const Color(0xFF00F2FE);
    canvas.drawCircle(Offset(22 * s, 60 * s), 4 * s, micPaint);
    canvas.drawLine(
      Offset(22 * s, 60 * s),
      Offset(36 * s, 68 * s),
      Paint()
        ..color = const Color(0xFF00F2FE)
        ..strokeWidth = 2 * s,
    );

    // Smirk
    final smirkPaint = Paint()
      ..color = const Color(0xFF37474F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5 * s
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(45 * s, 72 * s), Offset(58 * s, 69 * s), smirkPaint);
  }

  // ── 4. Cosmic Astronaut (Bubble Space Helmet) ──
  void _paintAstronaut(Canvas canvas, Size size, Offset center, double radius) {
    final s = size.width / 100.0;

    final bgPaint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFF3A1C71), Color(0xFF1B1B3A)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawCircle(center, radius, bgPaint);

    // Little background stars
    final starPaint = Paint()..color = Colors.white.withValues(alpha: 0.6);
    canvas.drawCircle(Offset(20 * s, 25 * s), 1.5 * s, starPaint);
    canvas.drawCircle(Offset(80 * s, 20 * s), 1.8 * s, starPaint);
    canvas.drawCircle(Offset(85 * s, 70 * s), 1.2 * s, starPaint);

    // Spacesuit Shoulders (White)
    canvas.drawOval(
      Rect.fromCenter(center: Offset(center.dx, 105 * s), width: 84 * s, height: 46 * s),
      Paint()..color = const Color(0xFFECEFF1),
    );
    // Chest badge
    canvas.drawCircle(Offset(center.dx, 92 * s), 4 * s, Paint()..color = const Color(0xFF00E5FF));

    // Outer Bubble Helmet (White)
    canvas.drawCircle(
      Offset(center.dx, 50 * s),
      34 * s,
      Paint()..color = const Color(0xFFCFD8DC),
    );

    // Helmet Visor Glass (Deep Reflective Navy/Cyan)
    final visorRect = Rect.fromCircle(center: Offset(center.dx, 50 * s), radius: 28 * s);
    canvas.drawOval(
      visorRect,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF0F2027), Color(0xFF2C5364), Color(0xFF00E5FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(visorRect),
    );

    // Big Crescent Glint Reflection on Helmet Visor
    final glintPath = Path()
      ..addArc(
        Rect.fromCircle(center: Offset(center.dx, 50 * s), radius: 23 * s),
        math.pi * 1.1,
        math.pi * 0.45,
      );
    canvas.drawPath(
      glintPath,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5 * s
        ..strokeCap = StrokeCap.round,
    );

    // Friendly Face Smiling inside Visor
    final eyePaint = Paint()..color = const Color(0xFF80D8FF);
    canvas.drawCircle(Offset(43 * s, 50 * s), 3.5 * s, eyePaint);
    canvas.drawCircle(Offset(57 * s, 50 * s), 3.5 * s, eyePaint);
    final innerSmile = Path()
      ..moveTo(45 * s, 58 * s)
      ..quadraticBezierTo(50 * s, 62 * s, 55 * s, 58 * s);
    canvas.drawPath(
      innerSmile,
      Paint()
        ..color = const Color(0xFF80D8FF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2 * s
        ..strokeCap = StrokeCap.round,
    );
  }

  // ── 5. Masked Superhero (Crimson Domino Mask & Cowl) ──
  void _paintHero(Canvas canvas, Size size, Offset center, double radius) {
    final s = size.width / 100.0;

    final bgPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFF416C), Color(0xFFFF4B2B)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawCircle(center, radius, bgPaint);

    // Superhero Suit & Golden Emblem
    canvas.drawOval(
      Rect.fromCenter(center: Offset(center.dx, 105 * s), width: 78 * s, height: 44 * s),
      Paint()..color = const Color(0xFFB71C1C),
    );
    canvas.drawCircle(Offset(center.dx, 90 * s), 5 * s, Paint()..color = const Color(0xFFFFD700));

    // Hero Face
    canvas.drawOval(
      Rect.fromCenter(center: Offset(center.dx, 58 * s), width: 54 * s, height: 50 * s),
      Paint()..color = const Color(0xFFFFD6B0),
    );

    // Slick Black Hero Hair with signature curl
    final hairPaint = Paint()..color = const Color(0xFF1A1A1A);
    final hairPath = Path()
      ..moveTo(22 * s, 46 * s)
      ..quadraticBezierTo(24 * s, 22 * s, 50 * s, 20 * s)
      ..quadraticBezierTo(76 * s, 22 * s, 78 * s, 46 * s)
      ..quadraticBezierTo(68 * s, 34 * s, 56 * s, 36 * s)
      ..quadraticBezierTo(52 * s, 44 * s, 48 * s, 36 * s) // superhero curl
      ..quadraticBezierTo(36 * s, 34 * s, 22 * s, 46 * s);
    canvas.drawPath(hairPath, hairPaint);

    // Superhero Domino Mask (Midnight Navy / Black)
    final maskPaint = Paint()..color = const Color(0xFF1E272C);
    final maskPath = Path()
      ..moveTo(24 * s, 54 * s)
      ..quadraticBezierTo(36 * s, 42 * s, 50 * s, 50 * s)
      ..quadraticBezierTo(64 * s, 42 * s, 76 * s, 54 * s)
      ..quadraticBezierTo(66 * s, 64 * s, 50 * s, 56 * s)
      ..quadraticBezierTo(34 * s, 64 * s, 24 * s, 54 * s);
    canvas.drawPath(maskPath, maskPaint);

    // Expressive White Hero Eyes
    final eyePaint = Paint()..color = Colors.white;
    final leftEye = Path()
      ..moveTo(31 * s, 53 * s)
      ..quadraticBezierTo(37 * s, 48 * s, 43 * s, 53 * s)
      ..quadraticBezierTo(37 * s, 57 * s, 31 * s, 53 * s);
    final rightEye = Path()
      ..moveTo(57 * s, 53 * s)
      ..quadraticBezierTo(63 * s, 48 * s, 69 * s, 53 * s)
      ..quadraticBezierTo(63 * s, 57 * s, 57 * s, 53 * s);
    canvas.drawPath(leftEye, eyePaint);
    canvas.drawPath(rightEye, eyePaint);

    // Confident Hero Grin
    final grinPaint = Paint()
      ..color = const Color(0xFF8D4004)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8 * s
      ..strokeCap = StrokeCap.round;
    final grinPath = Path()
      ..moveTo(40 * s, 72 * s)
      ..quadraticBezierTo(50 * s, 80 * s, 60 * s, 72 * s);
    canvas.drawPath(grinPath, grinPaint);
  }

  // ── 6. Film Noir Detective (Fedora & Trench Collar) ──
  void _paintDetective(Canvas canvas, Size size, Offset center, double radius) {
    final s = size.width / 100.0;

    final bgPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFF7971E), Color(0xFFFFD200)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawCircle(center, radius, bgPaint);

    // Trench Coat (Dark Brown) with collar turned up
    final coatPaint = Paint()..color = const Color(0xFF4E342E);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(center.dx, 105 * s), width: 80 * s, height: 46 * s),
      coatPaint,
    );

    // Face
    canvas.drawOval(
      Rect.fromCenter(center: Offset(center.dx, 60 * s), width: 50 * s, height: 48 * s),
      Paint()..color = const Color(0xFFFFD1A9),
    );

    // Classic Noir Fedora Hat (Brown)
    final hatPaint = Paint()..color = const Color(0xFF3E2723);
    final hatBrim = Path()
      ..moveTo(12 * s, 46 * s)
      ..quadraticBezierTo(50 * s, 34 * s, 88 * s, 46 * s)
      ..quadraticBezierTo(50 * s, 40 * s, 12 * s, 46 * s);
    canvas.drawPath(hatBrim, hatPaint);

    // Fedora Crown
    final hatCrown = Path()
      ..moveTo(28 * s, 40 * s)
      ..lineTo(32 * s, 20 * s)
      ..quadraticBezierTo(50 * s, 26 * s, 68 * s, 20 * s)
      ..lineTo(72 * s, 40 * s)
      ..close();
    canvas.drawPath(hatCrown, hatPaint);
    // Hat Ribbon Band (Amber)
    canvas.drawRect(
      Rect.fromLTWH(30 * s, 34 * s, 40 * s, 6 * s),
      Paint()..color = const Color(0xFFFF9500),
    );

    // Mystery Sunglasses / Shades
    final shadesPaint = Paint()..color = const Color(0xFF1A1A1A);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(37 * s, 54 * s), width: 18 * s, height: 13 * s),
      shadesPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(63 * s, 54 * s), width: 18 * s, height: 13 * s),
      shadesPaint,
    );
    canvas.drawLine(
      Offset(46 * s, 53 * s),
      Offset(54 * s, 53 * s),
      Paint()
        ..color = const Color(0xFF1A1A1A)
        ..strokeWidth = 2 * s,
    );

    // Detective smirk & 5 o'clock shadow
    final smirk = Path()
      ..moveTo(44 * s, 72 * s)
      ..quadraticBezierTo(52 * s, 74 * s, 58 * s, 70 * s);
    canvas.drawPath(
      smirk,
      Paint()
        ..color = const Color(0xFF4E342E)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4 * s
        ..strokeCap = StrokeCap.round,
    );
  }

  // ── 7. Anime Ninja (Headband & Mask) ──
  void _paintShinobi(Canvas canvas, Size size, Offset center, double radius) {
    final s = size.width / 100.0;

    final bgPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF11998E), Color(0xFF38EF7D)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawCircle(center, radius, bgPaint);

    // Ninja Vest
    canvas.drawOval(
      Rect.fromCenter(center: Offset(center.dx, 105 * s), width: 78 * s, height: 44 * s),
      Paint()..color = const Color(0xFF212121),
    );

    // Face
    canvas.drawOval(
      Rect.fromCenter(center: Offset(center.dx, 56 * s), width: 52 * s, height: 50 * s),
      Paint()..color = const Color(0xFFFFE0BD),
    );

    // Spiky Anime Hair (Black)
    final hairPaint = Paint()..color = const Color(0xFF1E272C);
    final hairPath = Path()
      ..moveTo(20 * s, 48 * s)
      ..lineTo(14 * s, 26 * s)
      ..lineTo(28 * s, 24 * s)
      ..lineTo(36 * s, 10 * s)
      ..lineTo(48 * s, 20 * s)
      ..lineTo(62 * s, 12 * s)
      ..lineTo(70 * s, 22 * s)
      ..lineTo(86 * s, 26 * s)
      ..lineTo(80 * s, 48 * s)
      ..close();
    canvas.drawPath(hairPath, hairPaint);

    // Headband (Blue/Navy)
    canvas.drawRect(
      Rect.fromLTWH(24 * s, 34 * s, 52 * s, 11 * s),
      Paint()..color = const Color(0xFF0D47A1),
    );
    // Silver Metal Plate on Headband
    final plateRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(center.dx, 39.5 * s), width: 28 * s, height: 8 * s),
      Radius.circular(2 * s),
    );
    canvas.drawRRect(plateRect, Paint()..color = const Color(0xFFCFD8DC));
    canvas.drawCircle(Offset(center.dx, 39.5 * s), 2.2 * s, Paint()..color = const Color(0xFF37474F));

    // Fierce Anime Eyes
    final eyePaint = Paint()..color = const Color(0xFF212121);
    canvas.drawLine(
      Offset(33 * s, 48 * s),
      Offset(43 * s, 51 * s),
      Paint()
        ..color = const Color(0xFF212121)
        ..strokeWidth = 2.5 * s
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(Offset(38 * s, 53 * s), 3 * s, eyePaint);
    canvas.drawLine(
      Offset(67 * s, 48 * s),
      Offset(57 * s, 51 * s),
      Paint()
        ..color = const Color(0xFF212121)
        ..strokeWidth = 2.5 * s
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(Offset(62 * s, 53 * s), 3 * s, eyePaint);

    // Fabric Ninja Mask covering mouth & nose (Dark Slate)
    final maskPath = Path()
      ..moveTo(24 * s, 58 * s)
      ..quadraticBezierTo(50 * s, 54 * s, 76 * s, 58 * s)
      ..lineTo(70 * s, 82 * s)
      ..quadraticBezierTo(50 * s, 86 * s, 30 * s, 82 * s)
      ..close();
    canvas.drawPath(maskPath, Paint()..color = const Color(0xFF263238));
  }

  // ── 8. Retro 80s Cinephile (Big Round Shades & Bob Hair) ──
  void _paintRetro(Canvas canvas, Size size, Offset center, double radius) {
    final s = size.width / 100.0;

    final bgPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawCircle(center, radius, bgPaint);

    // Retro Jacket
    canvas.drawOval(
      Rect.fromCenter(center: Offset(center.dx, 105 * s), width: 76 * s, height: 44 * s),
      Paint()..color = const Color(0xFFFF007F),
    );

    // Cute Bob Haircut (Caramel Brown)
    canvas.drawCircle(
      Offset(center.dx, 52 * s),
      32 * s,
      Paint()..color = const Color(0xFF5D4037),
    );

    // Face
    canvas.drawOval(
      Rect.fromCenter(center: Offset(center.dx, 58 * s), width: 48 * s, height: 46 * s),
      Paint()..color = const Color(0xFFFFE0BD),
    );

    // Neon Headband (Cyan)
    canvas.drawArc(
      Rect.fromCircle(center: Offset(center.dx, 50 * s), radius: 28 * s),
      math.pi * 1.15,
      math.pi * 0.7,
      false,
      Paint()
        ..color = const Color(0xFF00F2FE)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6 * s
        ..strokeCap = StrokeCap.round,
    );

    // Big Oversized Round Sunglasses
    final leftShade = Rect.fromCircle(center: Offset(36 * s, 54 * s), radius: 12 * s);
    final rightShade = Rect.fromCircle(center: Offset(64 * s, 54 * s), radius: 12 * s);
    final shadesFrame = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5 * s;

    // Pink / Purple Gradient Lens
    final lensPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFF007F), Color(0xFF7928CA)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(leftShade);
    canvas.drawOval(leftShade, lensPaint);
    canvas.drawOval(leftShade, shadesFrame);
    canvas.drawOval(rightShade, lensPaint);
    canvas.drawOval(rightShade, shadesFrame);
    canvas.drawLine(Offset(48 * s, 54 * s), Offset(52 * s, 54 * s), shadesFrame);

    // Lens Glint
    canvas.drawLine(
      Offset(30 * s, 48 * s),
      Offset(36 * s, 48 * s),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.8)
        ..strokeWidth = 1.8 * s,
    );
    canvas.drawLine(
      Offset(58 * s, 48 * s),
      Offset(64 * s, 48 * s),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.8)
        ..strokeWidth = 1.8 * s,
    );

    // Cheerful Smile with pink lips
    final smile = Path()
      ..moveTo(42 * s, 72 * s)
      ..quadraticBezierTo(50 * s, 78 * s, 58 * s, 72 * s);
    canvas.drawPath(
      smile,
      Paint()
        ..color = const Color(0xFFFF007F)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.8 * s
        ..strokeCap = StrokeCap.round,
    );
  }

  // ── 9. Cinema King (Golden Crown & Royal Shades) ──
  void _paintVip(Canvas canvas, Size size, Offset center, double radius) {
    final s = size.width / 100.0;

    final bgPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF3F2B96), Color(0xFFA8C0FF)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawCircle(center, radius, bgPaint);

    // Royal Robe (Purple & Gold Collar)
    canvas.drawOval(
      Rect.fromCenter(center: Offset(center.dx, 105 * s), width: 80 * s, height: 46 * s),
      Paint()..color = const Color(0xFF4A148C),
    );
    canvas.drawCircle(Offset(center.dx, 90 * s), 4 * s, Paint()..color = const Color(0xFFFFD700));

    // Face
    canvas.drawOval(
      Rect.fromCenter(center: Offset(center.dx, 60 * s), width: 52 * s, height: 48 * s),
      Paint()..color = const Color(0xFFFFD6B0),
    );

    // Shiny Golden 3-Point Crown
    final crownPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(26 * s, 18 * s, 48 * s, 26 * s));
    final crownPath = Path()
      ..moveTo(26 * s, 38 * s)
      ..lineTo(22 * s, 22 * s) // left point
      ..lineTo(38 * s, 30 * s)
      ..lineTo(50 * s, 16 * s) // tall center point
      ..lineTo(62 * s, 30 * s)
      ..lineTo(78 * s, 22 * s) // right point
      ..lineTo(74 * s, 38 * s)
      ..close();
    canvas.drawPath(crownPath, crownPaint);

    // Crown Jewels (Rubies)
    canvas.drawCircle(Offset(22 * s, 22 * s), 2.2 * s, Paint()..color = const Color(0xFFFF1744));
    canvas.drawCircle(Offset(50 * s, 16 * s), 3.0 * s, Paint()..color = const Color(0xFFFF1744));
    canvas.drawCircle(Offset(78 * s, 22 * s), 2.2 * s, Paint()..color = const Color(0xFFFF1744));

    // Star / Celebrity Shades (Black with Gold border)
    final shadesPaint = Paint()..color = const Color(0xFF1E1E24);
    final goldBorder = Paint()
      ..color = const Color(0xFFFFD700)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * s;

    final leftShade = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(36 * s, 54 * s), width: 22 * s, height: 16 * s),
      Radius.circular(4 * s),
    );
    final rightShade = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(64 * s, 54 * s), width: 22 * s, height: 16 * s),
      Radius.circular(4 * s),
    );
    canvas.drawRRect(leftShade, shadesPaint);
    canvas.drawRRect(leftShade, goldBorder);
    canvas.drawRRect(rightShade, shadesPaint);
    canvas.drawRRect(rightShade, goldBorder);
    canvas.drawLine(Offset(47 * s, 52 * s), Offset(53 * s, 52 * s), goldBorder);

    // Star glint on left lens
    final starGlint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(33 * s, 50 * s), 2 * s, starGlint);

    // Charming Royal Smirk
    final smile = Path()
      ..moveTo(42 * s, 72 * s)
      ..quadraticBezierTo(50 * s, 78 * s, 58 * s, 72 * s);
    canvas.drawPath(
      smile,
      Paint()
        ..color = const Color(0xFF8D4004)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.8 * s
        ..strokeCap = StrokeCap.round,
    );
  }

  // ── 10. Secret Agent 007 (Slick Shades & Tuxedo Bowtie) ──
  void _paintAction(Canvas canvas, Size size, Offset center, double radius) {
    final s = size.width / 100.0;

    final bgPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF232526), Color(0xFF414345)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawCircle(center, radius, bgPaint);

    // Black Tuxedo Jacket
    canvas.drawOval(
      Rect.fromCenter(center: Offset(center.dx, 105 * s), width: 82 * s, height: 46 * s),
      Paint()..color = const Color(0xFF141419),
    );
    // White Shirt V-Collar
    final shirtPath = Path()
      ..moveTo(40 * s, 85 * s)
      ..lineTo(50 * s, 100 * s)
      ..lineTo(60 * s, 85 * s)
      ..close();
    canvas.drawPath(shirtPath, Paint()..color = Colors.white);

    // Black Bowtie
    final bowPath = Path()
      ..moveTo(44 * s, 84 * s)
      ..lineTo(56 * s, 88 * s)
      ..lineTo(56 * s, 84 * s)
      ..lineTo(44 * s, 88 * s)
      ..close();
    canvas.drawPath(bowPath, Paint()..color = const Color(0xFF111111));
    canvas.drawCircle(Offset(50 * s, 86 * s), 2 * s, Paint()..color = const Color(0xFFFF9500));

    // Agent Face
    canvas.drawOval(
      Rect.fromCenter(center: Offset(center.dx, 54 * s), width: 52 * s, height: 48 * s),
      Paint()..color = const Color(0xFFFFD6B0),
    );

    // Slick Side-Parted Black Hair
    final hairPaint = Paint()..color = const Color(0xFF111111);
    final hairPath = Path()
      ..moveTo(22 * s, 46 * s)
      ..quadraticBezierTo(26 * s, 22 * s, 50 * s, 20 * s)
      ..quadraticBezierTo(74 * s, 20 * s, 78 * s, 46 * s)
      ..quadraticBezierTo(60 * s, 32 * s, 40 * s, 34 * s)
      ..quadraticBezierTo(30 * s, 36 * s, 22 * s, 46 * s);
    canvas.drawPath(hairPath, hairPaint);

    // Dark Sunglasses with Silver Frame
    final shadesPaint = Paint()..color = const Color(0xFF1A1A1A);
    final framePaint = Paint()
      ..color = const Color(0xFFB0BEC5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8 * s;

    final leftShade = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(36 * s, 50 * s), width: 22 * s, height: 15 * s),
      Radius.circular(4 * s),
    );
    final rightShade = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(64 * s, 50 * s), width: 22 * s, height: 15 * s),
      Radius.circular(4 * s),
    );
    canvas.drawRRect(leftShade, shadesPaint);
    canvas.drawRRect(leftShade, framePaint);
    canvas.drawRRect(rightShade, shadesPaint);
    canvas.drawRRect(rightShade, framePaint);
    canvas.drawLine(Offset(47 * s, 48 * s), Offset(53 * s, 48 * s), framePaint);

    // Glare on Shades
    canvas.drawLine(
      Offset(30 * s, 46 * s),
      Offset(35 * s, 46 * s),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.7)
        ..strokeWidth = 1.5 * s,
    );
    canvas.drawLine(
      Offset(58 * s, 46 * s),
      Offset(63 * s, 46 * s),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.7)
        ..strokeWidth = 1.5 * s,
    );

    // Dapper Agent Smirk
    final smirk = Path()
      ..moveTo(43 * s, 68 * s)
      ..quadraticBezierTo(52 * s, 71 * s, 59 * s, 67 * s);
    canvas.drawPath(
      smirk,
      Paint()
        ..color = const Color(0xFF8D4004)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6 * s
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CartoonAvatarPainter oldDelegate) {
    return oldDelegate.avatarId != avatarId;
  }
}
