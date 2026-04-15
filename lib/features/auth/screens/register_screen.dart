import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:turf_booking/features/auth/providers/auth_notifier.dart';
import 'package:turf_booking/features/auth/screens/email_confirmation_screen.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _passwordVisible = false;
  bool _confirmVisible = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit(AuthNotifier notifier) async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    final fullName =
        '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}'.trim();

    await notifier.signUp(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      fullName: fullName,
    );

    if (!mounted) return;

    final authState = ref.read(authProvider).asData?.value ?? const AuthState();
    if (authState.error != null) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => EmailConfirmationScreen(email: _emailController.text.trim()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authAsync = ref.watch(authProvider);
    final notifier = ref.read(authProvider.notifier);
    final authState = authAsync.asData?.value ?? const AuthState();

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F6F7),
        elevation: 0,
        surfaceTintColor: const Color(0xFFF6F6F7),
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE4E4E7)),
            ),
            child: const Icon(
              Icons.arrow_back_rounded,
              size: 18,
              color: Color(0xFF0E0E10),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              const Text(
                'Create account',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0E0E10),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Fill in your details to get started',
                style: TextStyle(fontSize: 14, color: Color(0xFF828289)),
              ),
              const SizedBox(height: 28),
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // First + Last name side by side
                    Row(
                      children: [
                        Expanded(
                          child: _buildField(
                            label: 'First Name',
                            controller: _firstNameController,
                            hint: 'John',
                            capitalization: TextCapitalization.words,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Required';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildField(
                            label: 'Last Name',
                            controller: _lastNameController,
                            hint: 'Doe',
                            capitalization: TextCapitalization.words,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Required';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
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
                        if (v.length < 6) return 'At least 6 characters';
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
                    const SizedBox(height: 18),
                    _buildField(
                      label: 'Confirm Password',
                      controller: _confirmPasswordController,
                      hint: '••••••••',
                      obscureText: !_confirmVisible,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Please confirm your password';
                        if (v != _passwordController.text) return 'Passwords do not match';
                        return null;
                      },
                      suffixIcon: GestureDetector(
                        onTap: () => setState(() => _confirmVisible = !_confirmVisible),
                        child: Icon(
                          _confirmVisible
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
                      label: 'Sign Up',
                      isLoading: authState.isLoading,
                      onPressed: () => _submit(notifier),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: RichText(
                    text: const TextSpan(
                      style: TextStyle(fontSize: 13.5, color: Color(0xFF828289)),
                      children: [
                        TextSpan(text: 'Already have an account? '),
                        TextSpan(
                          text: 'Sign in',
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
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization capitalization = TextCapitalization.none,
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
          textCapitalization: capitalization,
          obscureText: obscureText,
          validator: validator,
          style: const TextStyle(fontSize: 15, color: Color(0xFF0E0E10)),
          decoration: _inputDecoration(hint, suffixIcon),
        ),
      ],
    );
  }
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