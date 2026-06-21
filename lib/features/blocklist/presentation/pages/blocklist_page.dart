import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../bloc/blocklist_bloc.dart';

class BlocklistPage extends StatelessWidget {
  const BlocklistPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<BlocklistBloc>()..add(const BlocklistLoaded()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Blocklist'),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _showAddSheet(context),
            ),
          ],
        ),
        body: BlocBuilder<BlocklistBloc, BlocklistState>(
          builder: (context, state) => switch (state) {
            BlocklistLoading() => const Center(child: CircularProgressIndicator()),
            BlocklistReady(:final numbers) when numbers.isEmpty =>
              const Center(child: Text('No blocked numbers')),
            BlocklistReady(:final numbers) => ListView.separated(
                itemCount: numbers.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final n = numbers[i];
                  return ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.block)),
                    title: Text(n.phoneNumber),
                    subtitle: n.label != null ? Text(n.label!) : null,
                    trailing: IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: () => context
                          .read<BlocklistBloc>()
                          .add(BlocklistNumberUnblocked(n.phoneNumber)),
                    ),
                  );
                },
              ),
            _ => const SizedBox.shrink(),
          },
        ),
      ),
    );
  }

  void _showAddSheet(BuildContext outerContext) {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: outerContext,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 20, right: 20, top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone number',
                hintText: '+1 555 000 0000',
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  if (controller.text.trim().isNotEmpty) {
                    outerContext.read<BlocklistBloc>().add(
                          BlocklistNumberBlocked(controller.text.trim()),
                        );
                    Navigator.of(ctx).pop();
                  }
                },
                child: const Text('Block'),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
