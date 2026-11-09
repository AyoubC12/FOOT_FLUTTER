import 'package:flutter/material.dart';

import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/feature_placeholder.dart';

/// Push UI stub. Device tokens register on the Django API; FCM is not
/// bundled in Flutter until Firebase options exist for this project.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: Padding(
        padding: EdgeInsets.all(context.gutter()),
        child: const FeaturePlaceholder(
          title: 'Push inbox',
          subtitle:
              'Match alerts will arrive through Firebase Cloud Messaging. '
              'Register device tokens with /api/v1/notifications/devices/ '
              'after Firebase is configured. No provider keys live in the app.',
          icon: Icons.notifications_none_rounded,
        ),
      ),
    );
  }
}
