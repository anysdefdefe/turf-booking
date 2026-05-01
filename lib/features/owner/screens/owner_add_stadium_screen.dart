import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:turf_booking/app/constants/app_constants.dart';
import 'package:turf_booking/app/theme/app_colors.dart';
import 'package:turf_booking/features/owner/data/repositories/stadium_repository.dart';
import 'package:turf_booking/features/owner/providers/stadium_providers.dart';
import '../widgets/owner_bottom_nav_bar.dart';

// ── FORM STATE MODEL ──────────────────────────────────────────────────────────
// Lightweight mutable class for UI form state only. NOT a DB model.

class _CourtFormEntry {
  String sportType = '';
  String equipments = '';
  String description = '';
  double pricePerHour = 0;
  File? imageFile;
  TimeOfDay? openTime;
  TimeOfDay? closeTime;

  _CourtFormEntry();

  /// Converts the raw form data into the repository's DTO.
  CourtInsertPayload toPayload({
    required TimeOfDay defaultOpenTime,
    required TimeOfDay defaultCloseTime,
  }) {
    final equipmentList = equipments
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final resolvedOpenTime = openTime ?? defaultOpenTime;
    final resolvedCloseTime = closeTime ?? defaultCloseTime;

    return CourtInsertPayload(
      name: sportType.trim(),
      sportType: sportType.trim(),
      description: description.trim().isEmpty ? null : description.trim(),
      pricePerHour: pricePerHour,
      equipments: equipmentList,
      openTime:
          '${resolvedOpenTime.hour.toString().padLeft(2, '0')}:${resolvedOpenTime.minute.toString().padLeft(2, '0')}:00',
      closeTime:
          '${resolvedCloseTime.hour.toString().padLeft(2, '0')}:${resolvedCloseTime.minute.toString().padLeft(2, '0')}:00',
      imageFile: imageFile,
    );
  }
}

// ── SCREEN ────────────────────────────────────────────────────────────────────

class OwnerAddStadiumScreen extends ConsumerStatefulWidget {
  const OwnerAddStadiumScreen({super.key});

  @override
  ConsumerState<OwnerAddStadiumScreen> createState() =>
      _OwnerAddStadiumScreenState();
}

class _OwnerAddStadiumScreenState extends ConsumerState<OwnerAddStadiumScreen> {
  final _stadiumNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _contactController = TextEditingController();
  final _locationController = TextEditingController();
  final _cityController = TextEditingController();
  final _amenitiesController = TextEditingController();

  TimeOfDay _openTime = const TimeOfDay(hour: 6, minute: 0);
  TimeOfDay _closeTime = const TimeOfDay(hour: 22, minute: 0);

  final List<_CourtFormEntry> _courts = [_CourtFormEntry()];
  File? _stadiumImage;

  LatLng? _selectedLatLng;

  final _imagePicker = ImagePicker();

  @override
  void dispose() {
    _stadiumNameController.dispose();
    _descriptionController.dispose();
    _contactController.dispose();
    _locationController.dispose();
    _cityController.dispose();
    _amenitiesController.dispose();
    super.dispose();
  }

  List<String> _parseCsv(String source) {
    return source
        .split(',')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
  }

  // ── TIME PICKER ────────────────────────────────────────────────
  Future<void> _pickTime(bool isOpen) async {
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

  // ── IMAGE PICKER (preview only — no upload) ────────────────────
  Future<void> _pickStadiumImage() async {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppConstants.radiusL),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Add Image',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              _ImageSourceTile(
                icon: Icons.camera_alt_rounded,
                label: 'Take a Photo',
                onTap: () async {
                  Navigator.pop(context);
                  final xfile = await _imagePicker.pickImage(
                    source: ImageSource.camera,
                    imageQuality: 80,
                  );
                  if (xfile != null) {
                    setState(() {
                      _stadiumImage = File(xfile.path);
                    });
                  }
                },
              ),
              const SizedBox(height: 10),
              _ImageSourceTile(
                icon: Icons.photo_library_rounded,
                label: 'Choose from Gallery',
                onTap: () async {
                  Navigator.pop(context);
                  final files = await _imagePicker.pickMultiImage(
                    imageQuality: 80,
                  );
                  if (files.isNotEmpty) {
                    setState(() {
                      _stadiumImage = File(files.first.path);
                    });
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickCourtImage(int courtIndex) async {
    final xfile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (xfile != null && mounted) {
      setState(() {
        _courts[courtIndex].imageFile = File(xfile.path);
      });
    }
  }

  Future<void> _pickCourtTime(int courtIndex, bool isOpen) async {
    final current = isOpen
        ? (_courts[courtIndex].openTime ?? _openTime)
        : (_courts[courtIndex].closeTime ?? _closeTime);
    final picked = await showTimePicker(context: context, initialTime: current);
    if (picked != null && mounted) {
      setState(() {
        if (isOpen) {
          _courts[courtIndex].openTime = picked;
        } else {
          _courts[courtIndex].closeTime = picked;
        }
      });
    }
  }

  // ── MAPS PICKER (flutter_map / OSM — FREE) ─────────────────────
  Future<void> _openMapPicker() async {
    LatLng initial = const LatLng(12.9716, 77.5946); // Bengaluru default
    try {
      final permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        final pos = await Geolocator.getCurrentPosition();
        initial = LatLng(pos.latitude, pos.longitude);
      }
    } catch (_) {}

    if (!mounted) return;

    final result = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (context) => _MapPickerScreen(initialLocation: initial),
      ),
    );

    if (result != null) {
      setState(() => _selectedLatLng = result);
      try {
        final placemarks = await placemarkFromCoordinates(
          result.latitude,
          result.longitude,
        );
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          _locationController.text =
              '${p.street}, ${p.subLocality}, ${p.locality}, ${p.administrativeArea}';
          // Auto-fill city if empty
          if (_cityController.text.isEmpty && p.locality != null) {
            _cityController.text = p.locality!;
          }
        }
      } catch (_) {}
    }
  }

  // ── VALIDATION ─────────────────────────────────────────────────
  bool _validate() {
    if (_stadiumNameController.text.trim().isEmpty) {
      _showSnackbar('Please enter a stadium name');
      return false;
    }
    if (_locationController.text.trim().isEmpty) {
      _showSnackbar('Please enter or pick a location');
      return false;
    }
    if (_cityController.text.trim().isEmpty) {
      _showSnackbar('Please enter a city');
      return false;
    }
    for (int i = 0; i < _courts.length; i++) {
      if (_courts[i].sportType.trim().isEmpty) {
        _showSnackbar('Please enter sport type for Court ${i + 1}');
        return false;
      }
      if (_courts[i].pricePerHour <= 0) {
        _showSnackbar('Please enter a valid hourly rate for Court ${i + 1}');
        return false;
      }
    }
    return true;
  }

  // ── SAVE VIA CONTROLLER ────────────────────────────────────────
  Future<void> _save() async {
    if (!_validate()) return;

    final courtPayloads = _courts
        .map(
          (c) => c.toPayload(
            defaultOpenTime: _openTime,
            defaultCloseTime: _closeTime,
          ),
        )
        .toList();

    final success = await ref
        .read(addStadiumControllerProvider.notifier)
        .submitStadium(
          name: _stadiumNameController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          amenities: _parseCsv(_amenitiesController.text),
          address: _locationController.text.trim(),
          city: _cityController.text.trim(),
          latitude: _selectedLatLng?.latitude,
          longitude: _selectedLatLng?.longitude,
          openTime: _openTime,
          closeTime: _closeTime,
          courts: courtPayloads,
          imageFile: _stadiumImage,
        );

    if (!mounted) return;

    if (success) {
      _showSnackbar('✓ Stadium created successfully!');
      context.go('/owner/dashboard');
    } else {
      final error = ref.read(addStadiumControllerProvider).error;
      _showSnackbar('Error: ${error ?? 'Unknown error'}');
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
    final controllerState = ref.watch(addStadiumControllerProvider);
    final isSaving = controllerState.isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: const OwnerBottomNavBar(selectedIndex: 1),
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text(
          'Add Stadium',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: isSaving
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    ),
                  )
                : TextButton(
                    onPressed: _save,
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
            const _SectionHeader(title: 'Stadium Details'),
            const SizedBox(height: 14),
            _InputField(
              controller: _stadiumNameController,
              label: 'Stadium Name',
              hint: 'e.g. Green Arena',
              icon: Icons.stadium_rounded,
            ),
            const SizedBox(height: 12),
            _InputField(
              controller: _descriptionController,
              label: 'About / Description',
              hint: 'Short description for customers',
              icon: Icons.subject_rounded,
              maxLines: 3,
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
              controller: _cityController,
              label: 'City',
              hint: 'e.g. Bengaluru',
              icon: Icons.location_city_rounded,
            ),
            const SizedBox(height: 12),
            _InputField(
              controller: _amenitiesController,
              label: 'Amenities',
              hint: 'e.g. Parking, Washroom, Cafeteria',
              icon: Icons.checklist_rounded,
            ),
            const SizedBox(height: 12),
            const _FieldLabel(label: 'Location / Address'),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _locationController,
                    maxLines: 2,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      color: AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'e.g. 12, MG Road, Bengaluru',
                      prefixIcon: const Icon(
                        Icons.location_on_outlined,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                      hintStyle: const TextStyle(
                        fontFamily: 'Poppins',
                        color: AppColors.textMuted,
                      ),
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppConstants.radiusM,
                        ),
                        borderSide: BorderSide(color: AppColors.divider),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppConstants.radiusM,
                        ),
                        borderSide: BorderSide(color: AppColors.divider),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppConstants.radiusM,
                        ),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _openMapPicker,
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: _selectedLatLng != null
                          ? AppColors.badgeBg
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(AppConstants.radiusM),
                      border: Border.all(
                        color: _selectedLatLng != null
                            ? AppColors.primary
                            : AppColors.divider,
                      ),
                    ),
                    child: Icon(
                      Icons.map_rounded,
                      color: _selectedLatLng != null
                          ? AppColors.primary
                          : AppColors.textSecondary,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
            if (_selectedLatLng != null) ...[
              const SizedBox(height: 6),
              Text(
                '📍 ${_selectedLatLng!.latitude.toStringAsFixed(5)}, ${_selectedLatLng!.longitude.toStringAsFixed(5)}',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  color: AppColors.primary,
                ),
              ),
            ],
            const SizedBox(height: 12),
            const _FieldLabel(label: 'Timings'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _TimePicker(
                    label: 'Opens at',
                    time: _openTime,
                    onTap: () => _pickTime(true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TimePicker(
                    label: 'Closes at',
                    time: _closeTime,
                    onTap: () => _pickTime(false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const _FieldLabel(label: 'Stadium Images'),
            const SizedBox(height: 8),
            _SingleImagePicker(
              imageFile: _stadiumImage,
              onAddTap: _pickStadiumImage,
              onRemove: () => setState(() => _stadiumImage = null),
            ),
            const SizedBox(height: 32),
            const _SectionHeader(title: 'Courts'),
            const SizedBox(height: 14),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _courts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) => _CourtCard(
                courtNumber: index + 1,
                court: _courts[index],
                onPickImage: () => _pickCourtImage(index),
                onPickOpenTime: () => _pickCourtTime(index, true),
                onPickCloseTime: () => _pickCourtTime(index, false),
                onRemove: _courts.length > 1
                    ? () => setState(() => _courts.removeAt(index))
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => setState(() => _courts.add(_CourtFormEntry())),
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

// ── MAP PICKER SCREEN (flutter_map + OSM — 100% FREE) ────────────────────────

class _MapPickerScreen extends StatefulWidget {
  final LatLng initialLocation;
  const _MapPickerScreen({required this.initialLocation});

  @override
  State<_MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<_MapPickerScreen> {
  late LatLng _picked;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _picked = widget.initialLocation;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text(
          'Pick Location',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, _picked),
            child: const Text(
              'Confirm',
              style: TextStyle(
                fontFamily: 'Poppins',
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: widget.initialLocation,
              initialZoom: 15,
              onTap: (tapPosition, latLng) {
                setState(() => _picked = latLng);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.turf_booking',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _picked,
                    width: 40,
                    height: 40,
                    child: GestureDetector(
                      onTap: () {},
                      child: const Icon(
                        Icons.location_pin,
                        color: Colors.red,
                        size: 40,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppConstants.radiusM),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: const Text(
                'Tap on the map to set your stadium location',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            right: 16,
            child: FloatingActionButton.small(
              backgroundColor: Colors.white,
              onPressed: () async {
                try {
                  final pos = await Geolocator.getCurrentPosition();
                  final myLoc = LatLng(pos.latitude, pos.longitude);
                  _mapController.move(myLoc, 15);
                  setState(() => _picked = myLoc);
                } catch (_) {}
              },
              child: const Icon(
                Icons.my_location,
                color: AppColors.primary,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── REUSABLE WIDGETS ──────────────────────────────────────────────────────────

class _SingleImagePicker extends StatelessWidget {
  final File? imageFile;
  final VoidCallback onAddTap;
  final VoidCallback onRemove;
  final bool compact;

  const _SingleImagePicker({
    required this.imageFile,
    required this.onAddTap,
    required this.onRemove,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final double height = compact ? 132 : 150;

    return GestureDetector(
      onTap: onAddTap,
      child: Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppConstants.radiusL),
          border: Border.all(color: AppColors.divider),
        ),
        child: imageFile == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(
                    Icons.add_a_photo_outlined,
                    size: 30,
                    color: AppColors.textMuted,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tap to add image',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              )
            : Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppConstants.radiusL),
                      child: Image.file(imageFile!, fit: BoxFit.cover),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: GestureDetector(
                      onTap: onRemove,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.45),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 15,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 12,
                    bottom: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'Change image',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _ImageSourceTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ImageSourceTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 22),
            const SizedBox(width: 14),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CourtCard extends StatelessWidget {
  final int courtNumber;
  final _CourtFormEntry court;
  final VoidCallback onPickImage;
  final VoidCallback onPickOpenTime;
  final VoidCallback onPickCloseTime;
  final VoidCallback? onRemove;

  const _CourtCard({
    required this.courtNumber,
    required this.court,
    required this.onPickImage,
    required this.onPickOpenTime,
    required this.onPickCloseTime,
    required this.onRemove,
  });

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
          TextField(
            onChanged: (v) => court.equipments = v,
            style: const TextStyle(
              fontFamily: 'Poppins',
              color: AppColors.textPrimary,
            ),
            decoration: _inputDecoration(
              'Equipments',
              'e.g. Ball, Net, Rackets (comma separated)',
              Icons.inventory_2_outlined,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            onChanged: (v) => court.description = v,
            maxLines: 2,
            style: const TextStyle(
              fontFamily: 'Poppins',
              color: AppColors.textPrimary,
            ),
            decoration: _inputDecoration(
              'About / Description',
              'Short note about this court',
              Icons.subject_rounded,
            ),
          ),
          const SizedBox(height: 14),
          _SingleImagePicker(
            imageFile: court.imageFile,
            onAddTap: onPickImage,
            onRemove: () => court.imageFile = null,
            compact: true,
          ),
          const SizedBox(height: 14),
          const _FieldLabel(label: 'Hourly Rate (₹)'),
          const SizedBox(height: 10),
          _RateRow(label: 'Hourly', onChanged: (v) => court.pricePerHour = v),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _TimePickerButton(
                  label: 'Start Time',
                  value: court.openTime ?? const TimeOfDay(hour: 6, minute: 0),
                  onTap: onPickOpenTime,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TimePickerButton(
                  label: 'End Time',
                  value:
                      court.closeTime ?? const TimeOfDay(hour: 22, minute: 0),
                  onTap: onPickCloseTime,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TimePickerButton extends StatelessWidget {
  final String label;
  final TimeOfDay value;
  final VoidCallback onTap;

  const _TimePickerButton({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value.format(context),
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RateRow extends StatelessWidget {
  final String label;
  final ValueChanged<double> onChanged;

  const _RateRow({required this.label, required this.onChanged});

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
