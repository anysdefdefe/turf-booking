import 'package:flutter/material.dart';
import 'package:turf_booking/app/theme/app_colors.dart';
import 'package:turf_booking/app/constants/app_constants.dart';
import '../widgets/owner_bottom_nav_bar.dart';

// ── MODELS ────────────────────────────────────────────────────────────────────

class CourtEntry {
  String sportType;
  String amenities;
  double hourlyRate;
  double dailyRate;
  double weeklyRate;
  double monthlyRate;
  double yearlyRate;

  CourtEntry({
    this.sportType = '',
    this.amenities = '',
    this.hourlyRate = 0,
    this.dailyRate = 0,
    this.weeklyRate = 0,
    this.monthlyRate = 0,
    this.yearlyRate = 0,
  });
}

// ── SCREEN ────────────────────────────────────────────────────────────────────

class OwnerAddStadiumScreen extends StatefulWidget {
  const OwnerAddStadiumScreen({super.key});

  @override
  State<OwnerAddStadiumScreen> createState() => _OwnerAddStadiumScreenState();
}

class _OwnerAddStadiumScreenState extends State<OwnerAddStadiumScreen> {
  final _stadiumNameController = TextEditingController();
  final _contactController = TextEditingController();
  final _locationController = TextEditingController();
  TimeOfDay _openTime = const TimeOfDay(hour: 6, minute: 0);
  TimeOfDay _closeTime = const TimeOfDay(hour: 22, minute: 0);
  final List<CourtEntry> _courts = [CourtEntry()];

  @override
  void dispose() {
    _stadiumNameController.dispose();
    _contactController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickTime(BuildContext context, bool isOpen) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isOpen ? _openTime : _closeTime,
    );
    if (picked != null) {
      setState(() {
        if (isOpen) {
          _openTime = picked;
        } else {
          _closeTime = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: const OwnerBottomNavBar(selectedIndex: 1),
      appBar: AppBar(
        title: const Text('Add Stadium'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton(
              onPressed: () {
                // TODO: save to Supabase later
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text(
                      'Stadium saved (mock)',
                      style: TextStyle(fontFamily: 'Poppins'),
                    ),
                    backgroundColor: AppColors.primary,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppConstants.radiusM),
                    ),
                  ),
                );
              },
              child: const Text(
                'Save',
                style: TextStyle(
                  color: AppColors.primary,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── STADIUM DETAILS SECTION ──────────────────────────
            _SectionHeader(title: 'Stadium Details'),
            const SizedBox(height: 14),

            _InputField(
              controller: _stadiumNameController,
              label: 'Stadium Name',
              hint: 'e.g. Green Arena',
              icon: Icons.stadium_rounded,
            ),
            const SizedBox(height: 12),

            _InputField(
              controller: _contactController,
              label: 'Owner Contact',
              hint: 'e.g. +91 98765 43210',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),

            _InputField(
              controller: _locationController,
              label: 'Location / Address',
              hint: 'e.g. 12, MG Road, Bengaluru',
              icon: Icons.location_on_outlined,
              maxLines: 2,
            ),
            const SizedBox(height: 12),

            // ── TIMINGS ──────────────────────────────────────────
            _FieldLabel(label: 'Timings'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _TimePicker(
                    label: 'Opens at',
                    time: _openTime,
                    onTap: () => _pickTime(context, true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TimePicker(
                    label: 'Closes at',
                    time: _closeTime,
                    onTap: () => _pickTime(context, false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── STADIUM IMAGE PLACEHOLDER ─────────────────────────
            _FieldLabel(label: 'Stadium Images'),
            const SizedBox(height: 8),
            _ImagePlaceholder(
              onTap: () {
                // TODO: image picker later
              },
            ),

            const SizedBox(height: 32),

            // ── COURTS SECTION ───────────────────────────────────
            _SectionHeader(title: 'Courts'),
            const SizedBox(height: 14),

            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _courts.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) => _CourtCard(
                courtNumber: index + 1,
                court: _courts[index],
                onRemove: _courts.length > 1
                    ? () => setState(() => _courts.removeAt(index))
                    : null,
                onChanged: () => setState(() {}),
              ),
            ),

            const SizedBox(height: 16),

            // ── ADD COURT BUTTON ─────────────────────────────────
            GestureDetector(
              onTap: () => setState(() => _courts.add(CourtEntry())),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.badgeBg,
                  borderRadius: BorderRadius.circular(AppConstants.radiusM),
                  border: Border.all(color: AppColors.primary),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add, color: AppColors.primary, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Add Another Court',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ── COURT CARD ────────────────────────────────────────────────────────────────

class _CourtCard extends StatelessWidget {
  final int courtNumber;
  final CourtEntry court;
  final VoidCallback? onRemove;
  final VoidCallback onChanged;

  const _CourtCard({
    required this.courtNumber,
    required this.court,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Court header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.badgeBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Court $courtNumber',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const Spacer(),
              if (onRemove != null)
                GestureDetector(
                  onTap: onRemove,
                  child: const Icon(
                    Icons.remove_circle_outline,
                    color: Colors.redAccent,
                    size: 22,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Sport type
          TextField(
            onChanged: (v) => court.sportType = v,
            style: const TextStyle(
              fontFamily: 'Poppins',
              color: AppColors.textPrimary,
            ),
            decoration: _inputDecoration(
              'Sport Type',
              'e.g. Football, Cricket',
              Icons.sports_soccer_rounded,
            ),
          ),
          const SizedBox(height: 10),

          // Amenities
          TextField(
            onChanged: (v) => court.amenities = v,
            style: const TextStyle(
              fontFamily: 'Poppins',
              color: AppColors.textPrimary,
            ),
            decoration: _inputDecoration(
              'Amenities',
              'e.g. Bat, Ball, Racket',
              Icons.inventory_2_outlined,
            ),
          ),
          const SizedBox(height: 14),

          // Court image placeholder
          _FieldLabel(label: 'Court Images'),
          const SizedBox(height: 8),
          _ImagePlaceholder(
            onTap: () {
              // TODO: image picker later
            },
            height: 100,
          ),
          const SizedBox(height: 14),

          // Booking rates
          _FieldLabel(label: 'Booking Rates (₹)'),
          const SizedBox(height: 10),
          _RateRow(
            label: 'Hourly',
            initialValue: court.hourlyRate,
            onChanged: (v) => court.hourlyRate = v,
          ),
          const SizedBox(height: 8),
          _RateRow(
            label: 'Daily',
            initialValue: court.dailyRate,
            onChanged: (v) => court.dailyRate = v,
          ),
          const SizedBox(height: 8),
          _RateRow(
            label: 'Weekly',
            initialValue: court.weeklyRate,
            onChanged: (v) => court.weeklyRate = v,
          ),
          const SizedBox(height: 8),
          _RateRow(
            label: 'Monthly',
            initialValue: court.monthlyRate,
            onChanged: (v) => court.monthlyRate = v,
          ),
          const SizedBox(height: 8),
          _RateRow(
            label: 'Yearly',
            initialValue: court.yearlyRate,
            onChanged: (v) => court.yearlyRate = v,
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, String hint, IconData icon) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, size: 18, color: AppColors.textSecondary),
      labelStyle: const TextStyle(
        fontFamily: 'Poppins',
        color: AppColors.textSecondary,
      ),
      hintStyle: const TextStyle(
        fontFamily: 'Poppins',
        color: AppColors.textMuted,
      ),
      filled: true,
      fillColor: AppColors.background,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        borderSide: BorderSide(color: AppColors.divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        borderSide: BorderSide(color: AppColors.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        borderSide: const BorderSide(color: AppColors.primary),
      ),
    );
  }
}

// ── RATE ROW ──────────────────────────────────────────────────────────────────

class _RateRow extends StatelessWidget {
  final String label;
  final double initialValue;
  final ValueChanged<double> onChanged;

  const _RateRow({
    required this.label,
    required this.initialValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            keyboardType: TextInputType.number,
            onChanged: (v) => onChanged(double.tryParse(v) ?? 0),
            style: const TextStyle(
              fontFamily: 'Poppins',
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              prefixText: '₹ ',
              prefixStyle: const TextStyle(
                fontFamily: 'Poppins',
                color: AppColors.textSecondary,
              ),
              hintText: '0',
              hintStyle: const TextStyle(
                fontFamily: 'Poppins',
                color: AppColors.textMuted,
              ),
              filled: true,
              fillColor: AppColors.background,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusM),
                borderSide: BorderSide(color: AppColors.divider),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusM),
                borderSide: BorderSide(color: AppColors.divider),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusM),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── REUSABLE WIDGETS ──────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final int maxLines;
  final TextInputType keyboardType;

  const _InputField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(
        fontFamily: 'Poppins',
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 18, color: AppColors.textSecondary),
        labelStyle: const TextStyle(
          fontFamily: 'Poppins',
          color: AppColors.textSecondary,
        ),
        hintStyle: const TextStyle(
          fontFamily: 'Poppins',
          color: AppColors.textMuted,
        ),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          borderSide: BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          borderSide: BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      ),
    );
  }
}

class _TimePicker extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final VoidCallback onTap;

  const _TimePicker({
    required this.label,
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.access_time_rounded,
              size: 18,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
                Text(
                  time.format(context),
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  final VoidCallback onTap;
  final double height;

  const _ImagePlaceholder({required this.onTap, this.height = 120});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.chipUnselected,
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          border: Border.all(color: AppColors.divider),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.camera_alt_outlined,
              size: 28,
              color: AppColors.textMuted,
            ),
            SizedBox(height: 6),
            Text(
              'Tap to add images',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
