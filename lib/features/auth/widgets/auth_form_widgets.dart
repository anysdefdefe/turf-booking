import 'package:flutter/material.dart';

class AuthFieldLabel extends StatelessWidget {
  final String text;

  const AuthFieldLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Text(
      text,
      style: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: cs.onSurface,
      ),
    );
  }
}

class GoogleAuthButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const GoogleAuthButton({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: cs.surface,
          foregroundColor: cs.onSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          side: BorderSide(color: cs.outlineVariant, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 18),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cs.primaryContainer.withValues(alpha: 0.6),
              ),
              child: Center(
                child: Image.network(
                  'https://developers.google.com/identity/images/g-logo.png',
                  width: 16,
                  height: 16,
                  errorBuilder: (_, _, _) => Icon(
                    Icons.g_mobiledata_rounded,
                    size: 16,
                    color: cs.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Continue with Google',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AuthRingButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback onPressed;

  const AuthRingButton({
    super.key,
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton(
        onPressed: isLoading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          disabledBackgroundColor: cs.outlineVariant,
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}

InputDecoration authPillInputDecoration(
  BuildContext context,
  String hint, [
  Widget? suffixIcon,
]) {
  final cs = Theme.of(context).colorScheme;

  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(16),
    borderSide: BorderSide(color: cs.outlineVariant, width: 1),
  );

  return InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(
      fontFamily: 'Poppins',
      fontSize: 14,
      color: cs.onSurfaceVariant,
    ),
    filled: true,
    fillColor: cs.surface,
    suffixIcon: suffixIcon != null
        ? Padding(padding: const EdgeInsets.only(right: 12), child: suffixIcon)
        : null,
    suffixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: border,
    enabledBorder: border,
    focusedBorder: border.copyWith(
      borderSide: BorderSide(color: cs.primary, width: 1.5),
    ),
    errorBorder: border.copyWith(
      borderSide: BorderSide(color: cs.error, width: 1),
    ),
    focusedErrorBorder: border.copyWith(
      borderSide: BorderSide(color: cs.error, width: 1.5),
    ),
  );
}
