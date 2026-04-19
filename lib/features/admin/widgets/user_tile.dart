import 'package:flutter/material.dart';

class UserTile extends StatelessWidget {
  final Map<String, dynamic> user;
  final VoidCallback onBlock;
  final VoidCallback onUnblock;

  const UserTile({
    super.key,
    required this.user,
    required this.onBlock,
    required this.onUnblock,
  });

  @override
  Widget build(BuildContext context) {
    final bool isBlocked = user['is_blocked'] == true;
        final name = user['full_name'] ?? 'User';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFF4CAF50).withOpacity(0.15),
            child: Text(
              name[0].toUpperCase(),
              style: const TextStyle(
                color: Color(0xFF4CAF50),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user['full_name'] ?? 'Unknown',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  user['email'] ?? '',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: isBlocked ? onUnblock : onBlock,
            child: Text(
              isBlocked ? 'Unblock' : 'Block',
              style: TextStyle(
                color: isBlocked ? const Color(0xFF4CAF50) : Colors.red,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}