import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:turf_booking/app/theme/app_colors.dart';
import 'package:turf_booking/features/auth/providers/auth_controller.dart';
import 'package:turf_booking/features/auth/providers/auth_providers.dart';
import 'package:turf_booking/shared/widgets/fade_slide_transition.dart';

class ModeSelectionScreen extends ConsumerWidget {
  const ModeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final user = ref.watch(authStateProvider).value;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 8, 16, 0),
                child: authState.isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      )
                    : TextButton.icon(
                        onPressed: () {
                          ref.read(authControllerProvider.notifier).signOut();
                        },
                        icon: const Icon(Icons.logout_rounded, size: 16),
                        label: const Text('Log out'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.textSecondary,
                          textStyle: const TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
              ),
            ),
            const Spacer(flex: 2),
            const FadeSlideTransition(
              child: Text(
                "Choose Your Path",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 56),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 24,
              runSpacing: 24,
              children: [
                FadeSlideTransition(
                  delay: const Duration(milliseconds: 100),
                  child: _ProfileAvatar(
                    label: 'Book a Venue',
                    icon: Icons.sports_soccer_rounded,
                    gradientColors: const [
                      AppColors.primary,
                      AppColors.primaryDark,
                    ],
                    onTap: () => context.go('/customer/home'),
                  ),
                ),
                FadeSlideTransition(
                  delay: const Duration(milliseconds: 150),
                  child: _ProfileAvatar(
                    label: 'Manage Your Venues',
                    icon: Icons.store_rounded,
                    gradientColors: const [
                      Color(0xFF3F3F46),
                      Color(0xFF27272A),
                    ],
                    onTap: () => context.go('/owner/gateway'),
                  ),
                ),
                if (user != null && user.isAdmin)
                  FadeSlideTransition(
                    delay: const Duration(milliseconds: 200),
                    child: _ProfileAvatar(
                      label: 'Admin Panel',
                      icon: Icons.admin_panel_settings_rounded,
                      gradientColors: const [
                        Color(0xFFDC2626),
                        Color(0xFF991B1B),
                      ],
                      onTap: () => context.go('/admin'),
                    ),
                  ),
              ],
            ),
            const Spacer(flex: 3),
          ],
        ),
      ),
    );
  }
}

class _ProfileAvatar extends StatefulWidget {
  final String label;
  final IconData icon;
  final List<Color> gradientColors;
  final VoidCallback onTap;

  const _ProfileAvatar({
    required this.label,
    required this.icon,
    required this.gradientColors,
    required this.onTap,
  });

  @override
  State<_ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends State<_ProfileAvatar> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isHovered = true),
      onTapUp: (_) {
        setState(() => _isHovered = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isHovered = false),
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOutCubic,
            width: _isHovered ? 116 : 124,
            height: _isHovered ? 116 : 124,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: widget.gradientColors,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: _isHovered ? widget.gradientColors.first : Colors.transparent,
                width: 3,
              ),
              boxShadow: [
                if (!_isHovered)
                  BoxShadow(
                    color: widget.gradientColors.last.withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
              ],
            ),
            child: Icon(
              widget.icon,
              size: _isHovered ? 48 : 52,
              color: AppColors.surface,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: _isHovered ? 116 : 124, // Matches the box width to force text wrapping uniformly
            child: Text(
              widget.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: TextStyle(
                fontSize: 15,
                height: 1.1,
                fontWeight: _isHovered ? FontWeight.w700 : FontWeight.w600,
                color: _isHovered ? widget.gradientColors.first : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
