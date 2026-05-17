import 'court_model.dart';

enum BookingStatus { booked, unpaid, cancelled }

class CustomerBooking {
  final String id;
  final Court court;
  final BookingStatus status;
  final DateTime date;
  final DateTime? createdAt;
  final List<String> slots;
  final String courtType;
  final DateTime? cancelledAt;
  final int? bookedSlotCount;
  final String? firstSlotLabel;
  final double? dbTotalAmount;

  const CustomerBooking({
    required this.id,
    required this.court,
    required this.status,
    required this.date,
    required this.createdAt,
    required this.slots,
    required this.courtType,
    this.cancelledAt,
    this.bookedSlotCount,
    this.firstSlotLabel,
    this.dbTotalAmount,
  });

  int get durationHours => bookedSlotCount ?? slots.length;

  DateTime get createdAtDisplay => createdAt ?? date;

  String get primarySlot =>
      slots.isNotEmpty ? slots.first : (firstSlotLabel ?? '');

  List<String> get displaySlots => slots.isNotEmpty
      ? slots
      : (primarySlot.isEmpty ? const [] : [primarySlot]);

  DateTime get startDateTime => _slotToDateTime(primarySlot);

  DateTime get endDateTime => startDateTime.add(
    Duration(hours: durationHours == 0 ? 1 : durationHours),
  );

  bool get isPast => endDateTime.isBefore(DateTime.now());

  bool get canCancel =>
      (status == BookingStatus.booked || status == BookingStatus.unpaid) &&
      !isPast;

  double get totalAmount =>
      dbTotalAmount ?? (court.pricePerHour * durationHours);

  CustomerBooking copyWith({
    BookingStatus? status,
    DateTime? cancelledAt,
    int? bookedSlotCountOverride,
    String? firstSlotLabelOverride,
    double? dbTotalAmountOverride,
  }) {
    return CustomerBooking(
      id: id,
      court: court,
      status: status ?? this.status,
      date: date,
      createdAt: createdAt,
      slots: slots,
      courtType: courtType,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      bookedSlotCount: bookedSlotCountOverride ?? bookedSlotCount,
      firstSlotLabel: firstSlotLabelOverride ?? firstSlotLabel,
      dbTotalAmount: dbTotalAmountOverride ?? dbTotalAmount,
    );
  }

  DateTime _slotToDateTime(String slot) {
    if (slot.isEmpty) {
      return DateTime(date.year, date.month, date.day);
    }

    final parts = slot.split(' ');
    if (parts.length != 2) {
      return DateTime(date.year, date.month, date.day);
    }

    final hm = parts[0].split(':');
    if (hm.length != 2) {
      return DateTime(date.year, date.month, date.day);
    }

    final hourRaw = int.tryParse(hm[0]) ?? 0;
    final minute = int.tryParse(hm[1]) ?? 0;
    final meridiem = parts[1].toUpperCase();

    var hour = hourRaw % 12;
    if (meridiem == 'PM') {
      hour += 12;
    }

    return DateTime(date.year, date.month, date.day, hour, minute);
  }
}
