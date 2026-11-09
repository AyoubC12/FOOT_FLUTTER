import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/preview_banner.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  var _alerts = true;
  var _livePulse = true;
  var _haptics = false;

  @override
  Widget build(BuildContext context) {
    final gutter = context.gutter();
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(gutter, 8, gutter, 28),
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: PreviewBanner(label: 'Local UI toggles'),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Match alerts'),
                  subtitle: const Text(
                    'Preview only — no push registration yet.',
                    style: TextStyle(color: AppColors.muted),
                  ),
                  activeThumbColor: AppColors.background,
                  activeTrackColor: AppColors.accent,
                  value: _alerts,
                  onChanged: (value) => setState(() => _alerts = value),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Live score pulse'),
                  value: _livePulse,
                  activeThumbColor: AppColors.background,
                  activeTrackColor: AppColors.accent,
                  onChanged: (value) => setState(() => _livePulse = value),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Haptics'),
                  value: _haptics,
                  activeThumbColor: AppColors.background,
                  activeTrackColor: AppColors.accent,
                  onChanged: (value) => setState(() => _haptics = value),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Appearance'),
              subtitle: const Text(
                'Dark navy is the default FootGPT theme.',
                style: TextStyle(color: AppColors.muted),
              ),
              trailing: const Text(
                'Dark',
                style: TextStyle(color: AppColors.accent),
              ),
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('About'),
              subtitle: const Text(AppConstants.appName),
              trailing: const Icon(Icons.info_outline, color: AppColors.muted),
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            onTap: () => context.go(AppRoutes.login),
            child: const ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Sign out'),
              trailing: Icon(Icons.logout_rounded, color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
  }
}
