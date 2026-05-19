import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:turf_booking/app/constants/app_constants.dart';
import 'package:turf_booking/features/owner/data/models/court_model.dart';
import 'package:turf_booking/features/owner/data/repositories/stadium_repository.dart';
import 'package:turf_booking/features/owner/providers/stadium_providers.dart';
import 'package:turf_booking/features/owner/widgets/storage_media.dart';
import 'package:turf_booking/shared/services/storage_image_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

// ── Sport helpers (mirrored from manage screen) ───────────────────────────────

const _kSportOptions = [
  'Football',
  'Badminton',
  'Cricket',
  'Basketball',
  'Volleyball',
  'Tennis',
  'Padel',
];

IconData _sportIcon(String sportType) {
  switch (sportType.toLowerCase()) {
    case 'football':
    case 'soccer':
      return Icons.sports_soccer_rounded;
    case 'badminton':
      return Icons.sports_tennis_rounded;
    case 'cricket':
      return Icons.sports_cricket_rounded;
    case 'basketball':
      return Icons.sports_basketball_rounded;
    case 'volleyball':
      return Icons.sports_volleyball_rounded;
    case 'padel':
    case 'tennis':
      return Icons.sports_tennis_rounded;
    default:
      return Icons.sports_rounded;
  }
}

class OwnerCourtEditScreen extends ConsumerStatefulWidget {
  final String courtId;
  const OwnerCourtEditScreen({super.key, required this.courtId});

  @override
  ConsumerState<OwnerCourtEditScreen> createState() =>
      _OwnerCourtEditScreenState();
}

class _OwnerCourtEditScreenState extends ConsumerState<OwnerCourtEditScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _equipmentController = TextEditingController();
  final _openTimeController = TextEditingController();
  final _closeTimeController = TextEditingController();
  // Used when the court's sport isn't in the standard chip list ("Other" mode)
  final _customSportController = TextEditingController();
  final _imagePicker = ImagePicker();
  final _storageImageService = StorageImageService(Supabase.instance.client);
  late bool _isActive;
  // Either a value from _kSportOptions, or the sentinel 'Other'
  String? _selectedSport;
  bool _isSaving = false;
  bool _initialized = false;
  File? _selectedImage;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _equipmentController.dispose();
    _openTimeController.dispose();
    _closeTimeController.dispose();
    _customSportController.dispose();
    super.dispose();
  }

  void _initFields(CourtModel court) {
    if (_initialized) return;
    _nameController.text = court.name;
    // If the stored sport is not in our standard list, treat it as custom
    if (_kSportOptions.contains(court.sportType)) {
      _selectedSport = court.sportType;
    } else {
      _selectedSport = 'Other';
      _customSportController.text = court.sportType;
    }
    _descriptionController.text = court.description ?? '';
    _priceController.text = court.pricePerHour.toStringAsFixed(0);
    _equipmentController.text = court.equipments.join(', ');
    _openTimeController.text = court.openTime;
    _closeTimeController.text = court.closeTime;
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

  Future<void> _selectTime(TextEditingController controller) async {
    final text = controller.text.trim();
    TimeOfDay initialTime = TimeOfDay.now();
    if (text.isNotEmpty && text.contains(':')) {
      final parts = text.split(':');
      initialTime = TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    }
    final time = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (time != null && mounted) {
      controller.text =
          '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00';
    }
  }

  Future<void> _pickImage() async {
    final xfile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
    );
    if (xfile != null && mounted) {
      try {
        await _storageImageService.validatePickedImage(xfile);
        if (!mounted) return;
        setState(() => _selectedImage = File(xfile.path));
      } on FormatException catch (error) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  Future<void> _save(String stadiumId, String? currentImagePath) async {
    final name = _nameController.text.trim();
    // Resolve the actual sport value: if 'Other' is selected, use the typed text
    final sport = _selectedSport == 'Other'
        ? _customSportController.text.trim()
        : _selectedSport;
    final price = double.tryParse(_priceController.text.trim());
    final equipments = _parseCsv(_equipmentController.text);
    final openTime = _openTimeController.text.trim();
    final closeTime = _closeTimeController.text.trim();

    if (name.isEmpty || sport == null || sport.isEmpty) {
      _showSnackbar(
        _selectedSport == 'Other'
            ? 'Please type your sport name'
            : 'Name and sport are required',
      );
      return;
    }
    if (price == null || price <= 0) {
      _showSnackbar('Enter a valid hourly rate');
      return;
    }

    setState(() => _isSaving = true);

    try {
      await ref
          .read(stadiumRepositoryProvider)
          .updateCourt(
            courtId: widget.courtId,
            name: name,
            sportType: sport,
            description: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
            pricePerHour: price,
            equipments: equipments,
            openTime: openTime,
            closeTime: closeTime,
            isActive: _isActive,
            imageFile: _selectedImage,
            currentImagePath: currentImagePath,
          );

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
        backgroundColor: Theme.of(context).colorScheme.primary,
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
      loading: () => Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
      error: (error, _) => Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: Center(child: Text('Error: $error')),
      ),
      data: (stadium) {
        if (stadium == null) {
          return Scaffold(
            backgroundColor: Theme.of(context).colorScheme.surface,
          );
        }

        final courtsAsync = ref.watch(courtsForStadiumProvider(stadium.id));

        return courtsAsync.when(
          loading: () => Scaffold(
            backgroundColor: Theme.of(context).colorScheme.surface,
            body: Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          error: (error, _) => Scaffold(
            backgroundColor: Theme.of(context).colorScheme.surface,
            body: Center(child: Text('Error: $error')),
          ),
          data: (courts) {
            final court = courts
                .where((c) => c.id == widget.courtId)
                .firstOrNull;

            if (court == null) {
              return Scaffold(
                backgroundColor: Theme.of(context).colorScheme.surface,
                appBar: AppBar(title: const Text('Court Not Found')),
                body: Center(
                  child: Text(
                    'This court no longer exists.',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              );
            }

            _initFields(court);

            return Scaffold(
              backgroundColor: Theme.of(context).colorScheme.surface,
              appBar: AppBar(
                backgroundColor: Theme.of(context).colorScheme.surface,
                elevation: 0,
                title: Text(
                  'Edit ${court.name}',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(AppConstants.paddingL),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildImageCard(court),
                    const SizedBox(height: 8),
                    Text(
                      'JPG/PNG only, max 10 MB per image.',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11.5,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _buildLabel('Court Name'),
                    _buildField(_nameController, hint: 'e.g. Court A'),
                    const SizedBox(height: 16),
                    _buildLabel('Sport Type'),
                    _buildSportSelector(),
                    const SizedBox(height: 16),
                    _buildLabel('About / Description'),
                    _buildField(
                      _descriptionController,
                      hint: 'Short description for customers',
                      maxLines: 3,
                    ),
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

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Open Time'),
                              GestureDetector(
                                onTap: () => _selectTime(_openTimeController),
                                child: AbsorbPointer(
                                  child: _buildField(
                                    _openTimeController,
                                    hint: '06:00:00',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Close Time'),
                              GestureDetector(
                                onTap: () => _selectTime(_closeTimeController),
                                child: AbsorbPointer(
                                  child: _buildField(
                                    _closeTimeController,
                                    hint: '22:00:00',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // ── Active toggle ──────────────────────────────
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(
                          AppConstants.radiusM,
                        ),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.event_available_outlined,
                            size: 18,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Court Active',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 14,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ),
                          Switch.adaptive(
                            value: _isActive,
                            onChanged: (v) => setState(() => _isActive = v),
                            activeThumbColor: Theme.of(
                              context,
                            ).colorScheme.primary,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _isSaving
                            ? null
                            : () => _save(stadium.id, court.imageUrl),
                        style: FilledButton.styleFrom(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppConstants.radiusM,
                            ),
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
                                  color: Color.fromARGB(255, 255, 255, 255),
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 32),
                    const Divider(),
                    const SizedBox(height: 24),
                    Text(
                      'Maintenance & Blocking',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Block off specific hours so customers cannot book them. This will act as a phantom booking and will not affect your revenue.',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          context.push(
                            '/owner/court/${widget.courtId}/blocks',
                            extra: stadium.id,
                          );
                        },
                        icon: const Icon(Icons.block, size: 18),
                        label: const Text('Manage Blocked Slots'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.error,
                          side: BorderSide(
                            color: Theme.of(context).colorScheme.error,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppConstants.radiusM,
                            ),
                          ),
                          textStyle: const TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildImageCard(CourtModel court) {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(AppConstants.radiusL),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: _selectedImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(AppConstants.radiusL),
                      child: Image.file(_selectedImage!, fit: BoxFit.cover),
                    )
                  : StorageImage(
                      storagePath: court.imageUrl,
                      bucketName: StadiumRepository.imageBucket,
                      width: double.infinity,
                      height: 180,
                      borderRadius: BorderRadius.circular(AppConstants.radiusL),
                      placeholder: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFF4FBF7), Colors.white],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(
                            AppConstants.radiusL,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.sports_tennis_rounded,
                            size: 42,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
            ),
            Positioned(
              bottom: 12,
              left: 12,
              child: _photoPill('Tap to change'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _photoPill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Poppins',
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildLabel(String label) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      label,
      style: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    ),
  );

  Widget _buildField(
    TextEditingController controller, {
    String hint = '',
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) => TextField(
    controller: controller,
    keyboardType: keyboardType,
    maxLines: maxLines,
    style: TextStyle(
      fontFamily: 'Poppins',
      fontSize: 14,
      color: Theme.of(context).colorScheme.onSurface,
    ),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 14,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
      ),
      filled: true,
      fillColor: Theme.of(context).colorScheme.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.primary,
          width: 1.5,
        ),
      ),
    ),
  );

  Widget _buildSportSelector() {
    final cs = Theme.of(context).colorScheme;
    final allOptions = [..._kSportOptions, 'Other'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: allOptions.map((sport) {
            final selected = _selectedSport == sport;
            return GestureDetector(
              onTap: () => setState(() => _selectedSport = sport),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: selected ? cs.primary : cs.surface,
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(
                    color: selected ? cs.primary : cs.outlineVariant,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      sport == 'Other' ? Icons.edit_rounded : _sportIcon(sport),
                      size: 13,
                      color: selected ? cs.onPrimary : cs.onSurfaceVariant,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      sport,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: selected ? cs.onPrimary : cs.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        // Show custom text input only when 'Other' is selected
        if (_selectedSport == 'Other') ...[
          const SizedBox(height: 10),
          TextField(
            controller: _customSportController,
            textCapitalization: TextCapitalization.words,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              color: cs.onSurface,
            ),
            decoration: InputDecoration(
              hintText: 'e.g. Kabaddi, Hockey, Pickleball…',
              hintStyle: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                color: cs.onSurface.withValues(alpha: 0.35),
              ),
              filled: true,
              fillColor: cs.surface,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusM),
                borderSide: BorderSide(color: cs.outlineVariant),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusM),
                borderSide: BorderSide(color: cs.outlineVariant),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusM),
                borderSide: BorderSide(color: cs.primary, width: 1.5),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
