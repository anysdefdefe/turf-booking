import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../data/repositories/onboarding_repository.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _pages = [
    _OnboardingPageData(
      title: 'Find Your\nPerfect Venue',
      subtitle:
          'Explore top sports venues by location, sport type, and pricing in just a few taps.',
      imageUrl:
          'https://images.unsplash.com/photo-1544698310-74e20ce64522?auto=format&fit=crop&q=80&w=800',
    ),
    _OnboardingPageData(
      title: 'Choose Courts\n& Slots',
      subtitle:
          'Pick your preferred sport, select the exact court, and book only the hours you need.',
      imageUrl:
          'https://images.unsplash.com/photo-1508344928928-7165b67de128?auto=format&fit=crop&q=80&w=800',
    ),
    _OnboardingPageData(
      title: 'Book Fast,\nPlay More',
      subtitle:
          'Experience a smooth checkout, get clear booking details, and hit the field faster.',
      imageUrl:
          'https://images.unsplash.com/photo-1518605368461-1e12a9e33df0?auto=format&fit=crop&q=80&w=800',
    ),
  ];

  final PageController _controller = PageController();
  int _pageIndex = 0;
  bool _finishing = false;

  bool get _isLast => _pageIndex == _pages.length - 1;

  Future<void> _finish() async {
    if (_finishing) return;
    setState(() => _finishing = true);
    await OnboardingRepository.markCompleted();
    if (!mounted) return;
    context.go('/mode-selection');
  }

  Future<void> _next() async {
    if (_isLast) {
      await _finish();
      return;
    }

    await _controller.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.fastOutSlowIn,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Content
          Column(
            children: [
              // Image slider and text occupying top 75%
              Expanded(
                flex: 12,
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _pages.length,
                  onPageChanged: (index) => setState(() => _pageIndex = index),
                  itemBuilder: (context, index) {
                    final page = _pages[index];
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          page.imageUrl,
                          fit: BoxFit.cover,
                          alignment: Alignment.topCenter,
                        ),
                        // Gradient fade to background color
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  AppColors.background.withValues(alpha: 0.0),
                                  AppColors.background.withValues(alpha: 0.85),
                                  AppColors.background,
                                ],
                                stops: const [0.0, 0.55, 0.85, 1.0],
                              ),
                            ),
                          ),
                        ),
                        // Text overlays sliding with the page
                        Align(
                          alignment: Alignment.bottomLeft,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(28.0, 0, 28.0, 0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  page.title,
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 34,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                    height: 1.15,
                                    letterSpacing: -1.0,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  page.subtitle,
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 16,
                                    color: AppColors.textSecondary,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              // Bottom controls (Dots + Button) taking remaining space
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(_pages.length, (index) {
                              final selected = index == _pageIndex;
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOutCubic,
                                margin: const EdgeInsets.only(right: 6),
                                width: selected ? 28 : 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: selected
                                      ? AppColors.primary
                                      : AppColors.textMuted.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              );
                            }),
                          ),
                          const Spacer(),
                          FloatingActionButton.extended(
                            onPressed: _finishing ? null : _next,
                            elevation: 0,
                            backgroundColor: AppColors.textPrimary,
                            foregroundColor: AppColors.surface,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _isLast ? 'Get Started' : 'Next',
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (!_isLast) ...[
                                  const SizedBox(width: 6),
                                  const Icon(Icons.arrow_forward_rounded, size: 20),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Top controls (Courtly logo + Skip) Overlaid
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Courtly',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _finishing ? null : _finish,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      backgroundColor: Colors.white.withValues(alpha: 0.85),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                      shape: const StadiumBorder(),
                    ),
                    child: const Text(
                      'Skip',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingPageData {
  final String title;
  final String subtitle;
  final String imageUrl;

  const _OnboardingPageData({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
  });
}
