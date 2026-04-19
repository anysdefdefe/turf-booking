import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/admin_provider.dart';
import '../widgets/user_tile.dart';

class AdminUsersScreen extends ConsumerWidget {
  const AdminUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(allUsersProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Manage Users',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: usersAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
        ),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $e', style: const TextStyle(color: Colors.red)),
              ElevatedButton(
                onPressed: () => ref.refresh(allUsersProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (users) => RefreshIndicator(
          color: const Color(0xFF4CAF50),
          onRefresh: () async => ref.refresh(allUsersProvider),
          child: ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: users.length,
            itemBuilder: (context, index) {
              return UserTile(
                user: users[index],
                onBlock: () async {
                  final repo = ref.read(adminRepositoryProvider);
                  await repo.blockUser(users[index]['id']);
                  ref.refresh(allUsersProvider);
                },
                onUnblock: () async {
                  final repo = ref.read(adminRepositoryProvider);
                  await repo.unblockUser(users[index]['id']);
                  ref.refresh(allUsersProvider);
                },
              );
            },
          ),
        ),
      ),
    );
  }
}