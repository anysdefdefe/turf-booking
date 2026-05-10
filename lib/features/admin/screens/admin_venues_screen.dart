import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/admin_provider.dart';
import '../widgets/venue_tile.dart';

class AdminVenuesScreen extends ConsumerStatefulWidget {
  const AdminVenuesScreen({super.key});

  @override
  ConsumerState<AdminVenuesScreen> createState() => _AdminVenuesScreenState();
}

class _AdminVenuesScreenState extends ConsumerState<AdminVenuesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _filterStatus = 'all'; // 'all', 'active', 'suspended'

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _filterVenues(List<Map<String, dynamic>> venues) {
    var filtered = venues;

    // Filter by status
    if (_filterStatus == 'active') {
      filtered = filtered.where((v) => v['is_active'] == true).toList();
    } else if (_filterStatus == 'suspended') {
      filtered = filtered.where((v) => v['is_active'] == false).toList();
    }

    // Filter by search
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((v) {
        final name = (v['name'] ?? '').toLowerCase();
        final city = (v['city'] ?? '').toLowerCase();
        final query = _searchQuery.toLowerCase();
        return name.contains(query) || city.contains(query);
      }).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final venuesAsync = ref.watch(allVenuesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Manage Venues',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          // Search + Filter Section
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  onChanged: (value) =>
                      setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    hintText: 'Search by name or city...',
                    hintStyle:
                        TextStyle(color: Colors.grey[400], fontSize: 14),
                    prefixIcon:
                        const Icon(Icons.search, color: Colors.grey),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                            child: const Icon(Icons.close,
                                color: Colors.grey),
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFFF5F5F5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),

                const SizedBox(height: 10),

                // Filter Chips
                Row(
                  children: [
                    _filterChip('All', 'all'),
                    const SizedBox(width: 8),
                    _filterChip('Active', 'active'),
                    const SizedBox(width: 8),
                    _filterChip('Suspended', 'suspended'),
                  ],
                ),
              ],
            ),
          ),

          // Venues List
          Expanded(
            child: venuesAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(
                    color: Color(0xFF4CAF50)),
              ),
              error: (e, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Error: $e',
                        style: const TextStyle(color: Colors.red)),
                    ElevatedButton(
                      onPressed: () => ref.refresh(allVenuesProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (venues) {
                final filtered = _filterVenues(venues);
                return RefreshIndicator(
                  color: const Color(0xFF4CAF50),
                  onRefresh: () async => ref.refresh(allVenuesProvider),
                  child: filtered.isEmpty
                      ? Center(
                          child: Text(
                            _searchQuery.isEmpty
                                ? 'No venues found'
                                : 'No results for "$_searchQuery"',
                            style:
                                const TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final venue = filtered[index];
                            return VenueTile(
                              venue: venue,
                              onSuspend: () =>
                                  _handleSuspend(context, ref, venue),
                              onActivate: () =>
                                  _handleActivate(context, ref, venue),
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

  Widget _filterChip(String label, String value) {
    final isSelected = _filterStatus == value;
    return GestureDetector(
      onTap: () => setState(() => _filterStatus = value),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF4CAF50)
              : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[600],
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Future<void> _handleSuspend(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> venue,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Suspend Venue'),
        content: Text(
          'Are you sure you want to suspend "${venue['name']}"?\n\nOwner will not receive new bookings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Suspend'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final repo = ref.read(adminRepositoryProvider);
      await repo.suspendVenue(venue['id']);
      ref.refresh(allVenuesProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${venue['name']}" suspended ❌'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _handleActivate(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> venue,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Activate Venue'),
        content: Text(
            'Are you sure you want to activate "${venue['name']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Activate'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final repo = ref.read(adminRepositoryProvider);
      await repo.activateVenue(venue['id']);
      ref.refresh(allVenuesProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${venue['name']}" activated ✅'),
            backgroundColor: const Color(0xFF4CAF50),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }
}