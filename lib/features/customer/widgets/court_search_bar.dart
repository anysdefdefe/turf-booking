import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';

class CourtSearchBar extends StatefulWidget {
  final ValueChanged<String> onChanged;

  const CourtSearchBar({super.key, required this.onChanged});

  @override
  State<CourtSearchBar> createState() => _CourtSearchBarState();
}

class _CourtSearchBarState extends State<CourtSearchBar> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _controller,
        onChanged: widget.onChanged,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
          fontFamily: 'Poppins',
        ),
        decoration: InputDecoration(
          hintText: 'Search courts, stadiums, sports…',
          hintStyle: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 14,
            fontFamily: 'Poppins',
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.textSecondary,
            size: 22,
          ),
          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  onPressed: () {
                    _controller.clear();
                    widget.onChanged('');
                  },
                )
              : null,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 15,
          ),
        ),
      ),
    );
  }
}
