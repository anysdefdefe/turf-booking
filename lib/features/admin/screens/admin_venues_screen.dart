import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/admin_provider.dart';
import '../widgets/venue_tile.dart';

class AdminVenuesScreen extends ConsumerWidget {
  const AdminVenuesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
      body: venuesAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
        ),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $e', style: const TextStyle(color: Colors.red)),
              ElevatedButton(
                onPressed: () => ref.refresh(allVenuesProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (venues) => RefreshIndicator(
          color: const Color(0xFF4CAF50),
          onRefresh: () async => ref.refresh(allVenuesProvider),
          child: ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: venues.length,
            itemBuilder: (context, index) {
              return VenueTile(
                venue: venues[index],
                onSuspend: () async {
                  final repo = ref.read(adminRepositoryProvider);
                  await repo.suspendVenue(venues[index]['id']);
                  ref.refresh(allVenuesProvider);
                },
                onActivate: () async {
                  final repo = ref.read(adminRepositoryProvider);
                  await repo.activateVenue(venues[index]['id']);
                  ref.refresh(allVenuesProvider);
                },
              );
            },
          ),
        ),
      ),
    );
  }
}