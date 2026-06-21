import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../caller_id/domain/entities/caller_info.dart';
import '../../../caller_id/presentation/widgets/risk_score_badge.dart';
import '../../domain/entities/threat_entry.dart';
import '../bloc/threat_feed_bloc.dart';
import '../bloc/threat_feed_event.dart';
import '../bloc/threat_feed_state.dart';

class ThreatFeedPage extends StatelessWidget {
  const ThreatFeedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<ThreatFeedBloc>()..add(const ThreatFeedLoadRequested()),
      child: const _ThreatFeedView(),
    );
  }
}

class _ThreatFeedView extends StatelessWidget {
  const _ThreatFeedView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.security, color: SentriColors.primary, size: 22),
            const SizedBox(width: 8),
            const Text('Threat Feed'),
          ],
        ),
        actions: [
          BlocBuilder<ThreatFeedBloc, ThreatFeedState>(
            builder: (context, state) {
              final syncing =
                  state is ThreatFeedLoaded && state.isSyncing;
              return IconButton(
                icon: syncing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.sync),
                onPressed: syncing
                    ? null
                    : () => context
                        .read<ThreatFeedBloc>()
                        .add(const ThreatFeedSyncRequested()),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<ThreatFeedBloc, ThreatFeedState>(
        builder: (context, state) => switch (state) {
          ThreatFeedInitial() || ThreatFeedLoading() =>
            const Center(child: CircularProgressIndicator()),
          ThreatFeedError(:final message) => _ErrorView(
              onRetry: () => context
                  .read<ThreatFeedBloc>()
                  .add(const ThreatFeedLoadRequested()),
            ),
          ThreatFeedLoaded() => _LoadedView(state: state),
        },
      ),
    );
  }
}

// ── Loaded view ───────────────────────────────────────────────────────────────

class _LoadedView extends StatelessWidget {
  final ThreatFeedLoaded state;
  const _LoadedView({required this.state});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SyncBar(syncedAt: state.syncedAt),
        _StatsRow(state: state),
        _FilterRow(active: state.activeFilter),
        const Divider(height: 1),
        Expanded(
          child: state.filtered.isEmpty
              ? _EmptyFilter()
              : ListView.separated(
                  itemCount: state.filtered.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) =>
                      _ThreatTile(entry: state.filtered[i]),
                ),
        ),
      ],
    );
  }
}

// ── Sync bar ──────────────────────────────────────────────────────────────────

class _SyncBar extends StatelessWidget {
  final DateTime? syncedAt;
  const _SyncBar({this.syncedAt});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = syncedAt == null
        ? 'Never synced'
        : 'Updated ${_relative(syncedAt!)}';
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.cloud_done_outlined,
              size: 14,
              color: SentriColors.riskSafe),
          const SizedBox(width: 6),
          Text(label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              )),
        ],
      ),
    );
  }

  static String _relative(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return DateFormat('MMM d, h:mm a').format(dt);
  }
}

// ── Stats row ─────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final ThreatFeedLoaded state;
  const _StatsRow({required this.state});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: Row(
        children: [
          _StatChip(
            label: '${state.allEntries.length}',
            sublabel: 'Total',
            color: SentriColors.primary,
          ),
          const SizedBox(width: 8),
          _StatChip(
            label: '${state.criticalCount}',
            sublabel: 'Critical',
            color: SentriColors.riskCritical,
          ),
          const SizedBox(width: 8),
          _StatChip(
            label: '${state.trendingCount}',
            sublabel: 'Trending',
            color: SentriColors.riskHigh,
          ),
          const Spacer(),
          if (!state.autoBlockEnabled)
            FilledButton.tonalIcon(
              onPressed: () => _confirmAutoBlock(context),
              icon: const Icon(Icons.shield_outlined, size: 16),
              label: const Text('Auto-block'),
              style: FilledButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                textStyle: const TextStyle(fontSize: 12),
                minimumSize: Size.zero,
              ),
            )
          else
            Chip(
              avatar: const Icon(Icons.shield,
                  size: 14, color: SentriColors.riskSafe),
              label: const Text('Auto-block on',
                  style: TextStyle(fontSize: 11)),
              padding: EdgeInsets.zero,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
        ],
      ),
    );
  }

  void _confirmAutoBlock(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Auto-block critical threats?'),
        content: const Text(
          'This will add all numbers with a Critical risk score (80+) '
          'from this feed to your blocklist. You can remove them individually at any time.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              context
                  .read<ThreatFeedBloc>()
                  .add(const ThreatFeedAutoBlockRequested());
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Critical threats added to blocklist')),
              );
            },
            style:
                FilledButton.styleFrom(backgroundColor: SentriColors.riskHigh),
            child: const Text('Auto-block'),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String sublabel;
  final Color color;
  const _StatChip(
      {required this.label, required this.sublabel, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        children: [
          Text(label,
              style: TextStyle(
                  fontWeight: FontWeight.w800, color: color, fontSize: 18)),
          Text(sublabel,
              style: TextStyle(fontSize: 10, color: color.withOpacity(0.8))),
        ],
      ),
    );
  }
}

// ── Filter chips ──────────────────────────────────────────────────────────────

class _FilterRow extends StatelessWidget {
  final RiskCategory? active;
  const _FilterRow({this.active});

  static const _filters = [
    (label: 'All', cat: null),
    (label: 'Scam', cat: RiskCategory.scam),
    (label: 'Robocall', cat: RiskCategory.robocall),
    (label: 'Vishing', cat: RiskCategory.vishing),
    (label: 'Spam', cat: RiskCategory.spam),
    (label: 'Telemarketing', cat: RiskCategory.telemarketing),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: _filters.map((f) {
          final selected = f.cat == active;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(f.label),
              selected: selected,
              onSelected: (_) => context
                  .read<ThreatFeedBloc>()
                  .add(ThreatFeedFilterChanged(f.cat)),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Threat tile ───────────────────────────────────────────────────────────────

class _ThreatTile extends StatelessWidget {
  final ThreatEntry entry;
  const _ThreatTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: RiskScoreBadge(score: entry.riskScore, size: 48),
      title: Row(
        children: [
          Expanded(
            child: Text(
              entry.phoneNumber,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontFamily: 'monospace'),
            ),
          ),
          if (entry.isTrending) ...[
            const SizedBox(width: 6),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: SentriColors.riskHigh.withOpacity(0.15),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                    color: SentriColors.riskHigh.withOpacity(0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.trending_up,
                      size: 10, color: SentriColors.riskHigh),
                  const SizedBox(width: 2),
                  Text('HOT',
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: SentriColors.riskHigh,
                          letterSpacing: 0.5)),
                ],
              ),
            ),
          ],
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 3),
          Row(
            children: [
              _CategoryPill(entry.category),
              if (entry.region != null) ...[
                const SizedBox(width: 6),
                Text(
                  entry.region!,
                  style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
              const Spacer(),
              Icon(Icons.people_outline,
                  size: 12,
                  color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 2),
              Text(
                _formatReports(entry.reportCount),
                style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
          if (entry.tags.isNotEmpty) ...[
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              children: entry.tags.take(3).map((t) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color:
                        theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    t.replaceAll('_', ' '),
                    style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 9,
                        color: theme.colorScheme.onSurfaceVariant),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
      trailing: const Icon(Icons.chevron_right, size: 18),
      onTap: () {
        final encoded = Uri.encodeComponent(entry.phoneNumber);
        context.push(
            AppRoutes.callerDetail.replaceFirst(':number', encoded));
      },
    );
  }

  static String _formatReports(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return '$n';
  }
}

class _CategoryPill extends StatelessWidget {
  final RiskCategory category;
  const _CategoryPill(this.category);

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (category) {
      RiskCategory.scam => ('Scam', SentriColors.riskCritical),
      RiskCategory.vishing => ('Vishing', SentriColors.riskHigh),
      RiskCategory.robocall => ('Robocall', SentriColors.riskMedium),
      RiskCategory.spam => ('Spam', SentriColors.riskLow),
      RiskCategory.telemarketing => ('Telemarketing', SentriColors.riskLow),
      _ => ('Unknown', Colors.grey),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

// ── Empty / Error ─────────────────────────────────────────────────────────────

class _EmptyFilter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.filter_list_off,
              size: 48,
              color: Theme.of(context)
                  .colorScheme
                  .onSurfaceVariant
                  .withOpacity(0.4)),
          const SizedBox(height: 12),
          Text('No threats in this category',
              style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off_outlined,
              size: 56,
              color: Theme.of(context)
                  .colorScheme
                  .onSurfaceVariant
                  .withOpacity(0.5)),
          const SizedBox(height: 16),
          const Text('Could not load threat feed'),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
