import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/preview/preview_catalog.dart';
import '../../../../core/tactics/pitch_player.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/football_pitch.dart';
import '../../../../core/widgets/formation_selector.dart';
import '../../../../core/widgets/section_header.dart';
import '../providers/tactics_controller.dart';

class TacticsScreen extends ConsumerWidget {
  const TacticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tactics = ref.watch(tacticsControllerProvider);
    final controller = ref.read(tacticsControllerProvider.notifier);
    final gutter = context.gutter();
    final pitchHeight = context.isCompact ? 380.0 : 460.0;
    final compareSideBySide = !context.isCompact && tactics.compareMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tactical analysis'),
        actions: [
          IconButton(
            tooltip: 'AI suggestion',
            onPressed: tactics.suggesting ? null : controller.requestSuggestion,
            icon: tactics.suggesting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome_rounded),
          ),
          IconButton(
            tooltip: 'Save formation',
            onPressed: tactics.saving
                ? null
                : () => _saveDialog(context, ref, tactics),
            icon: const Icon(Icons.save_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(gutter, 8, gutter, 28),
        children: [
          if (tactics.needsAuth || AppConstants.apiBaseUrl.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _AuthNote(
                configured: AppConstants.apiBaseUrl.isNotEmpty,
                onSignIn: () => context.go(AppRoutes.login),
              ),
            ),
          if (tactics.error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                tactics.error!,
                style: const TextStyle(color: AppColors.danger),
              ),
            ),
          const SectionHeader(title: 'Formation'),
          FormationSelector(
            value: tactics.formation,
            onChanged: controller.selectFormation,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              FilterChip(
                label: const Text('Compare'),
                selected: tactics.compareMode,
                selectedColor: AppColors.accentMuted,
                onSelected: controller.toggleCompare,
              ),
              ActionChip(
                avatar: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                label: const Text('Add player'),
                onPressed: tactics.players.length >= 11
                    ? null
                    : () => _addPlayerSheet(context, ref),
              ),
              if (tactics.selected != null)
                ActionChip(
                  avatar: const Icon(Icons.person_remove_alt_1_rounded, size: 18),
                  label: const Text('Remove'),
                  onPressed: controller.removeSelected,
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (compareSideBySide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _PitchCard(
                    title: tactics.formation,
                    players: tactics.players,
                    selectedId: tactics.selectedId,
                    height: pitchHeight,
                    onTap: controller.selectPlayer,
                    onMoved: controller.movePlayer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ComparePitch(
                    tactics: tactics,
                    height: pitchHeight,
                    controller: controller,
                  ),
                ),
              ],
            )
          else ...[
            _PitchCard(
              title: tactics.formation,
              players: tactics.players,
              selectedId: tactics.selectedId,
              height: pitchHeight,
              onTap: controller.selectPlayer,
              onMoved: controller.movePlayer,
            ),
            if (tactics.compareMode) ...[
              const SizedBox(height: 16),
              _ComparePitch(
                tactics: tactics,
                height: pitchHeight * 0.92,
                controller: controller,
              ),
            ],
          ],
          const SizedBox(height: 16),
          AppCard(
            child: tactics.selected == null
                ? const Text(
                    'Drag players to reshape the block. Tap a token to edit the role.',
                    style: TextStyle(color: AppColors.muted),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tactics.selected!.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${tactics.selected!.position} · ${tactics.formation}',
                        style: const TextStyle(color: AppColors.muted),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'x ${tactics.selected!.x.toStringAsFixed(2)}  ·  '
                        'y ${tactics.selected!.y.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 16),
          const SectionHeader(title: 'AI tactical notes'),
          AppCard(
            child: tactics.suggesting
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : tactics.suggestion == null
                ? const Text(
                    'Ask FootGPT for coaching notes on this diagram. '
                    'Notes use the board layout and verified formation guides — not live stats.',
                    style: TextStyle(color: AppColors.muted),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tactics.suggestion!.text),
                      const SizedBox(height: 10),
                      for (final tip in tactics.suggestion!.tips.take(4))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            '• $tip',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.muted),
                          ),
                        ),
                      Text(
                        tactics.suggestion!.disclaimer,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 8),
          AppButton(
            label: tactics.compareMode
                ? 'Compare these shapes'
                : 'Suggest for this board',
            icon: Icons.auto_awesome_rounded,
            isLoading: tactics.suggesting,
            onPressed: controller.requestSuggestion,
          ),
          const SizedBox(height: 20),
          const SectionHeader(title: 'Saved boards'),
          if (tactics.saved.isEmpty)
            const Text(
              'Saved formations appear here after you sign in and persist a board.',
              style: TextStyle(color: AppColors.muted),
            )
          else
            for (final board in tactics.saved)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AppCard(
                  onTap: () => controller.loadBoard(board),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              board.name,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            Text(
                              '${board.formation} · ${board.players.length} players',
                              style: const TextStyle(color: AppColors.muted),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () =>
                            controller.loadBoard(board, compare: true),
                        child: const Text('Compare'),
                      ),
                      IconButton(
                        onPressed: () => controller.deleteSaved(board.id),
                        icon: const Icon(Icons.delete_outline_rounded),
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class _PitchCard extends StatelessWidget {
  const _PitchCard({
    required this.title,
    required this.players,
    required this.selectedId,
    required this.height,
    required this.onTap,
    required this.onMoved,
  });

  final String title;
  final List<PitchPlayer> players;
  final String? selectedId;
  final double height;
  final ValueChanged<PitchPlayer> onTap;
  final void Function(String id, double x, double y) onMoved;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(title, style: Theme.of(context).textTheme.titleSmall),
          ),
          const SizedBox(height: 8),
          FootballPitch(
            players: players,
            selectedId: selectedId,
            interactive: true,
            height: height,
            compactTokens: true,
            onPlayerTap: onTap,
            onPlayerMoved: onMoved,
          ),
        ],
      ),
    );
  }
}

class _ComparePitch extends StatelessWidget {
  const _ComparePitch({
    required this.tactics,
    required this.height,
    required this.controller,
  });

  final TacticsState tactics;
  final double height;
  final TacticsController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Compare with'),
        FormationSelector(
          value: tactics.compareFormation,
          onChanged: controller.selectCompareFormation,
        ),
        const SizedBox(height: 12),
        _PitchCard(
          title: tactics.compareFormation,
          players: tactics.comparePlayers,
          selectedId: null,
          height: height,
          onTap: (_) {},
          onMoved: (id, x, y) => controller.movePlayer(id, x, y, compare: true),
        ),
      ],
    );
  }
}

class _AuthNote extends StatelessWidget {
  const _AuthNote({required this.configured, required this.onSignIn});

  final bool configured;
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Expanded(
            child: Text(
              configured
                  ? 'Sign in to save boards and request AI notes.'
                  : 'Connect the Django API to persist formations.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          if (configured)
            TextButton(onPressed: onSignIn, child: const Text('Sign in')),
        ],
      ),
    );
  }
}

Future<void> _saveDialog(
  BuildContext context,
  WidgetRef ref,
  TacticsState tactics,
) async {
  final name = TextEditingController(
    text: tactics.boardId == null ? '${tactics.formation} board' : '',
  );
  final confirmed = await showDialog<String>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Save formation'),
        content: TextField(
          controller: name,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Board name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, name.text.trim()),
            child: const Text('Save'),
          ),
        ],
      );
    },
  );
  if (confirmed == null || confirmed.isEmpty) return;
  await ref.read(tacticsControllerProvider.notifier).save(confirmed);
}

Future<void> _addPlayerSheet(BuildContext context, WidgetRef ref) async {
  final used = ref
      .read(tacticsControllerProvider)
      .players
      .map((player) => player.id)
      .toSet();
  final available = PreviewCatalog.players
      .where((player) => !used.contains(player.id))
      .toList();

  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      return SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            Text(
              'Add a player',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            for (final player in available)
              ListTile(
                title: Text(player.name),
                subtitle: Text('${player.position} · ${player.number}'),
                onTap: () {
                  ref.read(tacticsControllerProvider.notifier).addPlayer(
                        PitchPlayer(
                          id: player.id,
                          name: player.name,
                          position: player.position,
                          x: 0.5,
                          y: 0.4,
                          number: player.number,
                        ),
                      );
                  Navigator.pop(context);
                },
              ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Custom name'),
              onTap: () async {
                Navigator.pop(context);
                await _customPlayerDialog(context, ref);
              },
            ),
          ],
        ),
      );
    },
  );
}

Future<void> _customPlayerDialog(BuildContext context, WidgetRef ref) async {
  final name = TextEditingController();
  final position = TextEditingController(text: 'CM');
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Custom player'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: position,
              decoration: const InputDecoration(labelText: 'Position'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Add'),
          ),
        ],
      );
    },
  );
  if (confirmed != true || name.text.trim().isEmpty) return;
  ref.read(tacticsControllerProvider.notifier).addPlayer(
        PitchPlayer(
          id: 'custom-${DateTime.now().millisecondsSinceEpoch}',
          name: name.text.trim(),
          position: position.text.trim().isEmpty ? 'CM' : position.text.trim(),
          x: 0.5,
          y: 0.45,
        ),
      );
}
