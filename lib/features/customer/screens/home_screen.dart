import 'package:flutter/material.dart';
import '../../../app/constants/app_constants.dart';
import '../../../app/theme/app_colors.dart';
import '../data/models/court_model.dart';
import '../data/repositories/court_repository.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/section_header.dart';
import '../widgets/court_card.dart';
import '../widgets/court_search_bar.dart';
import '../widgets/place_filter_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _repo = CourtRepository.instance;
  late List<Court> _courts;
  late List<String> _allCities;
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

  void _applyFilters() {
    List<Court> result = _repo.filterByCities(_selectedCities);
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result
          .where(
            (c) =>
                c.name.toLowerCase().contains(q) ||
                c.place.toLowerCase().contains(q) ||
                c.city.toLowerCase().contains(q) ||
                c.courtTypes.any((t) => t.toLowerCase().contains(q)),
          )
          .toList();
    }
    _courts = result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            _buildHeader(),
            _buildSearchBar(),
            _buildFilterSection(),
            _buildCourtsSection(),
          ],
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildHeader() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        color: AppColors.primary,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Mumbai, IN',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppColors.textSecondary,
                        size: 18,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Find Your Court 🏟️',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.07),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(
                    Icons.notifications_outlined,
                    color: AppColors.textPrimary,
                    size: 22,
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
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

  SliverToBoxAdapter _buildSearchBar() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
        child: CourtSearchBar(onChanged: _onSearch),
      ),
    );
  }

  SliverToBoxAdapter _buildFilterSection() {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Filter by Area',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 10),
          PlaceFilterBar(
            places: _allCities,
            selectedPlaces: _selectedCities,
            onToggle: _onCityToggle,
          ),
          const SizedBox(height: 22),
          SectionHeader(
            title: _searchQuery.isNotEmpty
                ? 'Results for "$_searchQuery"'
                : 'All Courts',
            actionLabel: _courts.isNotEmpty ? '${_courts.length} found' : null,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildCourtsSection() {
    if (_courts.isEmpty) {
      return SliverFillRemaining(
        child: EmptyState(
          title: 'No courts found',
          subtitle: 'Try adjusting your search or filters',
          icon: Icons.sports_tennis_rounded,
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        if (index == _courts.length) {
          return const SizedBox(height: AppConstants.paddingXL);
        }
        final court = _courts[index];
        return CourtCard(
          court: court,
          onTap: () => Navigator.pushNamed(
            context,
            AppConstants.routeCourtDetail,
            arguments: court,
          ),
        );
      }, childCount: _courts.length + 1),
    );
  }
}
