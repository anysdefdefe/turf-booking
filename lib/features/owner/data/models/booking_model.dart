/// A single 1-hour slot row from the `slots` table.
class SlotModel {
  final String id;
  final DateTime startTime; // stored as timestamp in the slots table
  final DateTime endTime;
  final String status;

  const SlotModel({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.status,
  });

  factory SlotModel.fromJson(Map<String, dynamic> json) {
    return SlotModel(
      id: json['id'] as String,
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: DateTime.parse(json['end_time'] as String),
      status: json['status'] as String,
    );
  }
}

class BookingModel {
  final String id;
  final String courtId;
  final String customerId;
  final String bookingDate; // YYYY-MM-DD
  final String startTime;   // HH:mm:ss  (overall booking range start)
  final String endTime;     // HH:mm:ss  (overall booking range end)
  final int durationHours;
  final double totalAmount;
  final String status;
  final String paymentStatus;
  final DateTime createdAt;

  // Joined fields populated from Supabase selects
  final String? customerName;
  final String? customerPhone;
  final String? courtName;
  final String? stadiumName;

  /// Individual 1-hour slots belonging to this booking (from `slots` table).
  /// Sorted ascending by start_time so we can display them in order.
  final List<SlotModel> slots;

  const BookingModel({
    required this.id,
    required this.courtId,
    required this.customerId,
    required this.bookingDate,
    required this.startTime,
    required this.endTime,
    required this.durationHours,
    required this.totalAmount,
    required this.status,
    required this.paymentStatus,
    required this.createdAt,
    this.customerName,
    this.customerPhone,
    this.courtName,
    this.stadiumName,
    this.slots = const [],
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    String? customerName;
    String? customerPhone;
    if (json['customer'] != null && json['customer'] is Map) {
      customerName = json['customer']['full_name'] as String?;
      customerPhone = json['customer']['phone'] as String?;
    }

    String? courtName;
    String? stadiumName;
    if (json['courts'] != null && json['courts'] is Map) {
      courtName = json['courts']['name'] as String?;
      if (json['courts']['stadium'] != null && json['courts']['stadium'] is Map) {
        stadiumName = json['courts']['stadium']['name'] as String?;
      }
    }

    // Parse the nested slots rows (may be absent or empty).
    List<SlotModel> slots = [];
    if (json['slots'] != null && json['slots'] is List) {
      slots = (json['slots'] as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .map(SlotModel.fromJson)
          .toList()
        ..sort((a, b) => a.startTime.compareTo(b.startTime));
    }

    return BookingModel(
      id: json['id'] as String,
      courtId: json['court_id'] as String,
      customerId: json['customer_id'] as String,
      bookingDate: json['booking_date'] as String,
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String,
      durationHours: (json['duration_hours'] as num).toInt(),
      totalAmount: (json['total_amount'] as num).toDouble(),
      status: json['status'] as String,
      paymentStatus: json['payment_status'] as String,
      createdAt: json['created_at'] is String
          ? DateTime.parse(json['created_at'])
          : json['created_at'] as DateTime,
      customerName: customerName,
      customerPhone: customerPhone,
      courtName: courtName,
      stadiumName: stadiumName,
      slots: slots,
    );
  }
}
