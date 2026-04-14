import 'package:flutter/material.dart';
import '../data/repositories/admin_repository.dart';
import '../widgets/user_tile.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
 final AdminRepository _repo = AdminRepository.instance;
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await _repo.getAllUsers();
    setState(() {
      _users = data;
      _isLoading = false;
    });
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
          'Manage Users',
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
                itemCount: _users.length,
                itemBuilder: (context, index) {
                  return UserTile(
                    user: _users[index],
                    onBlock: () async {
                      await _repo.blockUser(_users[index]['id']);
                      _load();
                    },
                    onUnblock: () async {
                      await _repo.unblockUser(_users[index]['id']);
                      _load();
                    },
                  );
                },
              ),
            ),
    );
  }
}