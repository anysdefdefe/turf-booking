import 'package:flutter/material.dart';
import '../data/models/pending_owner_model.dart';
import '../data/repositories/admin_repository.dart';
import '../widgets/approval_card.dart';

class AdminApprovalsScreen extends StatefulWidget {
  const AdminApprovalsScreen({super.key});

  @override
  State<AdminApprovalsScreen> createState() => _AdminApprovalsScreenState();
}

class _AdminApprovalsScreenState extends State<AdminApprovalsScreen> {
final AdminRepository _repo = AdminRepository.instance;
  List<PendingOwnerModel> _pending = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await _repo.getPendingOwners();
    setState(() {
      _pending = data;
      _isLoading = false;
    });
  }

  Future<void> _approve(String id) async {
    await _repo.approveOwner(id);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Owner approved ✅'), backgroundColor: Color(0xFF4CAF50)),
    );
    _load();
  }

  Future<void> _reject(String id) async {
    await _repo.rejectOwner(id, 'Does not meet requirements');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Owner rejected ❌'), backgroundColor: Colors.red),
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
        title: const Text(
          'Pending Approvals',
          style: TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.bold),
        ),
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF4CAF50)))
          : _pending.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline, size: 64, color: Color(0xFF4CAF50)),
                      SizedBox(height: 16),
                      Text('All caught up!', style: TextStyle(fontSize: 16, color: Colors.grey)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: const Color(0xFF4CAF50),
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _pending.length,
                    itemBuilder: (context, index) {
                      final owner = _pending[index];
                      return ApprovalCard(
                        owner: owner,
                        onApprove: () => _approve(owner.id),
                        onReject: () => _reject(owner.id),
                      );
                    },
                  ),
                ),
    );
  }
}