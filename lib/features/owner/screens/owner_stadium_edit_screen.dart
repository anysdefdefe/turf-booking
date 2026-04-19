import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:turf_booking/app/theme/app_colors.dart';
import 'package:turf_booking/app/constants/app_constants.dart';
import 'package:turf_booking/features/owner/data/repositories/stadium_repository.dart';
import 'package:turf_booking/features/owner/providers/stadium_providers.dart';

class OwnerStadiumEditScreen extends ConsumerStatefulWidget {
  const OwnerStadiumEditScreen({super.key});

  @override
  ConsumerState<OwnerStadiumEditScreen> createState() =>
      _OwnerStadiumEditScreenState();
}

class _OwnerStadiumEditScreenState
    extends ConsumerState<OwnerStadiumEditScreen> {
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _amenitiesController = TextEditingController();
  final _descriptionController = TextEditingController();
  late bool _isActive;
  bool _isSaving = false;
  bool _initialized = false;

  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _amenitiesController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// Pre-fill the form with current stadium data — exactly once.
  void _initFields({
    required String name,
    required String address,
    required String city,
    String? description,
    required List<String> amenities,
    required bool isActive,
  }) {
    if (_initialized) return;
    _nameController.text = name;
    _addressController.text = address;
    _cityController.text = city;
    _descriptionController.text = description ?? '';
    _amenitiesController.text = amenities.join(', ');
    _isActive = isActive;
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
    final address = _addressController.text.trim();
    final city = _cityController.text.trim();
    final description = _descriptionController.text.trim();
    final amenities = _parseCsv(_amenitiesController.text);

    if (name.isEmpty || address.isEmpty || city.isEmpty) {
      _showSnackbar('All fields are required');
      return;
    }

    setState(() => _isSaving = true);

    try {
      await ref.read(stadiumRepositoryProvider).updateStadium(
            stadiumId: stadiumId,
            name: name,
            description: description.isEmpty ? null : description,
            amenities: amenities,
            address: address,
            city: city,
            isActive: _isActive,
          );

      // Invalidate so dashboard + manage screens reflect the change.
      ref.invalidate(currentStadiumProvider);

      if (mounted) {
        _showSnackbar('✓ Stadium updated');
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
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.go('/owner/add-stadium');
          });
          return const Scaffold(backgroundColor: AppColors.background);
        }

        _initFields(
          name: stadium.name,
          address: stadium.address,
          city: stadium.city,
          description: stadium.description,
          amenities: stadium.amenities,
          isActive: stadium.isActive,
        );

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.surface,
            elevation: 0,
            title: const Text(
              'Edit Stadium',
              style: TextStyle(
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
                _buildLabel('Stadium Name'),
                _buildField(_nameController, hint: 'e.g. Green Arena'),
                const SizedBox(height: 16),
                _buildLabel('Description / About'),
                _buildField(_descriptionController, hint: 'e.g. Premium turf for all ages...', maxLines: 3),
                const SizedBox(height: 16),
                _buildLabel('Address'),
                _buildField(_addressController, hint: 'e.g. 12, MG Road'),
                const SizedBox(height: 16),
                _buildLabel('City'),
                _buildField(_cityController, hint: 'e.g. Bengaluru'),
                const SizedBox(height: 20),
                _buildLabel('Amenities'),
                _buildField(
                  _amenitiesController,
                  hint: 'e.g. Parking, Washroom, Cafeteria',
                ),
                const SizedBox(height: 20),

                // ── Active toggle ─────────────────────────────────
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusM),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.power_settings_new_outlined,
                          size: 18, color: AppColors.textSecondary),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Stadium Active',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Switch.adaptive(
                        value: _isActive,
                        onChanged: (v) => setState(() => _isActive = v),
                        activeThumbColor: AppColors.primary,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // ── Save button ───────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed:
                        _isSaving ? null : () => _save(stadium.id),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppConstants.radiusM),
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

  Widget _buildField(TextEditingController controller,
          {String hint = '', int maxLines = 1}) =>
      TextField(
        controller: controller,
        maxLines: maxLines,
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
