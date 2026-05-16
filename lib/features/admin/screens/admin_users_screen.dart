import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/admin_provider.dart';
import '../widgets/user_tile.dart';
import 'admin_user_detail_screen.dart';

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _filterRole = 'all'; // all, customers, owners, blocked

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _filterUsers(List<Map<String, dynamic>> users) {
    var filtered = users;

    // Filter by role
    switch (_filterRole) {
      case 'customers':
        filtered = filtered.where((u) => u['is_owner'] != true).toList();
        break;
      case 'owners':
        filtered = filtered.where((u) => u['is_owner'] == true).toList();
        break;
      case 'blocked':
        filtered = filtered.where((u) => u['is_blocked'] == true).toList();
        break;
    }

    // Filter by search
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((user) {
        final name = (user['full_name'] ?? '').toLowerCase();
        final email = (user['email'] ?? '').toLowerCase();
        final query = _searchQuery.toLowerCase();
        return name.contains(query) || email.contains(query);
      }).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(allUsersProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(title: const Text('Manage Users')),
      body: Column(
        children: [
          Container(
            color: cs.surface,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    hintText: 'Search by name or email...',
                    hintStyle: TextStyle(
                      color: cs.onSurfaceVariant,
                      fontSize: 14,
                    ),
                    prefixIcon: Icon(Icons.search, color: cs.onSurfaceVariant),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                            child: Icon(
                              Icons.close,
                              color: cs.onSurfaceVariant,
                            ),
                          )
                        : null,
                    filled: true,
                    fillColor: cs.surfaceContainerHighest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),

                const SizedBox(height: 10),

                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _filterChip('All', 'all', cs),
                      const SizedBox(width: 8),
                      _filterChip('Customers', 'customers', cs),
                      const SizedBox(width: 8),
                      _filterChip('Owners', 'owners', cs),
                      const SizedBox(width: 8),
                      _filterChip('Blocked', 'blocked', cs),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Users List
          Expanded(
            child: usersAsync.when(
              loading: () =>
                  Center(child: CircularProgressIndicator(color: cs.primary)),
              error: (e, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Error: $e', style: TextStyle(color: cs.error)),
                    FilledButton(
                      onPressed: () => ref.invalidate(allUsersProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (users) {
                final filtered = _filterUsers(users);
                return RefreshIndicator(
                  color: cs.primary,
                  onRefresh: () async => ref.invalidate(allUsersProvider),
                  child: filtered.isEmpty
                      ? Center(
                          child: Text(
                            _searchQuery.isEmpty
                                ? 'No users found'
                                : 'No results for "$_searchQuery"',
                            style: TextStyle(color: cs.onSurfaceVariant),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final user = filtered[index];
                            return GestureDetector(
                              onTap: () {
                                // Open user details page
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        AdminUserDetailScreen(user: user),
                                  ),
                                ).then((_) {
                                  // Refresh after returning
                                  ref.invalidate(allUsersProvider);
                                });
                              },
                              child: UserTile(
                                user: user,
                                onBlock: () => _handleBlock(context, ref, user),
                                onUnblock: () =>
                                    _handleUnblock(context, ref, user),
                              ),
                            );
                          },
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value, ColorScheme cs) {
    final isSelected = _filterRole == value;
    return GestureDetector(
      onTap: () => setState(() => _filterRole = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? cs.primary : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? cs.onPrimary : cs.onSurfaceVariant,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Future<void> _handleBlock(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> user,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Block User'),
        content: Text('Are you sure you want to block ${user['full_name']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Block'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final repo = ref.read(adminRepositoryProvider);
      await repo.blockUser(user['id']);
      ref.invalidate(allUsersProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${user['full_name']} blocked')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _handleUnblock(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> user,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unblock User'),
        content: Text('Are you sure you want to unblock ${user['full_name']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Unblock'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final repo = ref.read(adminRepositoryProvider);
      await repo.unblockUser(user['id']);
      ref.invalidate(allUsersProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${user['full_name']} unblocked')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}
