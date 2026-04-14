import 'package:flutter/material.dart';
import '../../../app/constants/app_constants.dart';
import '../../../app/theme/app_colors.dart';
import '../data/models/booking_args.dart';
import '../data/models/court_detail_args.dart';
import '../data/models/court_model.dart';
import '../data/repositories/customer_preferences_repository.dart';
import '../data/repositories/court_repository.dart';
import '../widgets/amenity_chip.dart';
import '../widgets/detail_section_title.dart';
import '../widgets/info_row_chip.dart';

class CourtDetailScreen extends StatefulWidget {
  const CourtDetailScreen({super.key});

  @override
  State<CourtDetailScreen> createState() => _CourtDetailScreenState();
}

class _CourtDetailScreenState extends State<CourtDetailScreen> {
  final CourtRepository _repo = CourtRepository.instance;

  bool _initialized = false;
  List<Court> _stadiumCourts = [];
  int _activeCourtIndex = 0;

  DateTime? _selectedDate;
  String? _selectedTime;
  String? _selectedType;
  int _durationHours = 1;

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
      _selectedDate != null && _selectedTime != null && _selectedType != null;

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
      _selectedTime = null;
      _selectedDate = null;
      _durationHours = 1;
    });
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
                _buildDatePicker(context),
                _divider(),
                _buildTimeSlotPicker(),
                _divider(),
                _buildTypePicker(court),
                _divider(),
                _buildDurationPicker(court),
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
      actions: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: _CircleBtn(icon: Icons.share_rounded, onTap: () {}),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
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
                  if (_stadiumCourts.length > 1) const SizedBox(width: 8),
                  _AvailBadge(isAvailable: court.isAvailable),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const DetailSectionTitle(title: 'Amenities'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: court.amenities
                .map((a) => AmenityChip(label: a))
                .toList(),
          ),
        ],
      ),
    );
  }

  // ── Date Picker ───────────────────────────────────────────────────────────

  Widget _buildDatePicker(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const DetailSectionTitle(title: 'Select Date'),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () async {
              final now = DateTime.now();
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate ?? now,
                firstDate: now,
                lastDate: now.add(const Duration(days: 60)),
                builder: (ctx, child) => Theme(
                  data: Theme.of(ctx).copyWith(
                    colorScheme: const ColorScheme.light(
                      primary: AppColors.primary,
                      onPrimary: Colors.white,
                    ),
                  ),
                  child: child!,
                ),
              );
              if (picked != null) setState(() => _selectedDate = picked);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _selectedDate != null
                      ? AppColors.primary
                      : AppColors.divider,
                  width: 1.2,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    color: _selectedDate != null
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _selectedDate == null
                        ? 'Tap to choose a date'
                        : _fmt(_selectedDate!),
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: _selectedDate == null
                          ? AppColors.textMuted
                          : AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: _selectedDate != null
                        ? AppColors.primary
                        : AppColors.textMuted,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime d) {
    const months = [
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
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${days[d.weekday - 1]}, ${d.day} ${months[d.month - 1]} ${d.year}';
  }

  // ── Time Slot Picker ──────────────────────────────────────────────────────

  Widget _buildTimeSlotPicker() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: DetailSectionTitle(title: 'Select Time Slot'),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _timeSlots.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final slot = _timeSlots[i];
                final sel = _selectedTime == slot;
                return GestureDetector(
                  onTap: () => setState(() => _selectedTime = slot),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 11,
                    ),
                    decoration: BoxDecoration(
                      color: sel ? AppColors.background : AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: sel ? AppColors.primary : AppColors.divider,
                        width: 1.2,
                      ),
                    ),
                    child: Text(
                      slot,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: sel
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
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
                    horizontal: 20,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: sel ? AppColors.background : AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: sel ? AppColors.primary : AppColors.divider,
                      width: 1.2,
                    ),
                  ),
                  child: Text(
                    type,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: sel
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── Duration ──────────────────────────────────────────────────────────────

  Widget _buildDurationPicker(Court court) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const DetailSectionTitle(title: 'Duration'),
          const SizedBox(height: 14),
          Row(
            children: [
              _DurationBtn(
                icon: Icons.remove_rounded,
                onTap: _durationHours > 1
                    ? () => setState(() => _durationHours--)
                    : null,
              ),
              const SizedBox(width: 20),
              Column(
                children: [
                  Text(
                    '$_durationHours',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Text(
                    'hour(s)',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 20),
              _DurationBtn(
                icon: Icons.add_rounded,
                onTap: _durationHours < 5
                    ? () => setState(() => _durationHours++)
                    : null,
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${(court.pricePerHour * _durationHours).toInt()}',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Text(
                    'total',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
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
                '₹${(court.pricePerHour * _durationHours).toInt()}',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '$_durationHours hr${_durationHours > 1 ? 's' : ''}',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _canBook
                  ? () => Navigator.pushNamed(
                      context,
                      AppConstants.routeBookingConfirm,
                      arguments: BookingArgs(
                        court: court,
                        date: _selectedDate!,
                        timeSlot: _selectedTime!,
                        courtType: _selectedType!,
                        durationHours: _durationHours,
                      ),
                    )
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: AppColors.divider,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: Text(
                _canBook ? 'Review & Book' : 'Select Date, Time & Sport',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
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
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.94),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.divider, width: 1),
        ),
        child: Icon(icon, size: 20, color: AppColors.textPrimary),
      ),
    );
  }
}

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: AppColors.surface,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.divider, width: 1),
      ),
      child: Icon(icon, size: 20, color: AppColors.textPrimary),
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
            width: 30,
            height: 30,
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
              size: 20,
              color: isLiked ? Colors.red : AppColors.textPrimary,
            ),
          ),
        );
      },
    );
  }
}

class _AvailBadge extends StatelessWidget {
  final bool isAvailable;
  const _AvailBadge({required this.isAvailable});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: AppColors.surface.withValues(alpha: 0.94),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: isAvailable ? AppColors.primary : Colors.red.shade300,
        width: 1,
      ),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          isAvailable ? 'Available' : 'Fully Booked',
          style: const TextStyle(
            fontFamily: 'Poppins',
            color: AppColors.textPrimary,
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
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
          size: 12,
        ),
        const SizedBox(width: 4),
        Text(
          '${km.toStringAsFixed(1)} km',
          style: const TextStyle(
            fontFamily: 'Poppins',
            color: AppColors.textSecondary,
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );
}

class _DurationBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _DurationBtn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: onTap != null ? AppColors.primary : AppColors.divider,
          width: 1,
        ),
      ),
      child: Icon(
        icon,
        color: onTap != null ? AppColors.textPrimary : AppColors.textMuted,
        size: 22,
      ),
    ),
  );
}
