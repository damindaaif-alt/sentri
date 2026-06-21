import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/caller_info.dart';
import '../bloc/caller_id_bloc.dart';
import '../widgets/risk_score_badge.dart';

class CallerDetailPage extends StatelessWidget {
  final String phoneNumber;
  const CallerDetailPage({super.key, required this.phoneNumber});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<CallerIdBloc>()
        ..add(CallerIdLookupRequested(phoneNumber)),
      child: Scaffold(
        appBar: AppBar(title: const Text('Caller Info')),
        body: BlocBuilder<CallerIdBloc, CallerIdState>(
          builder: (context, state) => switch (state) {
            CallerIdLoading() => const Center(child: CircularProgressIndicator()),
            CallerIdLoaded(:final callerInfo) => _CallerDetail(info: callerInfo),
            CallerIdError(:final message) => Center(child: Text(message)),
            _ => const SizedBox.shrink(),
          },
        ),
      ),
    );
  }
}

class _CallerDetail extends StatelessWidget {
  final CallerInfo info;
  const _CallerDetail({required this.info});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: RiskScoreBadge(score: info.riskScore, size: 96)),
          const SizedBox(height: 20),
          Center(
            child: Text(
              info.name ?? info.phoneNumber,
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          if (info.organization != null) ...[
            const SizedBox(height: 4),
            Center(
              child: Text(info.organization!, style: theme.textTheme.bodyMedium),
            ),
          ],
          const SizedBox(height: 32),
          _InfoTile(label: 'Phone', value: info.phoneNumber),
          _InfoTile(label: 'Category', value: info.category.name.toUpperCase()),
          _InfoTile(label: 'Reports', value: '${info.reportCount} community reports'),
          _InfoTile(
            label: 'Spoofing',
            value: info.spoofingStatus.name,
            valueColor: info.spoofingStatus == SpoofingStatus.confirmed
                ? SentriColors.riskCritical
                : null,
          ),
          if (info.evidenceTags.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Evidence', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: info.evidenceTags
                  .map((tag) => Chip(label: Text(tag)))
                  .toList(),
            ),
          ],
          const SizedBox(height: 32),
          _ReportButton(phoneNumber: info.phoneNumber),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _InfoTile({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              )),
          Text(value,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600, color: valueColor)),
        ],
      ),
    );
  }
}

class _ReportButton extends StatelessWidget {
  final String phoneNumber;
  const _ReportButton({required this.phoneNumber});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.tonal(
        onPressed: () => _showReportSheet(context),
        child: const Text('Report this number'),
      ),
    );
  }

  void _showReportSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => _ReportSheet(phoneNumber: phoneNumber, bloc: context.read<CallerIdBloc>()),
    );
  }
}

class _ReportSheet extends StatelessWidget {
  final String phoneNumber;
  final CallerIdBloc bloc;
  const _ReportSheet({required this.phoneNumber, required this.bloc});

  @override
  Widget build(BuildContext context) {
    final categories = [
      RiskCategory.spam,
      RiskCategory.scam,
      RiskCategory.vishing,
      RiskCategory.robocall,
      RiskCategory.telemarketing,
    ];
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Report as', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          ...categories.map(
            (c) => ListTile(
              title: Text(c.name[0].toUpperCase() + c.name.substring(1)),
              onTap: () {
                bloc.add(CallerIdNumberReported(
                  phoneNumber: phoneNumber,
                  category: c,
                ));
                Navigator.of(context).pop();
              },
            ),
          ),
        ],
      ),
    );
  }
}
