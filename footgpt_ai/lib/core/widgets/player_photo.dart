import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

class PlayerPhoto extends StatelessWidget {
  const PlayerPhoto({
    super.key,
    required this.name,
    this.url,
    this.size = 72,
  });

  final String name;
  final String? url;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initials = name
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map((part) => part[0])
        .take(2)
        .join()
        .toUpperCase();
    final fallback = CircleAvatar(
      radius: size / 2,
      backgroundColor: AppColors.accentMuted,
      child: Text(
        initials,
        style: TextStyle(
          color: AppColors.accent,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.28,
        ),
      ),
    );
    if (url == null || url!.isEmpty) return fallback;
    final dpr = MediaQuery.maybeOf(context)?.devicePixelRatio ?? 2;
    final cacheSize = (size * dpr).round();
    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: url!,
        width: size,
        height: size,
        memCacheWidth: cacheSize,
        memCacheHeight: cacheSize,
        fit: BoxFit.cover,
        placeholder: (_, _) => fallback,
        errorWidget: (_, _, _) => fallback,
      ),
    );
  }
}
