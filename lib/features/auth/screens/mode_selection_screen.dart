import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:turf_booking/features/auth/providers/auth_controller.dart';

class ModeSelectionScreen extends ConsumerWidget {
  const ModeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // We listen to the authControllerProvider to show loading spinners 
    // if the user hits the sign out button.
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F7),
      appBar: AppBar(
        title: const Text('Select Mode'),
        centerTitle: true,
        backgroundColor: const Color(0xFFF6F6F7),
        surfaceTintColor: Colors.transparent,
        actions: [
          if (authState.isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.logout_rounded),
              onPressed: () {
                ref.read(authControllerProvider.notifier).signOut();
              },
            )
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'How would you like to use Courtly?',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0E0E10),
                  letterSpacing: -0.5,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'You can always switch this later in your profile settings.',
                style: TextStyle(
                  fontSize: 15,
                  color: Color(0xFF71717A),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 56),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Color(0xFFE4E4E7)),
                ),
                clipBehavior: Clip.antiAlias,
                margin: EdgeInsets.zero,
                child: InkWell(
                  onTap: () => context.go('/customer/home'),
                  splashColor: const Color(0xFF0E0E10).withOpacity(0.05),
                  highlightColor: Colors.transparent,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0E0E10).withOpacity(0.05),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.sports_soccer_rounded,
                            size: 32,
                            color: Color(0xFF0E0E10),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'I want to book a turf',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0E0E10),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Find and book sports venues near you',
                          style: TextStyle(fontSize: 14, color: Color(0xFF71717A)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Color(0xFFE4E4E7)),
                ),
                clipBehavior: Clip.antiAlias,
                margin: EdgeInsets.zero,
                child: InkWell(
                  onTap: () => context.go('/owner/dashboard'),
                  splashColor: const Color(0xFF0E0E10).withOpacity(0.05),
                  highlightColor: Colors.transparent,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                         Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0E0E10).withOpacity(0.05),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.store_rounded,
                            size: 32,
                            color: Color(0xFF0E0E10),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'I am a turf owner',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0E0E10),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Manage your venues, bookings, and slots',
                          style: TextStyle(fontSize: 14, color: Color(0xFF71717A)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
