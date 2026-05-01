import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/constants/app_constants.dart';
import '../../../app/theme/app_colors.dart';
import 'package:turf_booking/features/owner/widgets/storage_media.dart';
import 'package:turf_booking/features/owner/data/repositories/stadium_repository.dart';
import '../data/models/booking_cart_item.dart';
import '../data/models/court_detail_args.dart';
import '../data/models/court_model.dart';
import '../data/repositories/customer_cart_repository.dart';
import '../data/repositories/court_repository.dart';
import '../widgets/detail_section_title.dart';
import '../widgets/info_row_chip.dart';

class CourtDetailScreen extends StatefulWidget {
  final Object? initialArgs;

  const CourtDetailScreen({super.key, this.initialArgs});

  @override
  State<CourtDetailScreen> createState() => _CourtDetailScreenState();
}

class _CourtDetailScreenState extends State<CourtDetailScreen> {
  final CourtRepository _repo = CourtRepository.instance;
  final CustomerCartRepository _cartRepo = CustomerCartRepository.instance;

  bool _initialized = false;
  Court? _court;
  int _dateStartOffset = 0;

  DateTime? _selectedDate;
  List<String> _timeSlots = const [];
  Set<String> _bookedSlots = const <String>{};
  bool _isLoadingBookedSlots = false;
  final Set<String> _selectedSlots = <String>{};

  bool get _canBook => _selectedDate != null && _selectedSlots.isNotEmpty;

  int get _selectedHours => _selectedSlots.length;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }

    final routeArgs =
        widget.initialArgs ?? ModalRoute.of(context)?.settings.arguments;
    if (routeArgs is CourtDetailArgs) {
      _court = routeArgs.selectedCourt;
    } else if (routeArgs is Court) {
      _court = routeArgs;
    }

    if (_court == null) {
      _initialized = true;
      return;
    }

    _selectedDate = _stripDate(DateTime.now());
    _timeSlots = _repo.generateHourlySlots(_court!);
    _refreshBookedSlots();

    _initialized = true;
  }

  Future<void> _refreshBookedSlots() async {
    final selectedDate = _selectedDate;
    if (selectedDate == null) {
      return;
    }

    setState(() => _isLoadingBookedSlots = true);
    final booked = await _repo.getBookedSlotsForDate(
      courtId: _court!.id,
      date: selectedDate,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _bookedSlots = booked.toSet();
      _selectedSlots.removeWhere((slot) => _bookedSlots.contains(slot));
      _isLoadingBookedSlots = false;
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
    if (_bookedSlots.contains(slot)) {
      return true;
    }

    if (_isSameDate(date, DateTime.now())) {
      final slotDateTime = _slotDateTime(date, slot);
      return !slotDateTime.isAfter(DateTime.now());
    }

    return false;
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
    if (!_initialized || _court == null) {
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

    final court = _court!;
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 340,
            child: Stack(
              fit: StackFit.expand,
              children: [
                StorageImage(
                  storagePath: court.imageUrl,
                  bucketName: StadiumRepository.imageBucket,
                  width: double.infinity,
                  height: 340,
                  fit: BoxFit.cover,
                  borderRadius: BorderRadius.zero,
                  placeholder: Container(
                    color: AppColors.divider,
                    child: const Icon(
                      Icons.sports_tennis_rounded,
                      size: 72,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: [0.0, 0.4],
                      colors: [Colors.black45, Colors.transparent],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned.fill(
            child: CustomScrollView(
              slivers: [
                const SliverToBoxAdapter(child: SizedBox(height: 290)),
                SliverToBoxAdapter(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 32),
                        _buildHeader(court),
                        _buildAbout(court),
                        _buildEquipments(court),
                        _buildDatePicker(),
                        _buildTimeSlotPicker(),
                        const SizedBox(height: 110),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 20,
            child: _CircleBtn(
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: () => Navigator.of(context).maybePop(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(context, court),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader(Court court) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
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
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    height: 1.1,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.divider.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.currency_rupee_rounded,
                      size: 14,
                      color: AppColors.textPrimary,
                    ),
                    Text(
                      '${court.pricePerHour.toInt()}',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.stadium_rounded,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  court.stadiumName,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSkeletalStat('Timing', '${court.openTime}-${court.closeTime}'),
              Container(height: 30, width: 1, color: AppColors.divider),
              _buildSkeletalStat('Type', court.courtTypes.isNotEmpty ? court.courtTypes.first : 'N/A'),
              Container(height: 30, width: 1, color: AppColors.divider),
              _buildSkeletalStat('Size', court.teamSize),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletalStat(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
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

  // ── Equipments ────────────────────────────────────────────────────────────

  Widget _buildEquipments(Court court) {
    IconData iconForEquipment(String equipment) {
      final key = equipment.toLowerCase();
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
          const DetailSectionTitle(title: 'Equipments'),
          const SizedBox(height: 12),
          if (court.equipments.isEmpty)
            const Text(
              'No equipments listed.',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            )
          else
            ...court.equipments.map(
              (equipment) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        equipment,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Icon(
                      iconForEquipment(equipment),
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
                  onTap: () {
                    setState(() {
                      _selectedDate = date;
                      _selectedSlots.clear();
                    });
                    _refreshBookedSlots();
                  },
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
    final morningSlots = _timeSlots
        .where((slot) {
          final hour = _slotHour(slot);
          return hour >= 6 && hour < 12;
        })
        .toList(growable: false);

    final afternoonSlots = _timeSlots
        .where((slot) {
          final hour = _slotHour(slot);
          return hour >= 12 && hour < 17;
        })
        .toList(growable: false);

    final eveningSlots = _timeSlots
        .where((slot) {
          final hour = _slotHour(slot);
          return hour >= 17;
        })
        .toList(growable: false);

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
          if (_isLoadingBookedSlots)
            const LinearProgressIndicator(minHeight: 2),
          if (morningSlots.isNotEmpty)
            _buildSlotSection(
              title: 'MORNING',
              icon: Icons.wb_sunny_outlined,
              slots: morningSlots,
            ),
          const SizedBox(height: 14),
          if (afternoonSlots.isNotEmpty)
            _buildSlotSection(
              title: 'AFTERNOON',
              icon: Icons.wb_twilight_outlined,
              slots: afternoonSlots,
            ),
          const SizedBox(height: 14),
          if (eveningSlots.isNotEmpty)
            _buildSlotSection(
              title: 'EVENING',
              icon: Icons.nightlight_round,
              slots: eveningSlots,
            ),
        ],
      ),
    );
  }

  int _slotHour(String slot) {
    final parts = slot.split(' ');
    if (parts.length != 2) {
      return 0;
    }
    final hm = parts[0].split(':');
    if (hm.length != 2) {
      return 0;
    }
    final hourRaw = int.tryParse(hm[0]) ?? 0;
    var hour = hourRaw % 12;
    if (parts[1].toUpperCase() == 'PM') {
      hour += 12;
    }
    return hour;
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

  // ── Bottom Bar ────────────────────────────────────────────────────────────

  Widget _buildBottomBar(BuildContext context, Court court) {
    return Container(
      color: AppColors.surface,
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        child: SafeArea(
          top: false,
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _canBook
                  ? () {
                      final selectedSlots = _orderedSelectedSlots();
                      final selectedDate = _selectedDate!;
                      final existsInCart = _cartRepo.hasConflictForSelection(
                        courtId: court.id,
                        date: selectedDate,
                        slots: selectedSlots,
                      );
                      if (existsInCart) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('These exact slots are already in your cart.'),
                          ),
                        );
                        return;
                      }

                      final cartItem = BookingCartItem(
                        id: 'CART-${DateTime.now().microsecondsSinceEpoch}',
                        court: court,
                        date: selectedDate,
                        slots: selectedSlots,
                        createdAt: DateTime.now(),
                      );
                      _cartRepo.addItem(cartItem);

                      setState(() {
                        _selectedSlots.clear();
                      });

                      if (!mounted) {
                        return;
                      }

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Slots added to booking cart.'),
                          action: SnackBarAction(
                            label: 'View Cart',
                            onPressed: () => context.go(AppConstants.routeCart),
                          ),
                        ),
                      );
                    }
                  : null,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.textPrimary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.divider,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_shopping_cart_rounded, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    _canBook 
                        ? 'Add to Cart  •  ₹${(court.pricePerHour * _selectedHours).toInt()}' 
                        : 'Select Date & Slots',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
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

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double iconSize;
  const _CircleBtn({
    required this.icon,
    required this.onTap,
    this.iconSize = 12,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.9),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 18, color: AppColors.textPrimary),
    ),
  );
}
