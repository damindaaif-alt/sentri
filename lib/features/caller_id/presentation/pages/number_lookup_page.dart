import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/database/sentri_database.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/phone_number_utils.dart';
import '../widgets/risk_score_badge.dart';

class NumberLookupPage extends StatefulWidget {
  const NumberLookupPage({super.key});

  @override
  State<NumberLookupPage> createState() => _NumberLookupPageState();
}

class _NumberLookupPageState extends State<NumberLookupPage> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  String _input = '';
  List<Map<String, dynamic>> _recents = [];

  @override
  void initState() {
    super.initState();
    _loadRecents();
    _controller.addListener(() => setState(() => _input = _controller.text));
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _loadRecents() async {
    final rows = await getIt<SentriDatabase>().getAllCachedCallers();
    if (mounted) setState(() => _recents = rows);
  }

  String? get _normalised => PhoneNumberUtils.toE164(_input.trim());
  bool get _isValid => _normalised != null && PhoneNumberUtils.isValid(_normalised!);

  void _lookup() {
    if (!_isValid) return;
    _focus.unfocus();
    context.push(
      AppRoutes.callerDetail.replaceFirst(
        ':number',
        Uri.encodeComponent(_normalised!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Number Lookup')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SearchBar(
            controller: _controller,
            focus: _focus,
            isValid: _isValid,
            onLookup: _lookup,
            onClear: () {
              _controller.clear();
              _focus.requestFocus();
            },
          ),
          Expanded(
            child: _recents.isEmpty
                ? _EmptyHint(onPaste: _handlePaste)
                : _RecentsList(
                    recents: _recents,
                    onTap: (number) => context.push(
                      AppRoutes.callerDetail.replaceFirst(
                        ':number',
                        Uri.encodeComponent(number),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePaste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && mounted) {
      _controller.text = data!.text!.trim();
      _controller.selection = TextSelection.collapsed(
          offset: _controller.text.length);
    }
  }
}

// ── Search bar ────────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focus;
  final bool isValid;
  final VoidCallback onLookup;
  final VoidCallback onClear;

  const _SearchBar({
    required this.controller,
    required this.focus,
    required this.isValid,
    required this.onLookup,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: controller,
            focusNode: focus,
            autofocus: true,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.search,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w500,
              letterSpacing: 1.2,
            ),
            decoration: InputDecoration(
              hintText: '+94 77 000 0000',
              hintStyle: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
                fontWeight: FontWeight.w400,
                letterSpacing: 1.2,
              ),
              prefixIcon: Icon(Icons.phone_outlined,
                  color: SentriColors.primary, size: 22),
              suffixIcon: controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: onClear,
                    )
                  : null,
              filled: false,
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
            ),
            onSubmitted: (_) => onLookup(),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: isValid ? onLookup : null,
            icon: const Icon(Icons.search, size: 18),
            label: const Text('Look up number'),
          ),
          if (!isValid && controller.text.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Enter a valid international number (e.g. +94 77 123 4567)',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Recent lookups list ───────────────────────────────────────────────────────

class _RecentsList extends StatelessWidget {
  final List<Map<String, dynamic>> recents;
  final void Function(String number) onTap;

  const _RecentsList({required this.recents, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.only(top: 8),
      itemCount: recents.length + 1,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        if (i == 0) {
          return Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Text(
              'Recent lookups',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
            ),
          );
        }
        final entry = recents[i - 1];
        final phone = entry['phone_number'] as String? ?? '';
        final score = (entry['risk_score'] as num?)?.toInt() ?? 0;
        final name = entry['name'] as String?;
        return ListTile(
          leading: RiskScoreBadge(score: score, size: 44),
          title: Text(name ?? phone,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: name != null ? Text(phone) : null,
          trailing: const Icon(Icons.chevron_right, size: 18),
          onTap: () => onTap(phone),
        );
      },
    );
  }
}

// ── Empty hint ────────────────────────────────────────────────────────────────

class _EmptyHint extends StatelessWidget {
  final VoidCallback onPaste;
  const _EmptyHint({required this.onPaste});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.manage_search_outlined,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'Enter any phone number',
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Get an instant risk score, spoofing status, and community reports.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: onPaste,
            icon: const Icon(Icons.content_paste_outlined, size: 16),
            label: const Text('Paste from clipboard'),
          ),
        ],
      ),
    );
  }
}
