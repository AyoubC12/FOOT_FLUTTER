import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/preview/preview_catalog.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/brand_mark.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gutter = context.gutter();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            onPressed: () => context.push(AppRoutes.settings),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(gutter, 8, gutter, 28),
        children: [
          AppCard(
            accentBorder: true,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: AppColors.accentMuted,
                  child: Text(
                    PreviewCatalog.userName[0],
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        PreviewCatalog.userName,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Text(
                        'Football analyst',
                        style: TextStyle(color: AppColors.muted),
                      ),
                      Text(
                        AppConstants.apiBaseUrl.isEmpty
                            ? 'Guest · API not configured'
                            : 'Connected workspace',
                        style: const TextStyle(
                          color: AppColors.accent,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const BrandMark(size: 36),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _NavTile(
            icon: Icons.bookmark_rounded,
            title: 'Favorites',
            onTap: () => context.push(AppRoutes.favorites),
          ),
          _NavTile(
            icon: Icons.shield_outlined,
            title: 'Teams',
            onTap: () => context.push(AppRoutes.teams),
          ),
          _NavTile(
            icon: Icons.person_search_rounded,
            title: 'Players',
            onTap: () => context.push(AppRoutes.players),
          ),
          _NavTile(
            icon: Icons.insights_rounded,
            title: 'Predictions',
            onTap: () => context.push(AppRoutes.predictions),
          ),
          _NavTile(
            icon: Icons.people_alt_rounded,
            title: 'Player comparison',
            onTap: () => context.push(AppRoutes.playerCompare),
          ),
          _NavTile(
            icon: Icons.schema_rounded,
            title: 'Tactical analysis',
            onTap: () => context.push(AppRoutes.tactics),
          ),
          _NavTile(
            icon: Icons.notifications_rounded,
            title: 'Notifications',
            onTap: () => context.push(AppRoutes.notifications),
          ),
          _NavTile(
            icon: Icons.settings_rounded,
            title: 'Settings',
            onTap: () => context.push(AppRoutes.settings),
          ),
          _NavTile(
            icon: Icons.logout_rounded,
            title: 'Sign out',
            onTap: () => context.go(AppRoutes.login),
          ),
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        onTap: onTap,
        child: Row(
          children: [
            Container(
              height: 36,
              width: 36,
              decoration: BoxDecoration(
                color: AppColors.accentMuted,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.accent, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600))),
            const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}
