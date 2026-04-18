import 'package:flutter/material.dart';
import '../../../app/constants/app_constants.dart';
import '../../../app/theme/app_colors.dart';
import '../data/models/booking_args.dart';
import '../data/models/court_detail_args.dart';
import '../data/models/court_model.dart';
import '../data/models/customer_booking.dart';
import '../data/repositories/customer_booking_repository.dart';
import '../data/repositories/customer_preferences_repository.dart';
import '../data/repositories/court_repository.dart';
import '../widgets/detail_section_title.dart';
import '../widgets/info_row_chip.dart';
import '../widgets/sport_icon_mapper.dart';

class CourtDetailScreen extends StatefulWidget {
  const CourtDetailScreen({super.key});

  @override
  State<CourtDetailScreen> createState() => _CourtDetailScreenState();
}

class _CourtDetailScreenState extends State<CourtDetailScreen> {
  final CourtRepository _repo = CourtRepository.instance;
  final CustomerBookingRepository _bookingRepo =
      CustomerBookingRepository.instance;

  bool _initialized = false;
  List<Court> _stadiumCourts = [];
  int _activeCourtIndex = 0;
  int _dateStartOffset = 0;

  DateTime? _selectedDate;
  String? _selectedType;
  final Set<String> _selectedSlots = <String>{};

  final List<String> _timeSlots = [
    '06:00 AM',
    '07:00 AM',
    '08:00 AM',
    '09:00 AM',
    '10:00 AM',
    '11:00 AM',
    '12:00 PM',
    '01:00 PM',
    '02:00 PM',
    '03:00 PM',
    '04:00 PM',
    '05:00 PM',
    '06:00 PM',
    '07:00 PM',
    '08:00 PM',
    '09:00 PM',
  ];

  bool get _canBook =>
      _selectedDate != null &&
      _selectedSlots.isNotEmpty &&
      _selectedType != null;

  int get _selectedHours => _selectedSlots.length;

  Court get _currentCourt => _stadiumCourts[_activeCourtIndex];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }

    final routeArgs = ModalRoute.of(context)?.settings.arguments;
    if (routeArgs is CourtDetailArgs) {
      final siblings = routeArgs.stadiumCourts.isEmpty
          ? _repo.getCourtsByStadium(routeArgs.selectedCourt.stadiumId)
          : routeArgs.stadiumCourts;
      _stadiumCourts = siblings;
      _activeCourtIndex = _indexOfCourtId(routeArgs.selectedCourt.id, siblings);
      _selectedType = routeArgs.selectedCourt.courtTypes.isNotEmpty
          ? routeArgs.selectedCourt.courtTypes.first
          : null;
    } else if (routeArgs is Court) {
      final siblings = _repo.getCourtsByStadium(routeArgs.stadiumId);
      _stadiumCourts = siblings.isEmpty ? [routeArgs] : siblings;
      _activeCourtIndex = _indexOfCourtId(routeArgs.id, _stadiumCourts);
      _selectedType = routeArgs.courtTypes.isNotEmpty
          ? routeArgs.courtTypes.first
          : null;
    }

    _selectedDate = _stripDate(DateTime.now());

    _initialized = true;
  }

  int _indexOfCourtId(String courtId, List<Court> courts) {
    final index = courts.indexWhere((court) => court.id == courtId);
    return index < 0 ? 0 : index;
  }

  void _switchCourtByDelta(int delta) {
    if (_stadiumCourts.length < 2) {
      return;
    }
    final nextIndex = (_activeCourtIndex + delta).clamp(
      0,
      _stadiumCourts.length - 1,
    );
    if (nextIndex == _activeCourtIndex) {
      return;
    }

    setState(() {
      _activeCourtIndex = nextIndex;
      _selectedType = _currentCourt.courtTypes.isNotEmpty
          ? _currentCourt.courtTypes.first
          : null;
      _selectedSlots.clear();
      _selectedDate = _stripDate(DateTime.now());
    });
  }

  DateTime _stripDate(DateTime d) => DateTime(d.year, d.month, d.day);

  List<DateTime> get _dateOptions {
    final base = _stripDate(DateTime.now());
    return List<DateTime>.generate(
      8,
      (index) => base.add(Duration(days: _dateStartOffset + index)),
    );
  }

  void _shiftDateWindow(int delta) {
    final nextOffset = _dateStartOffset + delta;
    if (nextOffset < 0) {
      return;
    }
    setState(() => _dateStartOffset = nextOffset);
  }

  bool _isSameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Set<String> _bookedSlotsForDate(DateTime date) {
    final blocked = <String>{};
    final selectedCourtId = _currentCourt.id;
    final now = DateTime.now();
    for (final booking in _bookingRepo.getAllBookings()) {
      if (booking.court.id != selectedCourtId ||
          booking.status != BookingStatus.booked ||
          !_isSameDate(booking.date, date)) {
        continue;
      }
      blocked.addAll(booking.slots);
    }

    if (_isSameDate(date, now)) {
      for (final slot in _timeSlots) {
        final slotDateTime = _slotDateTime(date, slot);
        if (!slotDateTime.isAfter(now)) {
          blocked.add(slot);
        }
      }
    }

    blocked.add(_timeSlots.first);
    return blocked;
  }

  DateTime _slotDateTime(DateTime date, String slot) {
    final parts = slot.split(' ');
    if (parts.length != 2) {
      return date;
    }

    final timeParts = parts[0].split(':');
    if (timeParts.length != 2) {
      return date;
    }

    final hourRaw = int.tryParse(timeParts[0]) ?? 0;
    final minute = int.tryParse(timeParts[1]) ?? 0;
    var hour = hourRaw % 12;
    if (parts[1].toUpperCase() == 'PM') {
      hour += 12;
    }

    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  bool _isBooked(String slot) {
    final date = _selectedDate;
    if (date == null) {
      return false;
    }
    return _bookedSlotsForDate(date).contains(slot);
  }

  void _toggleSlot(String slot) {
    if (_isBooked(slot)) {
      return;
    }
    setState(() {
      if (_selectedSlots.contains(slot)) {
        _selectedSlots.remove(slot);
      } else {
        _selectedSlots.add(slot);
      }
    });
  }

  List<String> _orderedSelectedSlots() {
    final slots = _selectedSlots.toList();
    slots.sort(
      (a, b) => _timeSlots.indexOf(a).compareTo(_timeSlots.indexOf(b)),
    );
    return slots;
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized || _stadiumCourts.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Court Details'),
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
        ),
        body: const Center(
          child: Text(
            'Court details are unavailable.',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    final court = _currentCourt;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context, court),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(court),
                _divider(),
                _buildAbout(court),
                _divider(),
                _buildAmenities(court),
                _divider(),
                _buildDatePicker(),
                _divider(),
                _buildTypePicker(court),
                _divider(),
                _buildTimeSlotPicker(),
                const SizedBox(height: 110),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(context, court),
    );
  }

  // ── App Bar ───────────────────────────────────────────────────────────────

  SliverAppBar _buildAppBar(BuildContext context, Court court) {
    return SliverAppBar(
      expandedHeight: 290,
      pinned: true,
      stretch: true,
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      leading: Padding(
        padding: const EdgeInsets.only(left: 10, top: 10, bottom: 10),
        child: _CircleBtn(
          icon: Icons.arrow_back_ios_new_rounded,
          onTap: () => Navigator.of(context).maybePop(),
          iconSize: 12,
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.all(10),
          child: _CircleBtn(icon: Icons.share_rounded, onTap: () {}, iconSize: 12),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 10, top: 10, bottom: 10),
          child: _FavBtn(courtId: court.id),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: Stack(
          fit: StackFit.expand,
          children: [
            GestureDetector(
              onHorizontalDragEnd: (details) {
                final velocity = details.primaryVelocity ?? 0;
                if (velocity < -100) {
                  _switchCourtByDelta(1);
                } else if (velocity > 100) {
                  _switchCourtByDelta(-1);
                }
              },
              child: Image.network(
                court.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  color: AppColors.divider,
                  child: const Icon(
                    Icons.sports_tennis_rounded,
                    size: 72,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.5, 1.0],
                  colors: [Colors.transparent, Colors.black54],
                ),
              ),
            ),
            Positioned(
              bottom: 14,
              left: 16,
              child: Row(
                children: [
                  if (_stadiumCourts.length > 1)
                    _SwitchCourtBtn(
                      icon: Icons.chevron_left_rounded,
                      onTap: () => _switchCourtByDelta(-1),
                    ),
                ],
              ),
            ),
            Positioned(
              bottom: 14,
              right: 16,
              child: Row(
                children: [
                  if (_stadiumCourts.length > 1)
                    _SwitchCourtBtn(
                      icon: Icons.chevron_right_rounded,
                      onTap: () => _switchCourtByDelta(1),
                    ),
                  if (_stadiumCourts.length > 1) const SizedBox(width: 8),
                  _DistBadge(km: court.distanceKm),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader(Court court) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  court.name,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    height: 1.2,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${court.pricePerHour.toInt()}',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                  const Text(
                    'per hour',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.stadium_rounded,
                size: 14,
                color: AppColors.primary,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  court.stadiumName,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (_stadiumCourts.length > 1)
                Text(
                  'Court ${_activeCourtIndex + 1} of ${_stadiumCourts.length}',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.location_on_rounded,
                size: 14,
                color: AppColors.primary,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${court.place}, ${court.city}',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              InfoRowChip(
                icon: Icons.star_rounded,
                label: '${court.rating}  (${court.reviewCount} reviews)',
                color: AppColors.star,
              ),
              InfoRowChip(
                icon: Icons.access_time_rounded,
                label: '${court.openTime} – ${court.closeTime}',
                color: AppColors.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── About ─────────────────────────────────────────────────────────────────

  Widget _buildAbout(Court court) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const DetailSectionTitle(title: 'About'),
          const SizedBox(height: 10),
          Text(
            court.description,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13.5,
              color: AppColors.textSecondary,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }

  // ── Amenities ─────────────────────────────────────────────────────────────

  Widget _buildAmenities(Court court) {
    IconData iconForAmenity(String amenity) {
      final key = amenity.toLowerCase();
      if (key.contains('water')) return Icons.local_drink_outlined;
      if (key.contains('flood') || key.contains('light')) {
        return Icons.wb_sunny_outlined;
      }
      if (key.contains('park')) return Icons.local_parking_outlined;
      if (key.contains('washroom')) return Icons.wc_outlined;
      if (key.contains('changing')) return Icons.checkroom_outlined;
      if (key.contains('shower')) return Icons.shower_outlined;
      if (key.contains('cafeteria') || key.contains('canteen')) {
        return Icons.restaurant_outlined;
      }
      if (key.contains('equipment')) return Icons.sports_tennis_outlined;
      if (key.contains('ac')) return Icons.ac_unit_outlined;
      return Icons.check_circle_outline_rounded;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const DetailSectionTitle(title: 'Amenities'),
          const SizedBox(height: 12),
          ...court.amenities.map(
            (amenity) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      amenity,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Icon(
                    iconForAmenity(amenity),
                    size: 17,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Date Picker ───────────────────────────────────────────────────────────

  Widget _buildDatePicker() {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final monthLabel = _selectedDate == null
        ? ''
        : '${_monthName(_selectedDate!.month)} ${_selectedDate!.year}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton.filledTonal(
                onPressed: _dateStartOffset > 0
                    ? () => _shiftDateWindow(-4)
                    : null,
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              const Spacer(),
              Text(
                monthLabel,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              IconButton.filledTonal(
                onPressed: () => _shiftDateWindow(4),
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 64,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _dateOptions.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, index) {
                final date = _dateOptions[index];
                final selected =
                    _selectedDate != null && _isSameDate(_selectedDate!, date);
                final today = _stripDate(DateTime.now());
                final label = _isSameDate(date, today)
                    ? 'Today'
                    : weekdays[date.weekday - 1];
                return GestureDetector(
                  onTap: () => setState(() {
                    _selectedDate = date;
                    _selectedSlots.removeWhere((slot) => _isBooked(slot));
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 52,
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primary : AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: selected ? AppColors.primary : AppColors.divider,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: selected
                                ? Colors.white.withValues(alpha: 0.9)
                                : AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${date.day}',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                            height: 0.9,
                            color: selected
                                ? Colors.white
                                : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _monthName(int month) {
    const names = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return names[month - 1];
  }

  // ── Time Slot Picker ──────────────────────────────────────────────────────

  Widget _buildTimeSlotPicker() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              DetailSectionTitle(title: 'Select Time Slots'),
              Spacer(),
              Text(
                '1 hr each',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              _SlotLegend(
                label: 'Available',
                color: AppColors.surface,
                outlined: true,
              ),
              SizedBox(width: 12),
              _SlotLegend(label: 'Selected', color: AppColors.primary),
              SizedBox(width: 12),
              _SlotLegend(label: 'Booked', color: Color(0xFFE7E8EC)),
            ],
          ),
          const SizedBox(height: 16),
          _buildSlotSection(
            title: 'MORNING',
            icon: Icons.wb_sunny_outlined,
            slots: _timeSlots.sublist(0, 6),
          ),
          const SizedBox(height: 14),
          _buildSlotSection(
            title: 'AFTERNOON',
            icon: Icons.wb_twilight_outlined,
            slots: _timeSlots.sublist(6, 12),
          ),
          const SizedBox(height: 14),
          _buildSlotSection(
            title: 'EVENING',
            icon: Icons.nightlight_round,
            slots: _timeSlots.sublist(12, _timeSlots.length),
          ),
        ],
      ),
    );
  }

  Widget _buildSlotSection({
    required String title,
    required IconData icon,
    required List<String> slots,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (_, constraints) {
            const gap = 8.0;
            final width = (constraints.maxWidth - (gap * 2)) / 3;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: slots
                  .map(
                    (slot) =>
                        SizedBox(width: width, child: _buildSlotTile(slot)),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSlotTile(String slot) {
    final booked = _isBooked(slot);
    final selected = _selectedSlots.contains(slot);
    final background = selected
        ? AppColors.primary
        : booked
        ? const Color(0xFFE7E8EC)
        : AppColors.surface;
    final borderColor = selected || !booked
        ? AppColors.primary
        : const Color(0xFFE7E8EC);
    final textColor = selected
        ? Colors.white
        : booked
        ? const Color(0xFF8F93A3)
        : AppColors.primaryDark;

    return GestureDetector(
      onTap: booked ? null : () => _toggleSlot(slot),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        height: 42,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: borderColor, width: booked ? 1 : 1.1),
        ),
        alignment: Alignment.center,
        child: Text(
          slot,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: textColor,
            decoration: booked ? TextDecoration.lineThrough : null,
            decorationColor: const Color(0xFF8F93A3),
          ),
        ),
      ),
    );
  }

  // ── Court Type ────────────────────────────────────────────────────────────

  Widget _buildTypePicker(Court court) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const DetailSectionTitle(title: 'Sport Type'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: court.courtTypes.map((type) {
              final sel = _selectedType == type;
              return GestureDetector(
                onTap: () => setState(() => _selectedType = type),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: sel
                        ? const Color(0xFFE8FFF5)
                        : const Color(0xFFF6F7FA),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: sel ? AppColors.primary : AppColors.divider,
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        sportIconForName(type),
                        size: 16,
                        color: sel
                            ? AppColors.primaryDark
                            : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 7),
                      Text(
                        type,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: sel
                              ? AppColors.primaryDark
                              : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── Bottom Bar ────────────────────────────────────────────────────────────

  Widget _buildBottomBar(BuildContext context, Court court) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        14,
        20,
        MediaQuery.of(context).padding.bottom + 14,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(
          top: BorderSide(color: AppColors.divider, width: 1),
        ),
      ),
      child: Row(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total Price (${_selectedHours} hr${_selectedHours == 1 ? '' : 's'})',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 9,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '₹${(court.pricePerHour * _selectedHours).toInt()}',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  height: 0.95,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton.icon(
              onPressed: _canBook
                  ? () => Navigator.pushNamed(
                      context,
                      AppConstants.routeBookingConfirm,
                      arguments: BookingArgs(
                        court: court,
                        date: _selectedDate!,
                        slots: _orderedSelectedSlots(),
                        courtType: _selectedType!,
                      ),
                    )
                  : null,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: AppColors.divider,
              ),
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              label: Text(
                _canBook ? 'Proceed to Book' : 'Select Date, Sport & Slots',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => const Divider(
    color: AppColors.divider,
    height: 1,
    indent: 20,
    endIndent: 20,
  );
}

class _SlotLegend extends StatelessWidget {
  final String label;
  final Color color;
  final bool outlined;

  const _SlotLegend({
    required this.label,
    required this.color,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 11,
          height: 11,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
            border: outlined
                ? Border.all(color: AppColors.primary, width: 1)
                : null,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

// ── Reusable sub-widgets ──────────────────────────────────────────────────────

class _SwitchCourtBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _SwitchCourtBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.94),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.divider, width: 1),
        ),
        child: Icon(icon, size: 16, color: AppColors.textPrimary),
      ),
    );
  }
}

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double iconSize;
  const _CircleBtn({required this.icon, required this.onTap,  this.iconSize = 12});


  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: AppColors.surface,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.divider, width: 1),
      ),
      child: Icon(icon, size: iconSize, color: AppColors.textPrimary),
    ),
  );
}

class _FavBtn extends StatelessWidget {
  final String courtId;

  const _FavBtn({required this.courtId});

  @override
  Widget build(BuildContext context) {
    final prefs = CustomerPreferencesRepository.instance;
    return ValueListenableBuilder<Set<String>>(
      valueListenable: prefs.likedCourtIds,
      builder: (context, likedIds, _) {
        final isLiked = likedIds.contains(courtId);
        return GestureDetector(
          onTap: () => prefs.toggleLike(courtId),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: isLiked ? Colors.red.shade50 : AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(
                color: isLiked ? Colors.red.shade200 : AppColors.divider,
                width: 1,
              ),
            ),
            child: Icon(
              isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              size: 16,
              color: isLiked ? Colors.red : AppColors.textPrimary,
            ),
          ),
        );
      },
    );
  }
}

class _DistBadge extends StatelessWidget {
  final double km;
  const _DistBadge({required this.km});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: AppColors.surface.withValues(alpha: 0.94),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.divider, width: 1),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.near_me_rounded,
          color: AppColors.textSecondary,
          size: 11,
        ),
        const SizedBox(width: 4),
        Text(
          '${km.toStringAsFixed(1)} km',
          style: const TextStyle(
            fontFamily: 'Poppins',
            color: AppColors.textSecondary,
            fontSize: 10.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );
}
