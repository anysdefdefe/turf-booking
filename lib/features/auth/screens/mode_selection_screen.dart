import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:turf_booking/features/auth/providers/auth_controller.dart';
import 'package:turf_booking/features/auth/providers/auth_providers.dart';
import 'package:turf_booking/app/theme/theme_controller.dart';
import 'package:turf_booking/shared/widgets/fade_slide_transition.dart';

const String _kHeroImageUrl =
    'https://plus.unsplash.com/premium_photo-1677404692469-a4ddcc1267a5?w=400&auto=format&fit=crop&q=60&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxzZWFyY2h8MTd8fEJhc2ViYWxsfGVufDB8fDB8fHww';

class _Accent {
  final Color icon;
  final Color iconBg;
  const _Accent({required this.icon, required this.iconBg});
}

class _CardData {
  final String title;
  final String subtitle;
  final IconData icon;
  final String route;
  final _Accent accent;

  const _CardData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.route,
    required this.accent,
  });
}

class ModeSelectionScreen extends ConsumerStatefulWidget {
  const ModeSelectionScreen({super.key});

  @override
  ConsumerState<ModeSelectionScreen> createState() =>
      _ModeSelectionScreenState();
}

class _ModeSelectionScreenState extends ConsumerState<ModeSelectionScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _sheetFade;
  late final Animation<Offset> _sheetSlide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();

    _sheetFade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _sheetSlide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final authState = ref.watch(authControllerProvider);
    final user = ref.watch(authStateProvider).value;

    final size = MediaQuery.sizeOf(context);
    final topPad = MediaQuery.paddingOf(context).top;
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    final heroHeight = size.height * 0.58;
    const sheetPeek = 32.0;
    const sheetRadius = 36.0;

    final cards = <_CardData>[
      _CardData(
        title: 'Player',
        subtitle: 'Book venues and manage your games',
        icon: Icons.sports_soccer_rounded,
        route: '/customer/home',
        accent: _Accent(icon: cs.primary, iconBg: cs.primaryContainer),
      ),
      _CardData(
        title: 'Owner',
        subtitle: 'Venues, bookings & payouts',
        icon: Icons.storefront_rounded,
        route: '/owner/gateway',
        accent: _Accent(icon: cs.tertiary, iconBg: cs.tertiaryContainer),
      ),
      if (user != null && user.isAdmin)
        _CardData(
          title: 'Admin',
          subtitle: 'Platform overview and controls',
          icon: Icons.admin_panel_settings_rounded,
          route: '/admin',
          accent: _Accent(icon: cs.secondary, iconBg: cs.secondaryContainer),
        ),
    ];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Theme.of(context).brightness == Brightness.dark
            ? Brightness.light
            : Brightness.dark,
        statusBarBrightness: Theme.of(context).brightness == Brightness.dark
            ? Brightness.dark
            : Brightness.light,
        systemNavigationBarColor: cs.surface,
        systemNavigationBarIconBrightness:
            Theme.of(context).brightness == Brightness.dark
            ? Brightness.light
            : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: cs.surface,
        body: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: heroHeight + sheetPeek,
              child: _HeroImage(topPad: topPad, authState: authState, ref: ref),
            ),

            Positioned(
              top: heroHeight - sheetPeek,
              left: 0,
              right: 0,
              bottom: 0,
              child: FadeTransition(
                opacity: _sheetFade,
                child: SlideTransition(
                  position: _sheetSlide,
                  child: Container(
                    decoration: BoxDecoration(
                      color: cs.surface,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(sheetRadius),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: cs.shadow.withValues(alpha: 0.08),
                          blurRadius: 30,
                          offset: Offset(0, -6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Pill handle
                        const SizedBox(height: 12),
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: cs.outlineVariant,
                              borderRadius: BorderRadius.circular(100),
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),

                        // Section header
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Choose your role',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: cs.onSurface,
                                  letterSpacing: -0.6,
                                  height: 1.1,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Pick the experience that fits your role.',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: cs.onSurfaceVariant,
                                  letterSpacing: -0.1,
                                  height: 1.45,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Cards list
                        Expanded(
                          child: ListView.separated(
                            padding: EdgeInsets.fromLTRB(
                              20,
                              0,
                              20,
                              20 + bottomPad,
                            ),
                            physics: const BouncingScrollPhysics(),
                            itemCount: cards.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, i) {
                              final card = cards[i];
                              return FadeSlideTransition(
                                delay: Duration(milliseconds: 80 + i * 60),
                                child: _RoleCard(
                                  data: card,
                                  onTap: () => context.go(card.route),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
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

class _HeroImage extends StatelessWidget {
  final double topPad;
  final AsyncValue<void> authState;
  final WidgetRef ref;

  const _HeroImage({
    required this.topPad,
    required this.authState,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Photo
        Image.network(
          _kHeroImageUrl,
          fit: BoxFit.cover,
          alignment: Alignment.center,
          filterQuality: FilterQuality.high,
          loadingBuilder: (_, child, progress) =>
              progress == null ? child : const _HeroFallback(),
          errorBuilder: (_, _, _) => const _HeroFallback(),
        ),

        ColoredBox(color: Colors.black.withValues(alpha: 0.38)),

        Positioned(
          top: topPad + 16,
          right: 20,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.34),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.22),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const _ThemeCycleButton(),
                const SizedBox(width: 8),
                authState.isLoading
                    ? const SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white60,
                        ),
                      )
                    : _HeroIconButton(
                        tooltip: 'Log out',
                        icon: Icons.logout_rounded,
                        onTap: () =>
                            ref.read(authControllerProvider.notifier).signOut(),
                      ),
              ],
            ),
          ),
        ),

        Positioned(
          left: 24,
          right: 24,
          bottom: 52,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 5),

                child: Text(
                  'Discipline beats motivation. Show up and play.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.94),
                    fontSize: 18,
                    fontWeight: FontWeight.w300,
                    letterSpacing: -0.1,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Headline
              Text(
                'Your game,\nyour ground.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 45,
                  fontWeight: FontWeight.w600,
                  height: 1.0,
                  letterSpacing: -1.1,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.30),
                      blurRadius: 14,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Sub-line
            ],
          ),
        ),
      ],
    );
  }
}

class _HeroIconButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;

  const _HeroIconButton({
    required this.tooltip,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withValues(alpha: 0.16),
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          splashColor: Colors.white.withValues(alpha: 0.22),
          highlightColor: Colors.white.withValues(alpha: 0.12),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.42),
                width: 1,
              ),
            ),
            child: Icon(icon, size: 19, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class _ThemeCycleButton extends StatelessWidget {
  const _ThemeCycleButton();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.instance,
      builder: (context, mode, _) {
        final nextMode = switch (mode) {
          ThemeMode.system => ThemeMode.light,
          ThemeMode.light => ThemeMode.dark,
          ThemeMode.dark => ThemeMode.system,
        };

        final (icon, tooltip) = switch (mode) {
          ThemeMode.system => (Icons.brightness_auto_rounded, 'Theme: System'),
          ThemeMode.light => (Icons.light_mode_rounded, 'Theme: Light'),
          ThemeMode.dark => (Icons.dark_mode_rounded, 'Theme: Dark'),
        };

        return _HeroIconButton(
          tooltip: tooltip,
          icon: icon,
          onTap: () => ThemeController.instance.setThemeMode(nextMode),
        );
      },
    );
  }
}

// ─── Role card ────────────────────────────────────────────────────────────────

class _RoleCard extends StatefulWidget {
  final _CardData data;
  final VoidCallback onTap;

  const _RoleCard({required this.data, required this.onTap});

  @override
  State<_RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<_RoleCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
      reverseDuration: const Duration(milliseconds: 160),
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 0.97,
    ).animate(CurvedAnimation(parent: _press, curve: Curves.easeIn));
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTapDown: (_) => _press.forward(),
      onTapUp: (_) {
        _press.reverse();
        widget.onTap();
      },
      onTapCancel: () => _press.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: cs.outlineVariant, width: 1),
            boxShadow: [
              BoxShadow(
                color: cs.shadow.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon container
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: d.accent.iconBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(d.icon, color: d.accent.icon, size: 26),
              ),

              const SizedBox(width: 16),

              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      d.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                        letterSpacing: -0.4,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      d.subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: cs.onSurfaceVariant,
                        height: 1.45,
                        letterSpacing: -0.1,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              // Chevron
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroFallback extends StatelessWidget {
  const _HeroFallback();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF111116),
      child: Center(
        child: Icon(
          Icons.stadium_rounded,
          size: 80,
          color: Colors.white.withValues(alpha: 0.10),
        ),
      ),
    );
  }
}
