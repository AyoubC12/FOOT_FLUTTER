import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../preview/preview_catalog.dart';
import '../preview/preview_models.dart';

/// Stylized player photo for UI previews. No network images or API assets.
class PlayerPortrait extends StatelessWidget {
  const PlayerPortrait({
    super.key,
    required this.player,
    this.height = 220,
  });

  final PreviewPlayer player;
  final double height;

  @override
  Widget build(BuildContext context) {
    final club = PreviewCatalog.teamById(player.clubId);

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    club.color.withValues(alpha: 0.85),
                    AppColors.background,
                    AppColors.accentMuted,
                  ],
                ),
              ),
            ),
            CustomPaint(painter: _SilhouettePainter()),
            Positioned(
              right: 16,
              top: 16,
              child: Text(
                '${player.number}',
                style: TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.w900,
                  color: AppColors.white.withValues(alpha: 0.12),
                ),
              ),
            ),
            Positioned(
              left: 16,
              bottom: 16,
              right: 16,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.accent,
                    child: Text(
                      player.initials,
                      style: const TextStyle(
                        color: AppColors.background,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          player.name,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          '${player.position} · ${club.name}',
                          style: const TextStyle(color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SilhouettePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.white.withValues(alpha: 0.1);
    final head = Offset(size.width * 0.52, size.height * 0.28);
    canvas.drawCircle(head, size.width * 0.11, paint);
    final torso = Path()
      ..moveTo(size.width * 0.36, size.height * 0.42)
      ..quadraticBezierTo(
        size.width * 0.52,
        size.height * 0.36,
        size.width * 0.68,
        size.height * 0.42,
      )
      ..lineTo(size.width * 0.78, size.height)
      ..lineTo(size.width * 0.26, size.height)
      ..close();
    canvas.drawPath(torso, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
