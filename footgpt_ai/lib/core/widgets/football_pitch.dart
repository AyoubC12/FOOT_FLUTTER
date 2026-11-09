import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../tactics/pitch_player.dart';
import 'pitch_token.dart';

class FootballPitch extends StatelessWidget {
  const FootballPitch({
    super.key,
    required this.players,
    this.selectedId,
    this.onPlayerTap,
    this.onPlayerMoved,
    this.interactive = false,
    this.height = 420,
    this.compactTokens = false,
  });

  final List<PitchPlayer> players;
  final String? selectedId;
  final ValueChanged<PitchPlayer>? onPlayerTap;
  final void Function(String id, double x, double y)? onPlayerMoved;
  final bool interactive;
  final double height;
  final bool compactTokens;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                const Positioned.fill(child: CustomPaint(painter: PitchPainter())),
                for (final player in players)
                  _DraggableMarker(
                    player: player,
                    selected: selectedId == player.id,
                    compact: compactTokens,
                    width: constraints.maxWidth,
                    height: constraints.maxHeight,
                    interactive: interactive,
                    onTap: () => onPlayerTap?.call(player),
                    onMoved: onPlayerMoved,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DraggableMarker extends StatelessWidget {
  const _DraggableMarker({
    required this.player,
    required this.selected,
    required this.compact,
    required this.width,
    required this.height,
    required this.interactive,
    required this.onTap,
    required this.onMoved,
  });

  final PitchPlayer player;
  final bool selected;
  final bool compact;
  final double width;
  final double height;
  final bool interactive;
  final VoidCallback onTap;
  final void Function(String id, double x, double y)? onMoved;

  @override
  Widget build(BuildContext context) {
    const tokenWidth = 88.0;
    final left = (player.x * width) - tokenWidth / 2;
    final top = (player.y * height) - 24;
    return Positioned(
      left: left.clamp(-20, width - 40),
      top: top.clamp(-8, height - 40),
      child: GestureDetector(
        onTap: onTap,
        onPanUpdate: interactive
            ? (details) {
                final nextX = ((player.x * width) + details.delta.dx) / width;
                final nextY = ((player.y * height) + details.delta.dy) / height;
                onMoved?.call(
                  player.id,
                  nextX.clamp(0.06, 0.94),
                  nextY.clamp(0.08, 0.94),
                );
              }
            : null,
        child: SizedBox(
          width: tokenWidth,
          child: PitchToken(
            player: player,
            selected: selected,
            compact: compact,
          ),
        ),
      ),
    );
  }
}

class PitchPainter extends CustomPainter {
  const PitchPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final field = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(24),
    );
    canvas.drawRRect(field, Paint()..color = const Color(0xFF0C3B28));

    final stripe = Paint()..color = const Color(0xFF0E4630);
    for (var i = 0; i < 8; i++) {
      if (i.isOdd) {
        canvas.drawRect(
          Rect.fromLTWH(0, size.height / 8 * i, size.width, size.height / 8),
          stripe,
        );
      }
    }

    final line = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;

    canvas.drawRRect(field.deflate(10), line);
    canvas.drawLine(
      Offset(10, size.height / 2),
      Offset(size.width - 10, size.height / 2),
      line,
    );
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), 36, line);

    void box(double top) {
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(size.width / 2, top),
          width: size.width * 0.56,
          height: size.height * 0.16,
        ),
        line,
      );
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(size.width / 2, top),
          width: size.width * 0.28,
          height: size.height * 0.08,
        ),
        line,
      );
    }

    box(size.height * 0.12);
    box(size.height * 0.88);

    final accent = Paint()
      ..color = AppColors.accent.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRRect(field.deflate(4), accent);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
