import 'package:flutter/material.dart';
import '../data/repositories/admin_repository.dart';
import '../widgets/venue_tile.dart';

class AdminVenuesScreen extends StatefulWidget {
  const AdminVenuesScreen({super.key});

  @override
  State<AdminVenuesScreen> createState() => _AdminVenuesScreenState();
}

class _AdminVenuesScreenState extends State<AdminVenuesScreen> {
 final AdminRepository _repo = AdminRepository.instance;
  List<Map<String, dynamic>> _venues = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await _repo.getAllVenues();
    setState(() {
      _venues = data;
      _isLoading = false;
    });
  }

  Future<void> _suspend(String venueId) async {
    await _repo.suspendVenue(venueId);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Venue suspended'), backgroundColor: Colors.orange),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Manage Venues',
          style: TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF4CAF50)))
          : RefreshIndicator(
              color: const Color(0xFF4CAF50),
              onRefresh: _load,
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: _venues.length,
                itemBuilder: (context, index) {
                  return VenueTile(
                    venue: _venues[index],
                    onSuspend: () => _suspend(_venues[index]['id']),
                  );
                },
              ),
            ),
    );
  }
}