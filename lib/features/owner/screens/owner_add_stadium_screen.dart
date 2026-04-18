import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:turf_booking/app/constants/app_constants.dart';
import 'package:turf_booking/app/theme/app_colors.dart';
import '../widgets/owner_bottom_nav_bar.dart';

// ── MODELS ────────────────────────────────────────────────────────────────────

class CourtEntry {
  String sportType;
  String amenities;
  double hourlyRate;
  double monthlyRate;
  double yearlyRate;
  List<File> images;

  CourtEntry({
    this.sportType = '',
    this.amenities = '',
    this.hourlyRate = 0,
    this.monthlyRate = 0,
    this.yearlyRate = 0,
    List<File>? images,
  }) : images = images ?? [];
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
  final List<File> _stadiumImages = [];

  LatLng? _selectedLatLng; // latlong2.LatLng — no API key needed
  bool _isSaving = false;

  final _supabase = Supabase.instance.client;
  final _imagePicker = ImagePicker();

  @override
  void dispose() {
    _stadiumNameController.dispose();
    _contactController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  // ── TIME PICKER ────────────────────────────────────────────────
  Future<void> _pickTime(bool isOpen) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isOpen ? _openTime : _closeTime,
    );
    if (picked != null) {
      setState(() {
        if (isOpen)
          _openTime = picked;
        else
          _closeTime = picked;
      });
    }
  }

  // ── IMAGE PICKER ───────────────────────────────────────────────
  Future<void> _pickImages({required bool forCourt, int? courtIndex}) async {
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
                      if (forCourt && courtIndex != null) {
                        _courts[courtIndex].images.add(File(xfile.path));
                      } else {
                        _stadiumImages.add(File(xfile.path));
                      }
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
                      if (forCourt && courtIndex != null) {
                        _courts[courtIndex].images.addAll(
                          files.map((f) => File(f.path)),
                        );
                      } else {
                        _stadiumImages.addAll(files.map((f) => File(f.path)));
                      }
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
        }
      } catch (_) {}
    }
  }

  // ── UPLOAD IMAGE ───────────────────────────────────────────────
  Future<String?> _uploadImage(File file, String bucket) async {
    try {
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
      await _supabase.storage.from(bucket).upload(fileName, file);
      return _supabase.storage.from(bucket).getPublicUrl(fileName);
    } catch (e) {
      return null;
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
    for (int i = 0; i < _courts.length; i++) {
      if (_courts[i].sportType.trim().isEmpty) {
        _showSnackbar('Please enter sport type for Court ${i + 1}');
        return false;
      }
    }
    return true;
  }

  // ── SAVE TO SUPABASE ───────────────────────────────────────────
  Future<void> _save() async {
    if (!_validate()) return;
    setState(() => _isSaving = true);
    try {
      final ownerId = _supabase.auth.currentUser!.id;

      final List<String> stadiumImageUrls = [];
      for (final img in _stadiumImages) {
        final url = await _uploadImage(img, 'stadium-images');
        if (url != null) stadiumImageUrls.add(url);
      }

      final stadiumResponse = await _supabase
          .from('stadiums')
          .insert({
            'owner_id': ownerId,
            'name': _stadiumNameController.text.trim(),
            'address': _locationController.text.trim(),
            'latitude': _selectedLatLng?.latitude,
            'longitude': _selectedLatLng?.longitude,
            'image_urls': stadiumImageUrls,
            'is_active': true,
          })
          .select()
          .single();

      final stadiumId = stadiumResponse['id'] as String;

      for (final court in _courts) {
        final List<String> courtImageUrls = [];
        for (final img in court.images) {
          final url = await _uploadImage(img, 'court-images');
          if (url != null) courtImageUrls.add(url);
        }
        await _supabase.from('courts').insert({
          'stadium_id': stadiumId,
          'name': court.sportType.trim(),
          'sport': court.sportType.trim(),
          'hourly_rate': court.hourlyRate,
          'monthly_rate': court.monthlyRate,
          'yearly_rate': court.yearlyRate,
          'is_available': true,
        });
      }

      if (!mounted) return;
      _showSnackbar('✓ Stadium added successfully!');
      Navigator.pop(context);
    } catch (e) {
      _showSnackbar('Error saving: ${e.toString()}');
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
            child: _isSaving
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
              controller: _contactController,
              label: 'Owner Contact',
              hint: 'e.g. +91 98765 43210',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
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
            _ImageGrid(
              images: _stadiumImages,
              onAddTap: () => _pickImages(forCourt: false),
              onRemove: (i) => setState(() => _stadiumImages.removeAt(i)),
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
                onRemove: _courts.length > 1
                    ? () => setState(() => _courts.removeAt(index))
                    : null,
                onAddImages: () =>
                    _pickImages(forCourt: true, courtIndex: index),
                onRemoveImage: (imgIndex) =>
                    setState(() => _courts[index].images.removeAt(imgIndex)),
              ),
            ),
            const SizedBox(height: 16),
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
              // OpenStreetMap tile layer — completely free, no key
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.turf_booking',
              ),
              // Draggable marker
              MarkerLayer(
                markers: [
                  Marker(
                    point: _picked,
                    width: 40,
                    height: 40,
                    child: GestureDetector(
                      onTap: () {}, // marker tap (optional)
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
          // Instruction banner
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
          // My location button
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

// ── All widgets below are UNCHANGED from original ─────────────────────────────

class _ImageGrid extends StatelessWidget {
  final List<File> images;
  final VoidCallback onAddTap;
  final void Function(int index) onRemove;

  const _ImageGrid({
    required this.images,
    required this.onAddTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        ...images.asMap().entries.map(
          (e) => _ImageThumb(file: e.value, onRemove: () => onRemove(e.key)),
        ),
        GestureDetector(
          onTap: onAddTap,
          child: Container(
            width: 90,
            height: 90,
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
                  size: 24,
                  color: AppColors.textMuted,
                ),
                SizedBox(height: 4),
                Text(
                  'Add',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ImageThumb extends StatelessWidget {
  final File file;
  final VoidCallback onRemove;

  const _ImageThumb({required this.file, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          child: Image.file(file, width: 90, height: 90, fit: BoxFit.cover),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
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
  final CourtEntry court;
  final VoidCallback? onRemove;
  final VoidCallback onAddImages;
  final void Function(int) onRemoveImage;

  const _CourtCard({
    required this.courtNumber,
    required this.court,
    required this.onRemove,
    required this.onAddImages,
    required this.onRemoveImage,
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
          const _FieldLabel(label: 'Court Images'),
          const SizedBox(height: 8),
          _ImageGrid(
            images: court.images,
            onAddTap: onAddImages,
            onRemove: onRemoveImage,
          ),
          const SizedBox(height: 14),
          const _FieldLabel(label: 'Booking Rates (₹)'),
          const SizedBox(height: 10),
          _RateRow(label: 'Hourly', onChanged: (v) => court.hourlyRate = v),
          const SizedBox(height: 8),
          _RateRow(label: 'Monthly', onChanged: (v) => court.monthlyRate = v),
          const SizedBox(height: 8),
          _RateRow(label: 'Yearly', onChanged: (v) => court.yearlyRate = v),
        ],
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
