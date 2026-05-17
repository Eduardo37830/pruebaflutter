import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../network/connectivity_provider.dart';

class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivityAsync = ref.watch(connectivityProvider);
    final isOnline = connectivityAsync.valueOrNull ?? true;

    if (isOnline) return const SizedBox.shrink();

    return MaterialBanner(
      backgroundColor: Theme.of(context).colorScheme.errorContainer,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      content: const Row(
        children: [
          Icon(Icons.cloud_off_rounded, size: 18),
          SizedBox(width: 8),
          Expanded(child: Text('Sin conexión. Los cambios se sincronizarán cuando vuelvas a estar online.')),
        ],
      ),
      actions: [const SizedBox.shrink()],
    );
  }
}
