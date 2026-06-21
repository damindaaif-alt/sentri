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
      // Builder gives us a context that is inside the BlocProvider so that
      // the AppBar action can read BlocklistBloc via context.read.
      child: Builder(
        builder: (ctx) => Scaffold(
          appBar: AppBar(
            title: const Text('Blocklist'),
            actions: [
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => _showAddSheet(ctx),
              ),
            ],
          ),
          body: BlocBuilder<BlocklistBloc, BlocklistState>(
            builder: (ctx, state) => switch (state) {
              BlocklistLoading() =>
                const Center(child: CircularProgressIndicator()),
              BlocklistReady(:final numbers) when numbers.isEmpty =>
                const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.shield_outlined, size: 64, color: Colors.grey),
                      SizedBox(height: 12),
                      Text('No blocked numbers',
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              BlocklistReady(:final numbers) => ListView.separated(
                  itemCount: numbers.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (ctx, i) {
                    final n = numbers[i];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            Colors.red.withOpacity(0.15),
                        child: const Icon(Icons.block, color: Colors.red),
                      ),
                      title: Text(n.phoneNumber),
                      subtitle: n.label != null ? Text(n.label!) : null,
                      trailing: IconButton(
                        icon: const Icon(Icons.remove_circle_outline,
                            color: Colors.red),
                        onPressed: () => ctx
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
      ),
    );
  }

  void _showAddSheet(BuildContext ctx) {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      builder: (sheetCtx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetCtx).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
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
                hintText: '+94 77 000 0000',
                prefixIcon: Icon(Icons.phone),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.block),
                label: const Text('Block number'),
                style: FilledButton.styleFrom(
                    backgroundColor: Colors.red),
                onPressed: () {
                  final number = controller.text.trim();
                  if (number.isNotEmpty) {
                    ctx
                        .read<BlocklistBloc>()
                        .add(BlocklistNumberBlocked(number));
                    Navigator.of(sheetCtx).pop();
                  }
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
