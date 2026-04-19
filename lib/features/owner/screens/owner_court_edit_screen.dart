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
  final _openTimeController = TextEditingController();
  final _closeTimeController = TextEditingController();
  late bool _isActive;
  bool _isSaving = false;
  bool _initialized = false;

  @override
  void dispose() {
    _nameController.dispose();
    _sportController.dispose();
    _priceController.dispose();
    _equipmentController.dispose();
    _openTimeController.dispose();
    _closeTimeController.dispose();
    super.dispose();
  }

  void _initFields(CourtModel court) {
    if (_initialized) return;
    _nameController.text = court.name;
    _sportController.text = court.sportType;
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
      initialTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }
    final time = await showTimePicker(context: context, initialTime: initialTime);
    if (time != null && mounted) {
      controller.text = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00';
    }
  }

  Future<void> _save(String stadiumId) async {
    final name = _nameController.text.trim();
    final sport = _sportController.text.trim();
    final price = double.tryParse(_priceController.text.trim());
    final equipments = _parseCsv(_equipmentController.text);
    final openTime = _openTimeController.text.trim();
    final closeTime = _closeTimeController.text.trim();

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
            openTime: openTime,
            closeTime: closeTime,
            isActive: _isActive,
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
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
        ),
      ),
    );
  }

  void _showMaintenanceSheet(BuildContext context, String courtId, String stadiumId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MaintenanceBlockSheet(courtId: courtId, stadiumId: stadiumId),
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
                                  child: _buildField(_openTimeController, hint: '06:00:00'),
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
                                  child: _buildField(_closeTimeController, hint: '22:00:00'),
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

                    const SizedBox(height: 32),
                    const Divider(),
                    const SizedBox(height: 24),
                    const Text(
                      'Maintenance & Blocking',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Block off specific hours so customers cannot book them. This will act as a phantom booking and will not affect your revenue.',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _showMaintenanceSheet(context, widget.courtId, stadium.id),
                        icon: const Icon(Icons.build_circle_outlined, size: 18),
                        label: const Text('Add Maintenance Block'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppConstants.radiusM),
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

class _MaintenanceBlockSheet extends ConsumerStatefulWidget {
  final String courtId;
  final String stadiumId;

  const _MaintenanceBlockSheet({required this.courtId, required this.stadiumId});

  @override
  ConsumerState<_MaintenanceBlockSheet> createState() => _MaintenanceBlockSheetState();
}

class _MaintenanceBlockSheetState extends ConsumerState<_MaintenanceBlockSheet> {
  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _isSaving = false;

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null && mounted) {
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _pickTime(bool isStart) async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time != null && mounted) {
      setState(() {
        if (isStart) _startTime = time;
        else _endTime = time;
      });
    }
  }

  Future<void> _submit() async {
    if (_selectedDate == null || _startTime == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select Date, Start Time and End Time', style: TextStyle(fontFamily: 'Poppins'))),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await ref.read(stadiumRepositoryProvider).createMaintenanceSlot(
        courtId: widget.courtId,
        date: _selectedDate!,
        startTime: _startTime!,
        endTime: _endTime!,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Maintenance block added successfully', style: TextStyle(fontFamily: 'Poppins')),
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      print('MAINTENANCE ERROR: $e');
      if (mounted) {
        Navigator.pop(context); // Pop bottom sheet to reveal the original screen
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e', style: const TextStyle(fontFamily: 'Poppins')),
            backgroundColor: AppColors.error,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'New Maintenance Block',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_today_outlined, size: 18),
                  label: Text(
                    _selectedDate == null
                        ? 'Select Date'
                        : '${_selectedDate!.day.toString().padLeft(2, '0')}/${_selectedDate!.month.toString().padLeft(2, '0')}/${_selectedDate!.year}',
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickTime(true),
                  icon: const Icon(Icons.access_time, size: 18),
                  label: Text(
                    _startTime == null
                        ? 'Start Time'
                        : _startTime!.format(context),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickTime(false),
                  icon: const Icon(Icons.access_time_filled, size: 18),
                  label: Text(
                    _endTime == null ? 'End Time' : _endTime!.format(context),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: _isSaving ? null : _submit,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isSaving
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text(
                    'Confirm Maintenace Block',
                    style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700),
                  ),
          ),
        ],
      ),
    );
  }
}
