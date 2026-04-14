import 'package:flutter/material.dart';

import '../../../app/constants/app_constants.dart';
import '../../../app/theme/app_colors.dart';
import '../../../shared/widgets/empty_state.dart';
import '../data/models/court_model.dart';
import '../data/repositories/court_repository.dart';
import '../widgets/court_card.dart';
import '../widgets/court_search_bar.dart';
import '../widgets/customer_floating_nav_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const String _currentLocation = 'Mumbai, IN';

  final CourtRepository _repo = CourtRepository.instance;
  late final List<String> _allCities;
  late List<Court> _courts;
  final List<String> _selectedCities = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _allCities = _repo.getAllCities();
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
      _applyFilters();
    });
  }

  void _applyFilters() {
    List<Court> result = _repo.filterByCities(_selectedCities);
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      result = result
          .where(
            (court) =>
                court.name.toLowerCase().contains(query) ||
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
            return _LocationFilterSheet(
              currentLocation: _currentLocation,
              cities: _allCities,
              selectedCities: _selectedCities,
              onToggleCity: (city) {
                _onCityToggle(city);
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
      Navigator.pushNamed(context, AppConstants.routeMyBookings);
      return;
    }

    if (index == 2) {
      Navigator.pushNamed(context, AppConstants.routeProfile);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: CustomerFloatingNavBar(
        selectedIndex: 0,
        onTap: _onNavTap,
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            _buildHeader(),
            _buildSearchRow(),
            if (_selectedCities.isNotEmpty) _buildFilterSummary(),
            _buildResultsHeader(),
            _buildCourtsSection(),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildHeader() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'My Location',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      SizedBox(width: 4),
                      Text(
                        _currentLocation,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                  SizedBox(height: 14),
                  Text(
                    'Find your Court',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      height: 1.1,
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

  SliverToBoxAdapter _buildSearchRow() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
        child: Row(
          children: [
            Expanded(child: CourtSearchBar(onChanged: _onSearch)),
            const SizedBox(width: 10),
            _OutlineIconButton(
              icon: Icons.filter_alt_outlined,
              onTap: _openLocationSheet,
              isActive: _selectedCities.isNotEmpty,
            ),
          ],
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildFilterSummary() {
    final label = _selectedCities.length == 1
        ? '1 location selected'
        : '${_selectedCities.length} locations selected';

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
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
    final title = _searchQuery.isEmpty
        ? 'All courts'
        : 'Results for "$_searchQuery"';
    final actionLabel = _courts.isEmpty ? '0 found' : '${_courts.length} found';

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
        child: Row(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w700,
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

  Widget _buildCourtsSection() {
    if (_courts.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: EmptyState(
          title: 'No courts found',
          subtitle: 'Try another location or search term',
          icon: Icons.sports_tennis_rounded,
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final court = _courts[index];
        return CourtCard(
          court: court,
          onTap: () => Navigator.pushNamed(
            context,
            AppConstants.routeCourtDetail,
            arguments: court,
          ),
        );
      }, childCount: _courts.length),
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
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isActive ? AppColors.primary : AppColors.divider,
            width: isActive ? 1.4 : 1,
          ),
        ),
        child: Icon(
          icon,
          size: 22,
          color: isActive ? AppColors.textPrimary : AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _LocationFilterSheet extends StatelessWidget {
  final String currentLocation;
  final List<String> cities;
  final List<String> selectedCities;
  final ValueChanged<String> onToggleCity;
  final VoidCallback onClear;

  const _LocationFilterSheet({
    required this.currentLocation,
    required this.cities,
    required this.selectedCities,
    required this.onToggleCity,
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Your Location',
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
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Clear all'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.divider, width: 1),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.my_location_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      currentLocation,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Other locations',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: cities
                  .map(
                    (city) => _LocationChip(
                      label: city,
                      isSelected: selectedCities.contains(city),
                      onTap: () => onToggleCity(city),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 18),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                child: const Text(
                  'Done',
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
    );
  }
}

class _LocationChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _LocationChip({
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
