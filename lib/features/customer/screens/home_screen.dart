import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/constants/app_constants.dart';
import '../../../app/theme/app_colors.dart';
import '../../../shared/widgets/empty_state.dart';
import '../data/models/court_model.dart';
import '../data/models/stadium_model.dart';
import '../data/repositories/court_repository.dart';
import '../providers/customer_catalog_controller.dart';
import '../widgets/court_search_bar.dart';
import '../widgets/customer_bottom_nav_bar.dart';
import 'package:turf_booking/features/owner/widgets/storage_media.dart';
import 'package:turf_booking/features/owner/data/repositories/stadium_repository.dart';
import 'package:turf_booking/features/auth/providers/auth_controller.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/sport_icon_mapper.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final CourtRepository _repo = CourtRepository.instance;
  List<String> _allCities = const [];
  List<String> _allSports = const [];
  List<String> _allTeamSizes = const [];
  List<Stadium> _stadiums = const [];
  List<Court> _courts = const [];
  final List<String> _selectedCities = [];
  final List<String> _selectedSports = [];
  final List<String> _selectedTeamSizes = [];
  RangeValues _priceRange = const RangeValues(0, 3000);
  RangeValues _distanceRange = const RangeValues(0, 12);
  String _searchQuery = '';

  bool get _hasActiveFilters {
    return _selectedCities.isNotEmpty ||
        _selectedSports.isNotEmpty ||
        _selectedTeamSizes.isNotEmpty ||
        _priceRange.start > 0 ||
        _priceRange.end < 3000 ||
        _distanceRange.start > 0 ||
        _distanceRange.end < 12;
  }

  List<Stadium> get _visibleStadiums {
    final selectedCities = _selectedCities.toSet();
    final query = _searchQuery.trim().toLowerCase();
    final filteredStadiumIds = _courts.map((court) => court.stadiumId).toSet();

    return _stadiums.where((stadium) {
      if (!filteredStadiumIds.contains(stadium.id)) {
        return false;
      }

      final cityMatch =
          selectedCities.isEmpty || selectedCities.contains(stadium.city);
      if (!cityMatch) {
        return false;
      }
      final distanceMatch =
          stadium.distanceKm >= _distanceRange.start &&
          stadium.distanceKm <= _distanceRange.end;

      if (!distanceMatch) {
        return false;
      }

      if (query.isEmpty) {
        return true;
      }
      return stadium.name.toLowerCase().contains(query) ||
          stadium.address.toLowerCase().contains(query) ||
          stadium.city.toLowerCase().contains(query);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _syncCatalogFromRepository();
    Future<void>.microtask(_loadCatalog);
  }

  Future<void> _loadCatalog() async {
    await ref.read(customerCatalogControllerProvider.future);
    if (!mounted) {
      return;
    }
    setState(_syncCatalogFromRepository);
  }

  void _syncCatalogFromRepository() {
    _allCities = _repo.getAllCities();
    _allSports = _repo.getAllSports();
    _allTeamSizes = _repo.getAllTeamSizes();
    _stadiums = _repo.getAllStadiums();
    _courts = _repo.getAllCourts();
  }

  void _onSearch(String query) {
    setState(() {
      _searchQuery = query;
      _applyFilters();
    });
  }

  void _onCityToggle(String city) {
    setState(() {
      if (_selectedCities.contains(city)) {
        _selectedCities.remove(city);
      } else {
        _selectedCities.add(city);
      }
      _applyFilters();
    });
  }

  void _clearFilters() {
    setState(() {
      _selectedCities.clear();
      _selectedSports.clear();
      _selectedTeamSizes.clear();
      _priceRange = const RangeValues(0, 3000);
      _distanceRange = const RangeValues(0, 12);
      _applyFilters();
    });
  }

  void _applyFilters() {
    List<Court> result = _repo.getAllCourts().where((court) {
      final cityMatch =
          _selectedCities.isEmpty || _selectedCities.contains(court.city);
      final sportMatch =
          _selectedSports.isEmpty ||
          court.courtTypes.any((type) => _selectedSports.contains(type));
      final teamSizeMatch =
          _selectedTeamSizes.isEmpty ||
          _selectedTeamSizes.contains(court.teamSize);
      final priceMatch =
          court.pricePerHour >= _priceRange.start &&
          court.pricePerHour <= _priceRange.end;

      return cityMatch && sportMatch && teamSizeMatch && priceMatch;
    }).toList();

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      result = result
          .where(
            (court) =>
                court.name.toLowerCase().contains(query) ||
                court.stadiumName.toLowerCase().contains(query) ||
                court.place.toLowerCase().contains(query) ||
                court.city.toLowerCase().contains(query) ||
                court.courtTypes.any(
                  (type) => type.toLowerCase().contains(query),
                ),
          )
          .toList();
    }
    _courts = result;
  }

  void _openLocationSheet() {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return _AdvancedFilterSheet(
              cities: _allCities,
              sports: _allSports,
              teamSizes: _allTeamSizes,
              selectedCities: _selectedCities,
              selectedSports: _selectedSports,
              selectedTeamSizes: _selectedTeamSizes,
              priceRange: _priceRange,
              distanceRange: _distanceRange,
              onToggleCity: (city) {
                _onCityToggle(city);
                setModalState(() {});
              },
              onToggleSport: (sport) {
                setState(() {
                  if (_selectedSports.contains(sport)) {
                    _selectedSports.remove(sport);
                  } else {
                    _selectedSports.add(sport);
                  }
                  _applyFilters();
                });
                setModalState(() {});
              },
              onToggleTeamSize: (teamSize) {
                setState(() {
                  if (_selectedTeamSizes.contains(teamSize)) {
                    _selectedTeamSizes.remove(teamSize);
                  } else {
                    _selectedTeamSizes.add(teamSize);
                  }
                  _applyFilters();
                });
                setModalState(() {});
              },
              onPriceChanged: (range) {
                setState(() {
                  _priceRange = range;
                  _applyFilters();
                });
                setModalState(() {});
              },
              onDistanceChanged: (range) {
                setState(() {
                  _distanceRange = range;
                  _applyFilters();
                });
                setModalState(() {});
              },
              onClear: () {
                _clearFilters();
                setModalState(() {});
              },
            );
          },
        );
      },
    );
  }

  void _onNavTap(int index) {
    if (index == 0) {
      return;
    }

    if (index == 1) {
      context.go('/customer/cart');
      return;
    }

    if (index == 2) {
      context.go('/customer/my-bookings');
      return;
    }

    if (index == 3) {
      context.go('/customer/profile');
    }
  }

  void _openVenueDetails(Stadium stadium) {
    final stadiumCourts = _repo.getCourtsByStadium(stadium.id);
    if (stadiumCourts.isEmpty) {
      return;
    }

    context.push(AppConstants.routeVenueDetail, extra: stadium);
  }

  @override
  Widget build(BuildContext context) {
    final catalogState = ref.watch(customerCatalogControllerProvider);

    if (catalogState.hasError && _stadiums.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        bottomNavigationBar: CustomerBottomNavBar(
          selectedIndex: 0,
          onTap: _onNavTap,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.wifi_off_rounded, size: 42),
                const SizedBox(height: 12),
                const Text(
                  'Failed to load venues.',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => ref
                      .read(customerCatalogControllerProvider.notifier)
                      .refresh()
                      .then((_) {
                        if (mounted) {
                          setState(_syncCatalogFromRepository);
                        }
                      }),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.textPrimary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: CustomerBottomNavBar(
        selectedIndex: 0,
        onTap: _onNavTap,
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            if (catalogState.isLoading && _stadiums.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              _buildHeader(ref),
              if (_hasActiveFilters) _buildFilterSummary(),
              _buildResultsHeader(),
              _buildVenuesSection(),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ],
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildHeader(WidgetRef ref) {
    final user = Supabase.instance.client.auth.currentUser;
    final firstName = user?.userMetadata?['full_name']?.toString().split(' ').first ?? 'User';

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Find Your\nVenue',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                      letterSpacing: -1.0,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                _OutlineIconButton(
                  icon: Icons.tune_rounded,
                  onTap: _openLocationSheet,
                  isActive: _hasActiveFilters,
                ),
                
              ],
            ),
            Text(
              "Your game starts here.",
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w200,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 18),
            CourtSearchBar(onChanged: _onSearch),
            const SizedBox(height: 24),
            _buildCategories(),
          ],
        ),
      ),
    );
  }

  Widget _buildCategories() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Categories',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 80,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _allSports.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final sport = _allSports[index];
              final isSelected = _selectedSports.contains(sport);
              final icon = sportIconForName(sport);
              
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedSports.remove(sport);
                    } else {
                      _selectedSports.add(sport);
                    }
                    _applyFilters();
                  });
                },
                child: Column(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : AppColors.surface,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? AppColors.primary : AppColors.divider,
                        ),
                      ),
                      child: Icon(
                        icon,
                        color: isSelected ? Colors.white : AppColors.textSecondary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      sport,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected ? AppColors.primary : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  SliverToBoxAdapter _buildFilterSummary() {
    final tags = <String>[];
    if (_selectedCities.isNotEmpty) {
      tags.add('${_selectedCities.length} locations');
    }
    if (_selectedSports.isNotEmpty) {
      tags.add('${_selectedSports.length} sports');
    }
    if (_selectedTeamSizes.isNotEmpty) {
      tags.add('${_selectedTeamSizes.length} team sizes');
    }
    if (_priceRange.start > 0 || _priceRange.end < 3000) {
      tags.add('price');
    }
    if (_distanceRange.start > 0 || _distanceRange.end < 12) {
      tags.add('distance');
    }
    final label = tags.join(' • ');

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
        child: Row(
          children: [
            const Icon(
              Icons.circle_outlined,
              size: 14,
              color: AppColors.primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            TextButton(
              onPressed: _clearFilters,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                minimumSize: const Size(48, 36),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Clear',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildResultsHeader() {
    final visibleStadiums = _visibleStadiums;
    final title = _searchQuery.isEmpty
        ? 'Venues'
        : 'Venue results for "$_searchQuery"';
    final resultCount = visibleStadiums.length;
    final actionLabel = resultCount == 0 ? '0 found' : '$resultCount found';

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
        child: Row(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            Text(
              actionLabel,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVenuesSection() {
    final visibleStadiums = _visibleStadiums;

    if (visibleStadiums.isEmpty) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: EmptyState(
          title: 'No venues found',
          subtitle: 'Try another location or search term',
          icon: Icons.stadium_rounded,
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final stadium = visibleStadiums[index];
        final courtCount = _repo.getCourtsByStadium(stadium.id).length;
        return _StadiumCard(
          stadium: stadium,
          courtCount: courtCount,
          onTap: () => _openVenueDetails(stadium),
        );
      }, childCount: visibleStadiums.length),
    );
  }
}

class _StadiumCard extends StatelessWidget {
  final Stadium stadium;
  final int courtCount;
  final VoidCallback onTap;

  const _StadiumCard({
    required this.stadium,
    required this.courtCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Deterministic check: bypass network request if string is empty
    final bool hasImage = stadium.imageUrl.isNotEmpty;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        // THE FIX: Forces the entire stadium card to stretch horizontally
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              child: Stack(
                children: [
                  hasImage
                      ? StorageImage(
                          storagePath: stadium.imageUrl,
                          bucketName: StadiumRepository.imageBucket,
                          width: double.infinity,
                          height: 150,
                          fit: BoxFit.cover,
                          borderRadius: BorderRadius.zero,
                          placeholder: _buildPlaceholder(),
                        )
                      : _buildPlaceholder(),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.surface.withValues(alpha: 0.94),
                        borderRadius: BorderRadius.circular(16),
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
                            '${stadium.distanceKm.toStringAsFixed(1)} km',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              color: AppColors.textSecondary,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          stadium.name,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        '$courtCount courts',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${stadium.address}, ${stadium.city}',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Extracted to enforce layout constraints
  Widget _buildPlaceholder() {
    return Container(
      height: 150,
      width: double.infinity, // THE FIX: Forces the placeholder to expand
      color: AppColors.divider,
      child: const Center(
        child: Icon(
          Icons.stadium_rounded,
          size: 40,
          color: AppColors.textMuted,
        ),
      ),
    );
  }
}

class _OutlineIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isActive;

  const _OutlineIconButton({
    required this.icon,
    required this.onTap,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isActive ? AppColors.textPrimary : const Color(0xFFEFEFF0),
        ),
        child: Icon(
          icon,
          size: 20,
          color: isActive ? Colors.white : AppColors.textPrimary,
        ),
      ),
    );
  }
}

class _AdvancedFilterSheet extends StatelessWidget {
  final List<String> cities;
  final List<String> sports;
  final List<String> teamSizes;
  final List<String> selectedCities;
  final List<String> selectedSports;
  final List<String> selectedTeamSizes;
  final RangeValues priceRange;
  final RangeValues distanceRange;
  final ValueChanged<String> onToggleCity;
  final ValueChanged<String> onToggleSport;
  final ValueChanged<String> onToggleTeamSize;
  final ValueChanged<RangeValues> onPriceChanged;
  final ValueChanged<RangeValues> onDistanceChanged;
  final VoidCallback onClear;

  const _AdvancedFilterSheet({
    required this.cities,
    required this.sports,
    required this.teamSizes,
    required this.selectedCities,
    required this.selectedSports,
    required this.selectedTeamSizes,
    required this.priceRange,
    required this.distanceRange,
    required this.onToggleCity,
    required this.onToggleSport,
    required this.onToggleTeamSize,
    required this.onPriceChanged,
    required this.onDistanceChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.divider, width: 1),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.82,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Filters',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: onClear,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        minimumSize: const Size(56, 36),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Clear all',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const Text(
                  'Sports',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: sports
                      .map(
                        (sport) => _FilterChipPill(
                          label: sport,
                          isSelected: selectedSports.contains(sport),
                          onTap: () => onToggleSport(sport),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 18),
                Text(
                  'Distance (${distanceRange.start.toStringAsFixed(1)} - ${distanceRange.end.toStringAsFixed(1)} km)',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                RangeSlider(
                  values: distanceRange,
                  min: 0,
                  max: 12,
                  divisions: 24,
                  labels: RangeLabels(
                    '${distanceRange.start.toStringAsFixed(1)} km',
                    '${distanceRange.end.toStringAsFixed(1)} km',
                  ),
                  onChanged: onDistanceChanged,
                ),
                const SizedBox(height: 8),
                Text(
                  'Price (₹${priceRange.start.toInt()} - ₹${priceRange.end.toInt()})',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                RangeSlider(
                  values: priceRange,
                  min: 0,
                  max: 3000,
                  divisions: 30,
                  labels: RangeLabels(
                    '₹${priceRange.start.toInt()}',
                    '₹${priceRange.end.toInt()}',
                  ),
                  onChanged: onPriceChanged,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Team Size',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: teamSizes
                      .map(
                        (teamSize) => _FilterChipPill(
                          label: teamSize,
                          isSelected: selectedTeamSizes.contains(teamSize),
                          onTap: () => onToggleTeamSize(teamSize),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Location',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: cities
                      .map(
                        (city) => _FilterChipPill(
                          label: city,
                          isSelected: selectedCities.contains(city),
                          onTap: () => onToggleCity(city),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Apply filters',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterChipPill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChipPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
            width: isSelected ? 1.4 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
