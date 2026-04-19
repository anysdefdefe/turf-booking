import 'package:flutter/material.dart';

class VenueTile extends StatelessWidget {
  final Map<String, dynamic> venue;
  final VoidCallback onSuspend;
  final VoidCallback onActivate;

  const VenueTile({
    super.key,
    required this.venue,
    required this.onSuspend,
    required this.onActivate,
  });

  @override
  Widget build(BuildContext context) {
    final bool isActive = venue['is_active'] == true;

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
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.stadium, color: Color(0xFF4CAF50)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  venue['name'] ?? 'Unknown Stadium',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  venue['city'] ?? '',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          isActive
              ? TextButton(
                  onPressed: onSuspend,
                  child: const Text(
                    'Suspend',
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                )
              : TextButton(
                  onPressed: onActivate,
                  child: const Text(
                    'Activate',
                    style: TextStyle(
                        color: Color(0xFF4CAF50), fontSize: 12),
                  ),
                ),
        ],
      ),
    );
  }
}