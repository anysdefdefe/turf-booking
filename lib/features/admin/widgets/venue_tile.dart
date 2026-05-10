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
    final name = venue['name'] ?? 'Unknown Stadium';
    final city = venue['city'] ?? 'Unknown City';
    final address = venue['address'] ?? 'No address';
    final description = venue['description'] ?? '';
    final createdAt = venue['created_at'] != null
        ? _formatDate(venue['created_at'])
        : 'Unknown';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive
              ? Colors.transparent
              : Colors.red.withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFF4CAF50).withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.stadium,
                  color: isActive
                      ? const Color(0xFF4CAF50)
                      : Colors.red,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      city,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isActive
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isActive ? 'Active' : 'Suspended',
                  style: TextStyle(
                    color: isActive ? Colors.green : Colors.red,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const Divider(height: 20),

          // Details
          _infoRow(Icons.location_on_outlined, address),
          const SizedBox(height: 6),
          _infoRow(Icons.calendar_today_outlined, 'Added: $createdAt'),

          if (description.isNotEmpty) ...[
            const SizedBox(height: 6),
            _infoRow(
              Icons.info_outline,
              description.length > 60
                  ? '${description.substring(0, 60)}...'
                  : description,
            ),
          ],

          const SizedBox(height: 12),

          // Action Button
          SizedBox(
            width: double.infinity,
            child: isActive
                ? OutlinedButton.icon(
                    onPressed: onSuspend,
                    icon: const Icon(Icons.block, size: 16),
                    label: const Text('Suspend Venue'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  )
                : ElevatedButton.icon(
                    onPressed: onActivate,
                    icon: const Icon(Icons.check_circle_outline,
                        size: 16),
                    label: const Text('Activate Venue'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey[400]),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Unknown';
    }
  }
}