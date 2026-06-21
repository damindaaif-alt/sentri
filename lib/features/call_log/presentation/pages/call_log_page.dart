import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../caller_id/domain/entities/caller_info.dart';
import '../../../caller_id/presentation/widgets/risk_score_badge.dart';

// Placeholder page — wired to real BLoC in the next sprint
class CallLogPage extends StatelessWidget {
  const CallLogPage({super.key});

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
      body: _SampleCallList(),
    );
  }
}

class _SampleCallList extends StatelessWidget {
  final _fmt = DateFormat('MMM d, h:mm a');

  final _samples = const [
    (number: '+14155552671', name: 'IRS Scam Alert', score: 94, blocked: true, category: RiskCategory.scam),
    (number: '+12025559876', name: null, score: 72, blocked: true, category: RiskCategory.robocall),
    (number: '+19175551234', name: 'Mom', score: 2, blocked: false, category: RiskCategory.safe),
    (number: '+16505557890', name: 'Unknown', score: 45, blocked: false, category: RiskCategory.telemarketing),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: _samples.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final s = _samples[i];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: RiskScoreBadge(score: s.score, size: 48),
          title: Text(
            s.name ?? s.number,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            '${s.category.name} · ${_fmt.format(DateTime.now().subtract(Duration(minutes: i * 23 + 5)))}',
          ),
          trailing: s.blocked
              ? const Icon(Icons.block, color: SentriColors.riskHigh, size: 18)
              : null,
          onTap: () => context.push(
            AppRoutes.callerDetail.replaceFirst(':number', Uri.encodeComponent(s.number)),
          ),
        );
      },
    );
  }
}
