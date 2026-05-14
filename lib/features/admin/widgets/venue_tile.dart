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
    final cs = Theme.of(context).colorScheme;
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
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive ? Colors.transparent : cs.error.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
                      ? cs.primary.withValues(alpha: 0.1)
                      : cs.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.stadium,
                  color: isActive ? cs.primary : cs.error,
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
                      style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isActive
                      ? cs.primary.withValues(alpha: 0.1)
                      : cs.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isActive ? 'Active' : 'Suspended',
                  style: TextStyle(
                    color: isActive ? cs.primary : cs.error,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const Divider(height: 20),

          // Details
          _infoRow(context, Icons.location_on_outlined, address),
          const SizedBox(height: 6),
          _infoRow(context, Icons.calendar_today_outlined, 'Added: $createdAt'),

          if (description.isNotEmpty) ...[
            const SizedBox(height: 6),
            _infoRow(
              context,
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
                      foregroundColor: cs.error,
                      side: BorderSide(color: cs.error),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  )
                : ElevatedButton.icon(
                    onPressed: onActivate,
                    icon: const Icon(Icons.check_circle_outline, size: 16),
                    label: const Text('Activate Venue'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cs.primary,
                      foregroundColor: cs.onPrimary,
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

  Widget _infoRow(BuildContext context, IconData icon, String value) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 14, color: cs.onSurfaceVariant),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
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
