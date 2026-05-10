import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/admin_provider.dart';

class AdminBookingsScreen extends ConsumerWidget {
  const AdminBookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(allBookingsProvider);
  

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'All Bookings',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: bookingsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
        ),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $e',
                  style: const TextStyle(color: Colors.red)),
              ElevatedButton(
                onPressed: () => ref.refresh(allBookingsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (bookings) => RefreshIndicator(
          color: const Color(0xFF4CAF50),
          onRefresh: () async => ref.refresh(allBookingsProvider),
          child: bookings.isEmpty
              ? const Center(
                  child: Text(
                    'No bookings yet',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: bookings.length,
                  itemBuilder: (context, index) {
                    final booking = bookings[index];
                    return _BookingCard(booking: booking);
                  },
                ),
        ),
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final Map<String, dynamic> booking;

  const _BookingCard({required this.booking});

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Color _paymentColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return Colors.green;
      case 'unpaid':
        return Colors.red;
      case 'refunded':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  /// Format a [DateTime] to a readable 12-hour time string (e.g. "9:00 AM").
  String _formatDateTime(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final suffix = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $suffix';
  }

  /// Fallback: format a raw "HH:mm:ss" or ISO time string.
  String _formatTimeStr(String raw) {
    final dt = DateTime.tryParse('2000-01-01 $raw');
    if (dt == null) {
      final parsed = DateTime.tryParse(raw);
      if (parsed != null) return _formatDateTime(parsed);
      return raw;
    }
    return _formatDateTime(dt);
  }

  @override
  Widget build(BuildContext context) {
    final status = booking['status'] ?? 'unknown';
    final paymentStatus = booking['payment_status'] ?? 'unknown';
    final userName = booking['users']?['full_name'] ?? 'Unknown User';
    final userEmail = booking['users']?['email'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Booking #${booking['id'].toString().substring(0, 8)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor(status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    color: _statusColor(status),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const Divider(height: 20),
             Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: const Color(0xFF4CAF50).withOpacity(0.15),
                  child: Text(
                    userName[0].toUpperCase(),
                    style: const TextStyle(
                      color: Color(0xFF4CAF50),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      userEmail,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ],
            ),

        const SizedBox(height: 10),
          // Details
          _infoRow(Icons.calendar_today_outlined, 'Date', booking['booking_date'] ?? '-'),
          const SizedBox(height: 6),
          // Show slots as chips similar to owner view. If slots are present, list them,
          // otherwise show a single time chip using start/end time.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.access_time_outlined, size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 6),
                    Text(
                      'Time',
                      style: TextStyle(fontSize: 13, color: Colors.grey[700], fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Builder(builder: (_) {
                  final slots = booking['slots'];
                  if (slots is List && slots.isNotEmpty) {
                    return Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: slots.map<Widget>((s) {
                        final st = s['start_time']?.toString() ?? booking['start_time']?.toString() ?? '';
                        final et = s['end_time']?.toString() ?? booking['end_time']?.toString() ?? '';
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FFF4),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.2)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.access_time_outlined, size: 12, color: Color(0xFF4CAF50)),
                              const SizedBox(width: 6),
                              Text(
                                '${_formatTimeStr(st)} – ${_formatTimeStr(et)}',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF2E7D32)),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  }

                  // fallback single range styled as a chip
                  final st = booking['start_time']?.toString() ?? '';
                  final et = booking['end_time']?.toString() ?? '';
                  return Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FFF4),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.access_time_outlined, size: 12, color: Color(0xFF4CAF50)),
                            const SizedBox(width: 6),
                            Text(
                              '${_formatTimeStr(st)} – ${_formatTimeStr(et)}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF2E7D32)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 6),
          _infoRow(Icons.currency_rupee,
              'Amount', '₹${booking['total_amount']}'),

          const SizedBox(height: 10),

          // Payment status
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _paymentColor(paymentStatus).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _paymentColor(paymentStatus).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.payment,
                      size: 13,
                      color: _paymentColor(paymentStatus),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      paymentStatus.toUpperCase(),
                      style: TextStyle(
                        color: _paymentColor(paymentStatus),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey[500]),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
        ),
        Text(
          value,
          style: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}