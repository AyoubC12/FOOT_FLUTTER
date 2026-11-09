import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/theme/app_colors.dart';
import '../football/fixture_models.dart';
import 'app_card.dart';
import 'club_logo.dart';

class FixtureCard extends StatelessWidget {
  const FixtureCard({
    super.key,
    required this.fixture,
    this.onTap,
    this.compact = false,
  });

  final FootballFixture fixture;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      accentBorder: fixture.isLive,
      padding: EdgeInsets.all(compact ? 12 : 16),
      child: Column(
        children: [
          Row(
            children: [
              _StatusChip(fixture: fixture),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  fixture.leagueName ?? 'Competition',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.muted,
                  ),
                ),
              ),
              Text(
                _timeLabel(fixture),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 12 : 16),
          Row(
            children: [
              Expanded(
                child: _Side(
                  name: fixture.homeName ?? 'Home',
                  logo: fixture.homeLogo,
                  compact: compact,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: fixture.isUpcoming
                    ? Text(
                        'VS',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w800,
                        ),
                      )
                    : Text(
                        '${fixture.homeGoals ?? '—'}  –  ${fixture.awayGoals ?? '—'}',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
              ),
              Expanded(
                child: _Side(
                  name: fixture.awayName ?? 'Away',
                  logo: fixture.awayLogo,
                  compact: compact,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _timeLabel(FootballFixture fixture) {
    if (fixture.isLive && fixture.elapsed != null) {
      return "${fixture.elapsed}'";
    }
    final date = fixture.date;
    if (date == null) return fixture.statusShort;
    return DateFormat('EEE d MMM · HH:mm').format(date.toLocal());
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.fixture});

  final FootballFixture fixture;

  @override
  Widget build(BuildContext context) {
    final live = fixture.isLive;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (live ? AppColors.live : AppColors.info).withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (live)
            Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.only(right: 6),
              decoration: const BoxDecoration(
                color: AppColors.live,
                shape: BoxShape.circle,
              ),
            ),
          Text(
            live ? 'LIVE' : (fixture.isFinished ? 'FT' : 'UPCOMING'),
            style: TextStyle(
              color: live ? AppColors.live : AppColors.info,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _Side extends StatelessWidget {
  const _Side({required this.name, required this.logo, required this.compact});

  final String name;
  final String? logo;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClubLogo(name: name, url: logo, size: compact ? 40 : 52),
        const SizedBox(height: 8),
        Text(
          name,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
