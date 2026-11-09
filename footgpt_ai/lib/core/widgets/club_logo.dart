import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// Provider crest only. Missing logos use a generic mark, never another club.
class ClubLogo extends StatelessWidget {
  const ClubLogo({super.key, required this.name, this.url, this.size = 48});

  final String name;
  final String? url;
  final double size;

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.accentMuted,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(Icons.shield_outlined, color: AppColors.accent, size: size * 0.45),
    );
    if (url == null || url!.isEmpty) return fallback;
    final dpr = MediaQuery.maybeOf(context)?.devicePixelRatio ?? 2;
    final cacheSize = (size * dpr).round();
    return CachedNetworkImage(
      imageUrl: url!,
      width: size,
      height: size,
      memCacheWidth: cacheSize,
      memCacheHeight: cacheSize,
      fit: BoxFit.contain,
      placeholder: (_, _) => fallback,
      errorWidget: (_, _, _) => fallback,
    );
  }
}
