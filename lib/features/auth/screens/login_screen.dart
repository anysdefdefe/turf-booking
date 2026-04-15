import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:turf_booking/features/auth/providers/auth_notifier.dart';
import 'package:turf_booking/features/auth/screens/register_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _passwordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _openRegister() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
  }

  void _submit(AuthState authState, AuthNotifier notifier) {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;
    notifier.signIn(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authAsync = ref.watch(authProvider);
    final notifier = ref.read(authProvider.notifier);
    final authState = authAsync.asData?.value ?? const AuthState();

    if (authAsync.isLoading && authAsync.asData == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFF6F6F7),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF0A0A0B))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F7),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Full-width hero with curved bottom
            _HeroImage(),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Welcome back',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0E0E10),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Sign in to your account',
                    style: TextStyle(fontSize: 14, color: Color(0xFF828289)),
                  ),
                  const SizedBox(height: 28),
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildField(
                          label: 'Email',
                          controller: _emailController,
                          hint: 'you@example.com',
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Email is required';
                            if (!v.contains('@')) return 'Enter a valid email';
                            return null;
                          },
                        ),
                        const SizedBox(height: 18),
                        _buildField(
                          label: 'Password',
                          controller: _passwordController,
                          hint: '••••••••',
                          obscureText: !_passwordVisible,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Password is required';
                            return null;
                          },
                          suffixIcon: GestureDetector(
                            onTap: () => setState(() => _passwordVisible = !_passwordVisible),
                            child: Icon(
                              _passwordVisible
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              size: 18,
                              color: const Color(0xFF828289),
                            ),
                          ),
                        ),
                        if (authState.error != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            authState.error!,
                            style: const TextStyle(
                              color: Color(0xFFB00020),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        const SizedBox(height: 28),
                        _RingButton(
                          label: 'Login',
                          isLoading: authState.isLoading,
                          onPressed: () => _submit(authState, notifier),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: GestureDetector(
                      onTap: _openRegister,
                      child: RichText(
                        text: const TextSpan(
                          style: TextStyle(fontSize: 13.5, color: Color(0xFF828289)),
                          children: [
                            TextSpan(text: "Don't have an account? "),
                            TextSpan(
                              text: 'Sign up',
                              style: TextStyle(
                                color: Color(0xFF0E0E10),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
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

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    String? Function(String?)? validator,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: Color(0xFF3A3A40),
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          validator: validator,
          style: const TextStyle(fontSize: 15, color: Color(0xFF0E0E10)),
          decoration: _inputDecoration(hint, suffixIcon),
        ),
      ],
    );
  }
}

// ─── Full-width hero with curved bottom cutout ───────────────────────────────

class _HeroImage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return ClipPath(
      clipper: _BottomArcClipper(),
      child: Container(
        width: screenWidth,
        height: 300,
        color: const Color(0xFF111215),
        child: Stack(
          children: [
            // Subtle grid pattern overlay for visual interest
            CustomPaint(
              size: Size(screenWidth, 300),
              painter: _GridPainter(),
            ),
            const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.sports_soccer_rounded, size: 48, color: Color(0xFFFFFFFF)),
                  SizedBox(height: 12),
                  Text(
                    'TurfBook',
                    style: TextStyle(
                      color: Color(0xFFF0F0F1),
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Book your turf, play your game',
                    style: TextStyle(color: Color(0xFF9A9AA1), fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFFFFF).withOpacity(0.04)
      ..strokeWidth = 0.8;
    const gap = 36.0;
    for (double x = 0; x < size.width; x += gap) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += gap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BottomArcClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 56);
    path.quadraticBezierTo(
      size.width * 0.5,
      size.height + 28,
      size.width,
      size.height - 56,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

// ─── Shared ring button ───────────────────────────────────────────────────────

class _RingButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback onPressed;

  const _RingButton({
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFF0E0E10), width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          foregroundColor: const Color(0xFF0E0E10),
          backgroundColor: Colors.transparent,
          disabledForegroundColor: const Color(0xFF828289),
        ).copyWith(
          // Inner shadow / depth via overlayColor
          overlayColor: WidgetStateProperty.all(
            const Color(0xFF0E0E10).withOpacity(0.05),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0E0E10)),
              )
            : Text(
                label,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
      ),
    );
  }
}

// ─── Shared input decoration ──────────────────────────────────────────────────

InputDecoration _inputDecoration(String hint, [Widget? suffixIcon]) {
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: Color(0xFFDDDDE0), width: 1.2),
  );
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(fontSize: 14, color: Color(0xFFB0B0B6)),
    filled: true,
    fillColor: Colors.white,
    suffixIcon: suffixIcon != null
        ? Padding(padding: const EdgeInsets.only(right: 12), child: suffixIcon)
        : null,
    suffixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
    border: border,
    enabledBorder: border,
    focusedBorder: border.copyWith(
      borderSide: const BorderSide(color: Color(0xFF0E0E10), width: 1.5),
    ),
    errorBorder: border.copyWith(
      borderSide: const BorderSide(color: Color(0xFFB00020), width: 1.2),
    ),
    focusedErrorBorder: border.copyWith(
      borderSide: const BorderSide(color: Color(0xFFB00020), width: 1.5),
    ),
  );
}