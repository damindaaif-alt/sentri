import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/database/sentri_database.dart';
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
      create: (_) =>
          getIt<CallerIdBloc>()..add(CallerIdLookupRequested(phoneNumber)),
      child: Scaffold(
        appBar: AppBar(title: const Text('Caller Info')),
        body: BlocBuilder<CallerIdBloc, CallerIdState>(
          builder: (context, state) => switch (state) {
            CallerIdLoading() =>
              const Center(child: CircularProgressIndicator()),
            CallerIdLoaded(:final callerInfo) =>
              _CallerDetail(info: callerInfo),
            CallerIdError(:final message) => _ErrorView(message: message),
            CallerIdReported() => _CallerDetail(
                info: CallerInfo(
                  phoneNumber: phoneNumber,
                  riskScore: 0,
                  category: RiskCategory.unknown,
                  spoofingStatus: SpoofingStatus.unknown,
                  reportCount: 0,
                ),
              ),
            _ => const SizedBox.shrink(),
          },
        ),
      ),
    );
  }
}

// ── Main detail body ──────────────────────────────────────────────────────────

class _CallerDetail extends StatefulWidget {
  final CallerInfo info;
  const _CallerDetail({required this.info});

  @override
  State<_CallerDetail> createState() => _CallerDetailState();
}

class _CallerDetailState extends State<_CallerDetail> {
  bool _isBlocked = false;
  bool _blockLoading = false;

  @override
  void initState() {
    super.initState();
    _checkBlocked();
  }

  Future<void> _checkBlocked() async {
    final blocked =
        await getIt<SentriDatabase>().isBlocked(widget.info.phoneNumber);
    if (mounted) setState(() => _isBlocked = blocked);
  }

  Future<void> _toggleBlock() async {
    setState(() => _blockLoading = true);
    final db = getIt<SentriDatabase>();
    if (_isBlocked) {
      await db.unblockNumber(widget.info.phoneNumber);
    } else {
      await db.blockNumber(
        widget.info.phoneNumber,
        label: widget.info.name,
      );
    }
    if (mounted) {
      setState(() {
        _isBlocked = !_isBlocked;
        _blockLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isBlocked
                ? '${widget.info.phoneNumber} blocked'
                : '${widget.info.phoneNumber} unblocked',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final info = widget.info;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _HeaderCard(info: info),
          const SizedBox(height: 12),
          _RiskCard(info: info),
          const SizedBox(height: 12),
          _IdentityCard(info: info),
          if (info.evidenceTags.isNotEmpty) ...[
            const SizedBox(height: 12),
            _EvidenceCard(tags: info.evidenceTags),
          ],
          const SizedBox(height: 24),
          _BlockButton(
            isBlocked: _isBlocked,
            loading: _blockLoading,
            onTap: _toggleBlock,
          ),
          const SizedBox(height: 10),
          _ReportButton(info: info),
        ],
      ),
    );
  }
}

// ── Header card ───────────────────────────────────────────────────────────────

class _HeaderCard extends StatelessWidget {
  final CallerInfo info;
  const _HeaderCard({required this.info});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initials = _initials(info.name ?? info.phoneNumber);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor:
                  theme.colorScheme.primaryContainer,
              child: Text(
                initials,
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              info.name ?? info.phoneNumber,
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            if (info.name != null) ...[
              const SizedBox(height: 2),
              Text(
                info.phoneNumber,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (info.organization != null) ...[
              const SizedBox(height: 4),
              Text(
                info.organization!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (info.isVerifiedBusiness) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified,
                      size: 16, color: SentriColors.primary),
                  const SizedBox(width: 4),
                  Text(
                    'Verified Business',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: SentriColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _initials(String value) {
    final parts = value.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    if (value.startsWith('+') || RegExp(r'^\d').hasMatch(value)) {
      return '#';
    }
    return value[0].toUpperCase();
  }
}

// ── Risk card ─────────────────────────────────────────────────────────────────

class _RiskCard extends StatelessWidget {
  final CallerInfo info;
  const _RiskCard({required this.info});

  Color get _riskColor {
    final s = info.riskScore;
    if (s < 20) return SentriColors.riskSafe;
    if (s < 40) return SentriColors.riskLow;
    if (s < 60) return SentriColors.riskMedium;
    if (s < 80) return SentriColors.riskHigh;
    return SentriColors.riskCritical;
  }

  String get _riskDescription {
    if (info.isUnknown) return 'No community data yet for this number.';
    final s = info.riskScore;
    if (s < 20) return 'This number appears safe based on available data.';
    if (s < 40) return 'Low risk. Monitor if calls seem unusual.';
    if (s < 60) return 'Moderate risk. Exercise caution.';
    if (s < 80) return 'High risk. Likely spam or scam.';
    return 'Critical risk. Auto-block recommended.';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: _riskColor.withOpacity(0.4), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              'RISK SCORE',
              style: theme.textTheme.labelSmall?.copyWith(
                letterSpacing: 1.2,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            RiskScoreBadge(score: info.riskScore, size: 96),
            const SizedBox(height: 16),
            Text(
              _riskDescription,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (info.reportCount > 0) ...[
              const SizedBox(height: 8),
              Text(
                '${info.reportCount} community report${info.reportCount == 1 ? '' : 's'}',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: _riskColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Identity / STIR-SHAKEN card ───────────────────────────────────────────────

class _IdentityCard extends StatelessWidget {
  final CallerInfo info;
  const _IdentityCard({required this.info});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            _DetailRow(
              label: 'Category',
              value: _categoryLabel(info.category),
              valueColor: _categoryColor(info.category),
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            _DetailRow(
              label: 'Caller ID',
              value: _spoofingLabel(info.spoofingStatus),
              valueColor: _spoofingColor(info.spoofingStatus),
              trailing: _spoofingIcon(info.spoofingStatus),
            ),
            if (info.lastReportedAt != null) ...[
              const Divider(height: 1, indent: 16, endIndent: 16),
              _DetailRow(
                label: 'Last reported',
                value: _formatDate(info.lastReportedAt!),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _categoryLabel(RiskCategory c) => switch (c) {
        RiskCategory.unknown => 'Unknown',
        RiskCategory.safe => 'Safe',
        RiskCategory.telemarketing => 'Telemarketing',
        RiskCategory.robocall => 'Robocall',
        RiskCategory.spam => 'Spam',
        RiskCategory.scam => 'Scam',
        RiskCategory.vishing => 'Voice Phishing',
        RiskCategory.spoofed => 'Spoofed',
        RiskCategory.malicious => 'Malicious',
      };

  Color? _categoryColor(RiskCategory c) => switch (c) {
        RiskCategory.unknown || RiskCategory.safe => null,
        RiskCategory.telemarketing || RiskCategory.robocall =>
          SentriColors.riskLow,
        RiskCategory.spam => SentriColors.riskMedium,
        RiskCategory.scam ||
        RiskCategory.vishing ||
        RiskCategory.spoofed =>
          SentriColors.riskHigh,
        RiskCategory.malicious => SentriColors.riskCritical,
      };

  String _spoofingLabel(SpoofingStatus s) => switch (s) {
        SpoofingStatus.unknown => 'Unverified',
        SpoofingStatus.verified => 'Verified (STIR/SHAKEN)',
        SpoofingStatus.likelySpoofed => 'Likely Spoofed',
        SpoofingStatus.confirmed => 'Confirmed Spoofed',
      };

  Color? _spoofingColor(SpoofingStatus s) => switch (s) {
        SpoofingStatus.unknown => null,
        SpoofingStatus.verified => SentriColors.riskSafe,
        SpoofingStatus.likelySpoofed => SentriColors.riskHigh,
        SpoofingStatus.confirmed => SentriColors.riskCritical,
      };

  Widget? _spoofingIcon(SpoofingStatus s) => switch (s) {
        SpoofingStatus.verified =>
          const Icon(Icons.verified, size: 16, color: SentriColors.riskSafe),
        SpoofingStatus.likelySpoofed || SpoofingStatus.confirmed =>
          const Icon(Icons.warning_amber_rounded,
              size: 16, color: SentriColors.riskHigh),
        _ => null,
      };

  String _formatDate(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 30) return '${diff.inDays} days ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

// ── Evidence tags card ────────────────────────────────────────────────────────

class _EvidenceCard extends StatelessWidget {
  final List<String> tags;
  const _EvidenceCard({required this.tags});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Evidence',
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: tags
                  .map((t) => Chip(
                        label: Text(t,
                            style: const TextStyle(fontSize: 12)),
                        padding: EdgeInsets.zero,
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Action buttons ────────────────────────────────────────────────────────────

class _BlockButton extends StatelessWidget {
  final bool isBlocked;
  final bool loading;
  final VoidCallback onTap;
  const _BlockButton(
      {required this.isBlocked,
      required this.loading,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor:
              isBlocked ? Colors.grey.shade700 : SentriColors.riskHigh,
        ),
        onPressed: loading ? null : onTap,
        icon: loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : Icon(isBlocked ? Icons.block_flipped : Icons.block),
        label: Text(isBlocked ? 'Unblock number' : 'Block this number'),
      ),
    );
  }
}

class _ReportButton extends StatelessWidget {
  final CallerInfo info;
  const _ReportButton({required this.info});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: FilledButton.tonal(
        onPressed: () => _showReportSheet(context),
        child: const Text('Report this number'),
      ),
    );
  }

  void _showReportSheet(BuildContext outerCtx) {
    final bloc = outerCtx.read<CallerIdBloc>();
    showModalBottomSheet(
      context: outerCtx,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _ReportSheet(
          phoneNumber: info.phoneNumber, bloc: bloc),
    );
  }
}

class _ReportSheet extends StatelessWidget {
  final String phoneNumber;
  final CallerIdBloc bloc;
  const _ReportSheet(
      {required this.phoneNumber, required this.bloc});

  @override
  Widget build(BuildContext context) {
    const categories = [
      (RiskCategory.spam, Icons.mark_email_unread_outlined, 'Spam'),
      (RiskCategory.scam, Icons.money_off_outlined, 'Scam'),
      (RiskCategory.vishing, Icons.mic_off_outlined, 'Voice Phishing'),
      (RiskCategory.robocall, Icons.smart_toy_outlined, 'Robocall'),
      (RiskCategory.telemarketing, Icons.campaign_outlined, 'Telemarketing'),
    ];
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Report as',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            ...categories.map(
              ((RiskCategory, IconData, String) c) => ListTile(
                leading: Icon(c.$2),
                title: Text(c.$3),
                contentPadding: EdgeInsets.zero,
                onTap: () {
                  // Store messenger before pop so it's valid after unmount.
                  final messenger = ScaffoldMessenger.of(context);
                  bloc.add(CallerIdNumberReported(
                    phoneNumber: phoneNumber,
                    category: c.$1,
                  ));
                  Navigator.of(context).pop();
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Thank you for reporting')),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final Widget? trailing;
  const _DetailRow(
      {required this.label,
      required this.value,
      this.valueColor,
      this.trailing});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Text(label,
              style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant)),
          const Spacer(),
          if (trailing != null) ...[trailing!, const SizedBox(width: 6)],
          Text(value,
              style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600, color: valueColor)),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_outlined,
                size: 56,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text('Could not load caller info',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
