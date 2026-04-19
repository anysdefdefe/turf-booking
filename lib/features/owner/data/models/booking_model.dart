class BookingModel {
  final String id;
  final String courtId;
  final String customerId;
  final String bookingDate; // YYYY-MM-DD
  final String startTime;   // HH:mm:ss
  final String endTime;     // HH:mm:ss
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
    );
  }
}
