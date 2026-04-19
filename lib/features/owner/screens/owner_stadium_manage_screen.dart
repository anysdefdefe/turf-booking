import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:turf_booking/app/theme/app_colors.dart';
import 'package:turf_booking/app/constants/app_constants.dart';
import 'package:turf_booking/features/owner/data/models/court_model.dart';
import 'package:turf_booking/features/owner/providers/stadium_providers.dart';
import '../widgets/owner_bottom_nav_bar.dart';

// ── Sport icon helper ─────────────────────────────────────────────────────────

IconData _sportIcon(String sportType) {
  switch (sportType.toLowerCase()) {
    case 'football':
    case 'soccer':
      return Icons.sports_soccer_rounded;
    case 'badminton':
      return Icons.sports_tennis_rounded;
    case 'cricket':
      return Icons.sports_cricket_rounded;
    case 'basketball':
      return Icons.sports_basketball_rounded;
    case 'volleyball':
      return Icons.sports_volleyball_rounded;
    case 'padel':
    case 'tennis':
      return Icons.sports_tennis_rounded;
    default:
      return Icons.sports_rounded;
  }
}

const _kSportOptions = [
  'Football',
  'Badminton',
  'Cricket',
  'Basketball',
  'Volleyball',
  'Tennis',
  'Padel',
];

// ── Root screen ───────────────────────────────────────────────────────────────

class OwnerStadiumManageScreen extends ConsumerWidget {
  const OwnerStadiumManageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stadiumAsync = ref.watch(currentStadiumProvider);

    return stadiumAsync.when(
      loading: () => const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      ),
      error: (error, _) => Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded,
                    size: 48, color: AppColors.textMuted),
                const SizedBox(height: 16),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => ref.invalidate(currentStadiumProvider),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      data: (stadium) {
        if (stadium == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.go('/owner/add-stadium');
          });
          return const Scaffold(backgroundColor: AppColors.background);
        }

        final courtsAsync = ref.watch(courtsForStadiumProvider(stadium.id));

        return courtsAsync.when(
          loading: () => const Scaffold(
            backgroundColor: Colors.white,
            body: Center(
                child: CircularProgressIndicator(color: AppColors.primary)),
          ),
          error: (err, _) => Scaffold(
            backgroundColor: AppColors.background,
            body: Center(child: Text('Failed to load courts: $err')),
          ),
          data: (courts) {
            final minPrice = courts.isEmpty
                ? null
                : courts
                    .map((c) => c.pricePerHour)
                    .reduce((a, b) => a < b ? a : b);

            final defaultOpen = courts.isNotEmpty
                ? courts.first.openTime
                : '06:00:00';
            final defaultClose = courts.isNotEmpty
                ? courts.first.closeTime
                : '22:00:00';

            return AnnotatedRegion<SystemUiOverlayStyle>(
              value: SystemUiOverlayStyle.light,
              child: Scaffold(
                backgroundColor: Colors.white,
                bottomNavigationBar:
                    const OwnerBottomNavBar(selectedIndex: 1),
                body: Column(
                  children: [
                    Expanded(
                      child: CustomScrollView(
                        slivers: [
                          // Hero image
                          SliverToBoxAdapter(
                            child: _HeroImage(
                              imageUrl: stadium.imageUrl,
                              onEdit: () =>
                                  context.push('/owner/edit-stadium'),
                            ),
                          ),
                          // Venue details
                          SliverToBoxAdapter(
                            child: _VenueDetails(
                              name: stadium.name,
                              address: stadium.address,
                              city: stadium.city,
                              description: stadium.description,
                              amenities: stadium.amenities,
                              minPrice: minPrice,
                            ),
                          ),
                          // Sport Types
                          if (courts.isNotEmpty)
                            SliverToBoxAdapter(
                              child: _SportTypesSection(courts: courts),
                            ),
                          // Courts management
                          SliverToBoxAdapter(
                            child: _CourtsSection(
                              courts: courts,
                              stadiumId: stadium.id,
                            ),
                          ),
                          const SliverToBoxAdapter(
                              child: SizedBox(height: 24)),
                        ],
                      ),
                    ),
                    // CTA bar
                    _CtaBar(
                      stadiumId: stadium.id,
                      defaultOpenTime: defaultOpen,
                      defaultCloseTime: defaultClose,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ── HERO IMAGE ────────────────────────────────────────────────────────────────

class _HeroImage extends StatelessWidget {
  final String? imageUrl;
  final VoidCallback onEdit;

  const _HeroImage({required this.imageUrl, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SizedBox(
          height: 240,
          width: double.infinity,
          child: imageUrl != null && imageUrl!.isNotEmpty
              ? Image.network(
                  imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stack) => _PlaceholderHero(),
                )
              : _PlaceholderHero(),
        ),
        // Gradient
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 80,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.black54, Colors.transparent],
              ),
            ),
          ),
        ),
        // Back button
        Positioned(
          top: MediaQuery.of(context).padding.top + 10,
          left: 14,
          child: GestureDetector(
            onTap: () {
              if (context.canPop()) context.pop();
            },
            child: _CircleButton(
              icon: Icons.chevron_left_rounded,
              iconColor: Colors.black87,
            ),
          ),
        ),
        // Edit button
        Positioned(
          top: MediaQuery.of(context).padding.top + 10,
          right: 14,
          child: GestureDetector(
            onTap: onEdit,
            child: _CircleButton(
              icon: Icons.edit_outlined,
              iconColor: AppColors.primary,
              iconSize: 18,
            ),
          ),
        ),
      ],
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final double iconSize;

  const _CircleButton({
    required this.icon,
    required this.iconColor,
    this.iconSize = 22,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 8,
          ),
        ],
      ),
      child: Icon(icon, color: iconColor, size: iconSize),
    );
  }
}

class _PlaceholderHero extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFD0EED8),
      child: const Center(
        child: Icon(Icons.stadium_rounded, size: 64, color: AppColors.primary),
      ),
    );
  }
}

// ── VENUE DETAILS ─────────────────────────────────────────────────────────────

class _VenueDetails extends StatelessWidget {
  final String name;
  final String address;
  final String city;
  final String? description;
  final List<String> amenities;
  final double? minPrice;

  const _VenueDetails({
    required this.name,
    required this.address,
    required this.city,
    required this.description,
    required this.amenities,
    required this.minPrice,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppConstants.paddingL, 18, AppConstants.paddingL, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          if (minPrice != null)
            Text(
              '₹ ${minPrice!.toStringAsFixed(0)} onwards',
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.location_on_outlined,
                  size: 15, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                '$address, $city',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'About Venue',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            (description != null && description!.trim().isNotEmpty)
                ? description!
                : 'No description provided for this venue yet.',
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          if (amenities.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text(
              'Amenities',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: amenities
                  .map((a) => _AmenityChip(label: a))
                  .toList(growable: false),
            ),
          ],
        ],
      ),
    );
  }
}

// ── SPORT TYPES ───────────────────────────────────────────────────────────────

class _SportTypesSection extends StatelessWidget {
  final List<CourtModel> courts;
  const _SportTypesSection({required this.courts});

  @override
  Widget build(BuildContext context) {
    final sports = courts.map((c) => c.sportType).toSet().toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppConstants.paddingL, 20, AppConstants.paddingL, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sport Types',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: sports
                .map((s) => _SportChip(sport: s))
                .toList(growable: false),
          ),
        ],
      ),
    );
  }
}

// ── COURTS SECTION ────────────────────────────────────────────────────────────

class _CourtsSection extends ConsumerWidget {
  final List<CourtModel> courts;
  final String stadiumId;

  const _CourtsSection({required this.courts, required this.stadiumId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppConstants.paddingL, 24, AppConstants.paddingL, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Courts',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          if (courts.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'No courts added yet. Tap "Add New Court" below.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            )
          else
            ...courts.map(
              (c) => _CourtTile(court: c, stadiumId: stadiumId),
            ),
        ],
      ),
    );
  }
}

// ── CTA BAR ───────────────────────────────────────────────────────────────────

class _CtaBar extends StatelessWidget {
  final String stadiumId;
  final String defaultOpenTime;
  final String defaultCloseTime;

  const _CtaBar({
    required this.stadiumId,
    required this.defaultOpenTime,
    required this.defaultCloseTime,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(
        left: AppConstants.paddingL,
        right: AppConstants.paddingL,
        bottom: MediaQuery.of(context).padding.bottom + 8,
        top: 10,
      ),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: FilledButton.icon(
          onPressed: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => _AddCourtSheet(
              stadiumId: stadiumId,
              defaultOpenTime: defaultOpenTime,
              defaultCloseTime: defaultCloseTime,
            ),
          ),
          icon: const Icon(Icons.add_rounded, size: 20),
          label: const Text(
            'Add New Court',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF1A1A1A),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}

// ── COURT TILE ────────────────────────────────────────────────────────────────

class _CourtTile extends ConsumerWidget {
  final CourtModel court;
  final String stadiumId;

  const _CourtTile({required this.court, required this.stadiumId});

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        icon: const Icon(
          Icons.warning_amber_rounded,
          color: Colors.orange,
          size: 44,
        ),
        title: const Text(
          'Delete Court?',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
            color: AppColors.error,
          ),
        ),
        content: Text(
          'You are about to permanently delete "${court.name}".\n\nThis action cannot be undone and will remove all associated data.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.divider),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text(
              'Delete',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final ok = await ref
          .read(deleteCourtControllerProvider.notifier)
          .deleteCourt(court.id, stadiumId);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ok ? '✓ "${court.name}" deleted' : 'Failed to delete court',
              style: const TextStyle(fontFamily: 'Poppins'),
            ),
            backgroundColor: ok ? AppColors.primary : AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Sport icon
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.badgeBg,
              shape: BoxShape.circle,
            ),
            child: Icon(_sportIcon(court.sportType),
                color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  court.name,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${court.sportType} · ₹${court.pricePerHour.toStringAsFixed(0)}/hr  ·  ${court.openTime.substring(0, 5)}–${court.closeTime.substring(0, 5)}',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Status chip
          _StatusChip(isActive: court.isActive),
          const SizedBox(width: 8),

          // Edit button
          GestureDetector(
            onTap: () => context.push('/owner/edit-court/${court.id}'),
            child: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.edit_outlined,
                  size: 15, color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(width: 6),

          // Delete button
          GestureDetector(
            onTap: () => _confirmDelete(context, ref),
            child: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.delete_outline_rounded,
                  size: 15, color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

// ── ADD COURT BOTTOM SHEET ────────────────────────────────────────────────────

class _AddCourtSheet extends ConsumerStatefulWidget {
  final String stadiumId;
  final String defaultOpenTime;
  final String defaultCloseTime;

  const _AddCourtSheet({
    required this.stadiumId,
    required this.defaultOpenTime,
    required this.defaultCloseTime,
  });

  @override
  ConsumerState<_AddCourtSheet> createState() => _AddCourtSheetState();
}

class _AddCourtSheetState extends ConsumerState<_AddCourtSheet> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  String? _selectedSport;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final price = double.tryParse(_priceController.text.trim());

    if (name.isEmpty) {
      _snack('Court name is required');
      return;
    }
    if (_selectedSport == null) {
      _snack('Please select a sport type');
      return;
    }
    if (price == null || price <= 0) {
      _snack('Enter a valid price per hour');
      return;
    }

    setState(() => _isSaving = true);

    final ok = await ref
        .read(addCourtControllerProvider.notifier)
        .addCourt(
          stadiumId: widget.stadiumId,
          name: name,
          sportType: _selectedSport!,
          pricePerHour: price,
          openTime: widget.defaultOpenTime,
          closeTime: widget.defaultCloseTime,
        );

    if (mounted) {
      setState(() => _isSaving = false);
      if (ok) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('✓ Court added',
              style: TextStyle(fontFamily: 'Poppins')),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      } else {
        _snack('Failed to add court. Please try again.');
      }
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontFamily: 'Poppins')),
      backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 20, 24, bottomInset + 24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Title
            const Text(
              'Add New Court',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),

            // Court name
            _label('Court Name'),
            _field(_nameController, hint: 'e.g. Court A'),
            const SizedBox(height: 16),

            // Sport type
            _label('Sport Type'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _kSportOptions.map((sport) {
                final selected = _selectedSport == sport;
                return GestureDetector(
                  onTap: () => setState(() => _selectedSport = sport),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primary : Colors.white,
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(
                        color: selected
                            ? AppColors.primary
                            : AppColors.divider,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _sportIcon(sport),
                          size: 13,
                          color: selected
                              ? Colors.white
                              : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          sport,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: selected
                                ? Colors.white
                                : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Price
            _label('Price per Hour (₹)'),
            _field(
              _priceController,
              hint: 'e.g. 800',
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 28),

            // Submit
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: _isSaving ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text(
                        'Add Court',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
      );

  Widget _field(
    TextEditingController controller, {
    String hint = '',
    TextInputType keyboardType = TextInputType.text,
  }) =>
      TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          color: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            color: AppColors.textMuted,
          ),
          filled: true,
          fillColor: AppColors.background,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusM),
            borderSide: const BorderSide(color: AppColors.divider),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusM),
            borderSide: const BorderSide(color: AppColors.divider),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusM),
            borderSide:
                const BorderSide(color: AppColors.primary, width: 1.5),
          ),
        ),
      );
}

// ── AMENITY CHIP ──────────────────────────────────────────────────────────────

class _AmenityChip extends StatelessWidget {
  final String label;
  const _AmenityChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: AppColors.divider, width: 1.2),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}

// ── SPORT CHIP ────────────────────────────────────────────────────────────────

class _SportChip extends StatelessWidget {
  final String sport;
  const _SportChip({required this.sport});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_sportIcon(sport), size: 14, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            sport,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── STATUS CHIP ───────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  final bool isActive;
  const _StatusChip({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isActive
            ? Colors.green.withValues(alpha: 0.12)
            : Colors.red.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isActive ? 'Active' : 'Inactive',
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color:
              isActive ? Colors.green.shade700 : Colors.red.shade400,
        ),
      ),
    );
  }
}
