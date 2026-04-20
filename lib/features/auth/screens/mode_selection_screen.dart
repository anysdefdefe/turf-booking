import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:turf_booking/features/auth/providers/auth_controller.dart';
import 'package:turf_booking/features/auth/providers/auth_providers.dart';
import 'package:turf_booking/shared/widgets/fade_slide_transition.dart';

class ModeSelectionScreen extends ConsumerWidget {
  const ModeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final user = ref.watch(authStateProvider).value;
    final textTheme = Theme.of(context).textTheme;

    final modeCards = <_ModeCardData>[
      const _ModeCardData(
        title: 'Player',
        subtitle: 'Book a Venue',
        icon: Icons.sports_soccer_rounded,
        backgroundColor: Color(0xFF232529),
        route: '/customer/home',
      ),
      const _ModeCardData(
        title: 'Owner',
        subtitle: 'Manage Venues',
        icon: Icons.store_rounded,
        backgroundColor: Color(0xFF25262B),
        route: '/owner/gateway',
      ),
      if (user != null && user.isAdmin)
        const _ModeCardData(
          title: 'Admin',
          subtitle: 'Control Center',
          icon: Icons.admin_panel_settings_rounded,
          backgroundColor: Color(0xFF2A2525),
          route: '/admin',
        ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF18181D),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 390;
            final heroHeight = constraints.maxHeight * (isCompact ? 0.62 : 0.6);
            final panelTop = constraints.maxHeight * (isCompact ? 0.5 : 0.52);
            final archDepth = isCompact ? 32.0 : 40.0;

            return Stack(
              fit: StackFit.expand,
              children: [
                Positioned.fill(
                  top: panelTop,
                  child: Container(
                    color: const Color(0xFF18181D),
                    padding: EdgeInsets.fromLTRB(
                      isCompact ? 18 : 22,
                      isCompact ? 86 : 92,
                      isCompact ? 18 : 22,
                      16,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Choose Your Profile',
                          style: textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: isCompact ? 10 : 12,
                          runSpacing: 12,
                          children: modeCards
                              .map(
                                (card) => FadeSlideTransition(
                                  delay: card.animationDelay,
                                  child: _ModeProfileCard(
                                    data: card,
                                    onTap: () => context.go(card.route),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Pick the mode that matches your goal.',
                          textAlign: TextAlign.center,
                          style: textTheme.bodySmall?.copyWith(
                            color: Colors.white70,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  height: heroHeight,
                  child: ClipPath(
                    clipper: _HeroBottomArchClipper(archDepth: archDepth),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _HeroPoster(isCompact: isCompact),
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color(0x60000000),
                                Colors.transparent,
                                Colors.transparent,
                              ],
                              stops: [0.0, 0.3, 1.0],
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.topRight,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                            child: authState.isLoading
                                ? const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  )
                                : TextButton.icon(
                                    onPressed: () {
                                      ref
                                          .read(authControllerProvider.notifier)
                                          .signOut();
                                    },
                                    icon: const Icon(
                                      Icons.logout_rounded,
                                      size: 16,
                                    ),
                                    label: const Text('Log out'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      textStyle: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(
                            left: 24,
                            right: 24,
                            bottom: isCompact ? 122 : 132,
                          ),
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: isCompact ? 64 : 72,
                                  height: isCompact ? 64 : 72,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.24),
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.stadium_rounded,
                                    color: Colors.white,
                                    size: 34,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                FadeSlideTransition(
                                  child: Text(
                                    'Turf Booking',
                                    style: textTheme.headlineSmall?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Choose Your Path',
                                  textAlign: TextAlign.center,
                                  style: textTheme.titleMedium?.copyWith(
                                    color: Colors.white.withOpacity(0.9),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
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
    );
  }
}

class _HeroPoster extends StatelessWidget {
  final bool isCompact;

  const _HeroPoster({required this.isCompact});

  @override
  Widget build(BuildContext context) {
    return Image.network(
      'https://images.unsplash.com/photo-1575361204480-aadea25e6e68?auto=format&fit=crop&w=1200&q=80',
      fit: BoxFit.cover,
      filterQuality: FilterQuality.high,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return _HeroFallback(isCompact: isCompact, showLoader: true);
      },
      errorBuilder: (_, __, ___) => _HeroFallback(isCompact: isCompact),
    );
  }
}

class _HeroFallback extends StatelessWidget {
  final bool isCompact;
  final bool showLoader;

  const _HeroFallback({required this.isCompact, this.showLoader = false});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2A2E32), Color(0xFF16181E)],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: -20,
            right: -36,
            child: Container(
              width: 160,
              height: 160,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x1F00C27C),
              ),
            ),
          ),
          Positioned(
            left: -42,
            bottom: 36,
            child: Container(
              width: 190,
              height: 190,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x1800995F),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.sports_soccer_rounded,
                  size: isCompact ? 48 : 56,
                  color: Colors.white70,
                ),
                if (showLoader) ...[
                  const SizedBox(height: 14),
                  const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeCardData {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color backgroundColor;
  final String route;

  const _ModeCardData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.backgroundColor,
    required this.route,
  });

  Duration get animationDelay {
    switch (title) {
      case 'Player':
        return const Duration(milliseconds: 80);
      case 'Owner':
        return const Duration(milliseconds: 130);
      default:
        return const Duration(milliseconds: 180);
    }
  }
}

class _ModeProfileCard extends StatelessWidget {
  final _ModeCardData data;
  final VoidCallback onTap;

  const _ModeProfileCard({required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            child: Ink(
              height: 82,
              width: 82,
              decoration: BoxDecoration(
                color: data.backgroundColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.18),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(18),
                splashColor: Colors.white.withOpacity(0.06),
                highlightColor: Colors.white.withOpacity(0.02),
                child: Icon(data.icon, size: 23, color: Colors.white70),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            data.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              height: 1,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            data.subtitle,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10.5,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroBottomArchClipper extends CustomClipper<Path> {
  final double archDepth;

  const _HeroBottomArchClipper({required this.archDepth});

  @override
  Path getClip(Size size) {
    final safeDepth = archDepth.clamp(16.0, size.height - 24);
    final edgeY = size.height - safeDepth;

    final path = Path()
      ..lineTo(0, edgeY)
      ..quadraticBezierTo(
        size.width / 2,
        size.height + safeDepth,
        size.width,
        edgeY,
      )
      ..lineTo(size.width, 0)
      ..close();

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
