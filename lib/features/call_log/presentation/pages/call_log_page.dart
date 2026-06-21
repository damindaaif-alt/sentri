import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../caller_id/presentation/widgets/risk_score_badge.dart';
import '../../domain/entities/call_record.dart';
import '../bloc/call_log_bloc.dart';

class CallLogPage extends StatelessWidget {
  const CallLogPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<CallLogBloc>()..add(const CallLogLoadRequested()),
      child: const _CallLogView(),
    );
  }
}

class _CallLogView extends StatelessWidget {
  const _CallLogView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.shield, color: SentriColors.primary, size: 22),
            const SizedBox(width: 8),
            const Text('Sentri'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.push(AppRoutes.numberLookup),
          ),
        ],
      ),
      body: BlocBuilder<CallLogBloc, CallLogState>(
        builder: (context, state) => switch (state) {
          CallLogInitial() || CallLogLoading() =>
            const Center(child: CircularProgressIndicator()),
          CallLogError(:final message) => _ErrorView(
              message: message,
              onRetry: () => context
                  .read<CallLogBloc>()
                  .add(const CallLogLoadRequested()),
            ),
          CallLogLoaded(:final records, :final isRefreshing) =>
            _CallList(records: records, isRefreshing: isRefreshing),
        },
      ),
    );
  }
}

class _CallList extends StatelessWidget {
  final List<CallRecord> records;
  final bool isRefreshing;
  const _CallList({required this.records, required this.isRefreshing});

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return const _EmptyView();
    }
    return RefreshIndicator(
      onRefresh: () async => context
          .read<CallLogBloc>()
          .add(const CallLogRefreshRequested()),
      child: Stack(
        children: [
          ListView.separated(
            itemCount: records.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) => _CallTile(record: records[i]),
          ),
          if (isRefreshing)
            const LinearProgressIndicator(),
        ],
      ),
    );
  }
}

class _CallTile extends StatelessWidget {
  final CallRecord record;
  const _CallTile({required this.record});

  static final _fmt = DateFormat('MMM d, h:mm a');

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: RiskScoreBadge(score: record.riskScore, size: 48),
      title: Text(
        record.name ?? record.phoneNumber,
        style: const TextStyle(fontWeight: FontWeight.w600),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Row(
        children: [
          _DirectionIcon(record.direction),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              '${_durationLabel(record.durationSeconds)} · ${_fmt.format(record.timestamp)}',
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      trailing: record.wasBlocked
          ? const Icon(Icons.block, color: SentriColors.riskHigh, size: 18)
          : record.riskScore >= 60
              ? const Icon(Icons.warning_amber_rounded,
                  color: SentriColors.riskMedium, size: 18)
              : null,
      onTap: () => context.push(
        AppRoutes.callerDetail.replaceFirst(
          ':number',
          Uri.encodeComponent(record.phoneNumber),
        ),
      ),
    );
  }

  String _durationLabel(int seconds) {
    if (seconds == 0) return 'No answer';
    if (seconds < 60) return '${seconds}s';
    return '${seconds ~/ 60}m ${seconds % 60}s';
  }
}

class _DirectionIcon extends StatelessWidget {
  final CallDirection direction;
  const _DirectionIcon(this.direction);

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (direction) {
      CallDirection.incoming => (Icons.call_received, SentriColors.riskSafe),
      CallDirection.outgoing => (Icons.call_made, Colors.blue),
      CallDirection.missed => (Icons.call_missed, SentriColors.riskHigh),
      CallDirection.rejected => (Icons.call_end, SentriColors.riskMedium),
      CallDirection.blocked => (Icons.block, SentriColors.riskCritical),
      CallDirection.unknown => (Icons.call, Colors.grey),
    };
    return Icon(icon, size: 14, color: color);
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.call_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(height: 16),
          Text('No recent calls',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Calls from the last 30 days will appear here',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  bool get _isPermission =>
      message.toLowerCase().contains('permission') ||
      message.toLowerCase().contains('denied');

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isPermission ? Icons.lock_outline : Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              _isPermission ? 'Permission required' : 'Could not load calls',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _isPermission
                  ? 'Sentri needs call log access to show your recent calls.'
                  : message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _isPermission
                  ? () async {
                      final status = await Permission.phone.request();
                      if (status.isGranted) onRetry();
                    }
                  : onRetry,
              child: Text(_isPermission ? 'Grant permission' : 'Retry'),
            ),
            if (_isPermission) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: openAppSettings,
                child: const Text('Open Settings'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
