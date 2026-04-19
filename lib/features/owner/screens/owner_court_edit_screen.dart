import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:turf_booking/app/theme/app_colors.dart';
import 'package:turf_booking/app/constants/app_constants.dart';
import 'package:turf_booking/features/owner/data/models/court_model.dart';
import 'package:turf_booking/features/owner/data/repositories/stadium_repository.dart';
import 'package:turf_booking/features/owner/providers/stadium_providers.dart';

class OwnerCourtEditScreen extends ConsumerStatefulWidget {
  final String courtId;
  const OwnerCourtEditScreen({super.key, required this.courtId});

  @override
  ConsumerState<OwnerCourtEditScreen> createState() =>
      _OwnerCourtEditScreenState();
}

class _OwnerCourtEditScreenState
    extends ConsumerState<OwnerCourtEditScreen> {
  final _nameController = TextEditingController();
  final _sportController = TextEditingController();
  final _priceController = TextEditingController();
  final _equipmentController = TextEditingController();
  late bool _isActive;
  bool _isSaving = false;
  bool _initialized = false;

  @override
  void dispose() {
    _nameController.dispose();
    _sportController.dispose();
    _priceController.dispose();
    _equipmentController.dispose();
    super.dispose();
  }

  /// Pre-fill the form with current court data — exactly once.
  void _initFields(CourtModel court) {
    if (_initialized) return;
    _nameController.text = court.name;
    _sportController.text = court.sportType;
    _priceController.text = court.pricePerHour.toStringAsFixed(0);
    _equipmentController.text = court.equipments.join(', ');
    _isActive = court.isActive;
    _initialized = true;
  }

  List<String> _parseCsv(String source) {
    return source
        .split(',')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
  }

  Future<void> _save(String stadiumId) async {
    final name = _nameController.text.trim();
    final sport = _sportController.text.trim();
    final price = double.tryParse(_priceController.text.trim());
    final equipments = _parseCsv(_equipmentController.text);

    if (name.isEmpty || sport.isEmpty) {
      _showSnackbar('Name and sport are required');
      return;
    }
    if (price == null || price <= 0) {
      _showSnackbar('Enter a valid hourly rate');
      return;
    }

    setState(() => _isSaving = true);

    try {
      await ref.read(stadiumRepositoryProvider).updateCourt(
            courtId: widget.courtId,
            name: name,
            sportType: sport,
            pricePerHour: price,
            equipments: equipments,
            isActive: _isActive,
          );

      // Invalidate so the manage screen refreshes the court list.
      ref.invalidate(courtsForStadiumProvider(stadiumId));

      if (mounted) {
        _showSnackbar('✓ Court updated');
        context.pop();
      }
    } catch (e) {
      _showSnackbar('Error: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'Poppins')),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stadiumAsync = ref.watch(currentStadiumProvider);

    return stadiumAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
      error: (error, _) => Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: Text('Error: $error')),
      ),
      data: (stadium) {
        if (stadium == null) {
          return const Scaffold(backgroundColor: AppColors.background);
        }

        final courtsAsync =
            ref.watch(courtsForStadiumProvider(stadium.id));

        return courtsAsync.when(
          loading: () => const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          ),
          error: (error, _) => Scaffold(
            backgroundColor: AppColors.background,
            body: Center(child: Text('Error: $error')),
          ),
          data: (courts) {
            final court = courts.where((c) => c.id == widget.courtId).firstOrNull;

            if (court == null) {
              return Scaffold(
                backgroundColor: AppColors.background,
                appBar: AppBar(title: const Text('Court Not Found')),
                body: const Center(
                  child: Text(
                    'This court no longer exists.',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              );
            }

            _initFields(court);

            return Scaffold(
              backgroundColor: AppColors.background,
              appBar: AppBar(
                backgroundColor: AppColors.surface,
                elevation: 0,
                title: Text(
                  'Edit ${court.name}',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(AppConstants.paddingL),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Court Name'),
                    _buildField(_nameController, hint: 'e.g. Court A'),
                    const SizedBox(height: 16),
                    _buildLabel('Sport'),
                    _buildField(_sportController, hint: 'e.g. Football'),
                    const SizedBox(height: 16),
                    _buildLabel('Price per Hour (₹)'),
                    _buildField(
                      _priceController,
                      hint: 'e.g. 800',
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    _buildLabel('Equipments'),
                    _buildField(
                      _equipmentController,
                      hint: 'e.g. Ball, Net, Rackets',
                    ),
                    const SizedBox(height: 20),

                    // ── Active toggle ──────────────────────────────
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius:
                            BorderRadius.circular(AppConstants.radiusM),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.event_available_outlined,
                              size: 18, color: AppColors.textSecondary),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Court Active',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 14,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          Switch.adaptive(
                            value: _isActive,
                            onChanged: (v) =>
                                setState(() => _isActive = v),
                            activeThumbColor: AppColors.primary,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ── Save button ───────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _isSaving
                            ? null
                            : () => _save(stadium.id),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                AppConstants.radiusM),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Save Changes',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLabel(String label) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
      );

  Widget _buildField(
    TextEditingController controller, {
    String hint = '',
    TextInputType keyboardType = TextInputType.text,
  }) =>
      TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          color: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            color: AppColors.textMuted,
          ),
          filled: true,
          fillColor: AppColors.surface,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusM),
            borderSide: const BorderSide(color: AppColors.divider),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusM),
            borderSide: const BorderSide(color: AppColors.divider),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusM),
            borderSide:
                const BorderSide(color: AppColors.primary, width: 1.5),
          ),
        ),
      );
}
