import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:turf_booking/app/constants/app_constants.dart';
import 'package:turf_booking/features/owner/data/repositories/stadium_repository.dart';

class OwnerBlockManagementScreen extends ConsumerStatefulWidget {
  final String courtId;
  const OwnerBlockManagementScreen({super.key, required this.courtId});

  @override
  ConsumerState<OwnerBlockManagementScreen> createState() =>
      _OwnerBlockManagementScreenState();
}

class _OwnerBlockManagementScreenState
    extends ConsumerState<OwnerBlockManagementScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _existingBlocks = [];
  final List<Map<String, dynamic>> _pendingBlocks = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadExistingBlocks();
  }

  Future<void> _loadExistingBlocks() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(stadiumRepositoryProvider);
      final blocks = await repo.getBlockedSlots(widget.courtId);
      if (mounted) {
        setState(() {
          _existingBlocks = blocks;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error loading blocks: $e',
              style: const TextStyle(fontFamily: 'Poppins'),
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _savePendingBlocks() async {
    if (_pendingBlocks.isEmpty) return;

    setState(() => _isSaving = true);
    try {
      final repo = ref.read(stadiumRepositoryProvider);
      await repo.addBlockedSlots(_pendingBlocks);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Blocks saved successfully',
              style: TextStyle(fontFamily: 'Poppins'),
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
        setState(() {
          _pendingBlocks.clear();
        });
        await _loadExistingBlocks();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error saving blocks: $e',
              style: const TextStyle(fontFamily: 'Poppins'),
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _unblockSlot(String blockId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unblock Slot'),
        content: const Text('Are you sure you want to unblock this slot?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
            child: const Text('Unblock'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final repo = ref.read(stadiumRepositoryProvider);
      await repo.unblockSlot(blockId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Slot unblocked successfully',
              style: TextStyle(fontFamily: 'Poppins'),
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
        await _loadExistingBlocks();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error unblocking slot: $e',
              style: const TextStyle(fontFamily: 'Poppins'),
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _showAddBlockSheet() {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddBlockSheet(
        courtId: widget.courtId,
        onAdd: (block) {
          setState(() {
            _pendingBlocks.add(block);
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        title: Text(
          'Manage Blocked Slots',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(AppConstants.paddingL),
              children: [
                if (_pendingBlocks.isNotEmpty) ...[
                  Text(
                    'Pending Blocks (Not Saved)',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._pendingBlocks.asMap().entries.map((e) {
                    final index = e.key;
                    final block = e.value;
                    return _buildBlockCard(
                      block,
                      isPending: true,
                      onDelete: () {
                        setState(() {
                          _pendingBlocks.removeAt(index);
                        });
                      },
                    );
                  }),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _isSaving ? null : _savePendingBlocks,
                    style: FilledButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
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
                            'Save All Pending Blocks',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 24),
                ],
                Text(
                  'Active Blocked Slots',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                if (_existingBlocks.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Text(
                        'No blocked slots yet.',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  )
                else
                  ..._existingBlocks.map(
                    (block) => _buildBlockCard(
                      block,
                      isPending: false,
                      onUnblock: () => _unblockSlot(block['id']),
                    ),
                  ),
                const SizedBox(height: 80), // Padding for FAB
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddBlockSheet,
        elevation: 4,
        backgroundColor: Theme.of(context).colorScheme.error,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Add Block',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildBlockCard(
    Map<String, dynamic> block, {
    required bool isPending,
    VoidCallback? onDelete,
    VoidCallback? onUnblock,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isPending
            ? Theme.of(
                context,
              ).colorScheme.errorContainer.withValues(alpha: 0.2)
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isPending
              ? Theme.of(context).colorScheme.error.withValues(alpha: 0.5)
              : Theme.of(
                  context,
                ).colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      block['block_date'],
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${block['start_time']} - ${block['end_time']}',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                if (block['reason'] != null &&
                    block['reason'].toString().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Reason: ${block['reason']}',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (isPending && onDelete != null)
            IconButton.filledTonal(
              icon: const Icon(Icons.close, size: 18),
              style: IconButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.errorContainer,
                foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
              ),
              onPressed: onDelete,
            ),
          if (!isPending && onUnblock != null)
            OutlinedButton.icon(
              onPressed: onUnblock,
              icon: const Icon(Icons.lock_open, size: 16),
              label: const Text('Unblock', style: TextStyle(fontSize: 12)),
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
                side: BorderSide(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.5),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AddBlockSheet extends StatefulWidget {
  final String courtId;
  final ValueChanged<Map<String, dynamic>> onAdd;

  const _AddBlockSheet({required this.courtId, required this.onAdd});

  @override
  State<_AddBlockSheet> createState() => _AddBlockSheetState();
}

class _AddBlockSheetState extends State<_AddBlockSheet> {
  DateTime? _selectedDate;
  int? _startHour;
  int? _endHour;
  final _reasonController = TextEditingController();
  String? _errorMessage;

  final List<int> _hours = List.generate(24, (index) => index);

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    // 7 days from now
    final minDate = DateTime.now().add(const Duration(days: 7));
    final date = await showDatePicker(
      context: context,
      initialDate: minDate,
      firstDate: minDate,
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (date != null && mounted) {
      setState(() => _selectedDate = date);
    }
  }

  void _submit() {
    setState(() => _errorMessage = null);

    if (_selectedDate == null || _startHour == null || _endHour == null) {
      setState(
        () => _errorMessage = 'Please select Date, Start Hour and End Hour',
      );
      return;
    }

    final start = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _startHour!,
      0,
    );
    final end = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _endHour!,
      0,
    );

    if (end.isBefore(start) || end.isAtSameMomentAs(start)) {
      setState(() => _errorMessage = 'End time must be after start time');
      return;
    }

    final String dateStr =
        '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}';
    final stStr = '${_startHour!.toString().padLeft(2, '0')}:00:00';
    final etStr = '${_endHour!.toString().padLeft(2, '0')}:00:00';

    final block = {
      'court_id': widget.courtId,
      'block_date': dateStr,
      'start_time': stStr,
      'end_time': etStr,
      'reason': _reasonController.text.trim(),
      'status': 'blocked',
    };

    widget.onAdd(block);
    Navigator.pop(context);
  }

  String _formatHour(int h) {
    final period = h >= 12 ? 'PM' : 'AM';
    final hour12 = h % 12 == 0 ? 12 : h % 12;
    return '${hour12.toString().padLeft(2, '0')}:00 $period';
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: mediaQuery.viewInsets.bottom + mediaQuery.padding.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'New Block Slot',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_today_outlined, size: 18),
            label: Text(
              _selectedDate == null
                  ? 'Select Date (Min 7 days from now)'
                  : '${_selectedDate!.day.toString().padLeft(2, '0')}/${_selectedDate!.month.toString().padLeft(2, '0')}/${_selectedDate!.year}',
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: _startHour,
                  decoration: InputDecoration(
                    labelText: 'Start Hour',
                    labelStyle: TextStyle(
                      fontFamily: 'Poppins',
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                  items: _hours
                      .map(
                        (h) => DropdownMenuItem(
                          value: h,
                          child: Text(
                            _formatHour(h),
                            style: const TextStyle(fontFamily: 'Poppins'),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (val) => setState(() => _startHour = val),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: _endHour,
                  decoration: InputDecoration(
                    labelText: 'End Hour',
                    labelStyle: TextStyle(
                      fontFamily: 'Poppins',
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                  items: _hours
                      .map(
                        (h) => DropdownMenuItem(
                          value: h,
                          child: Text(
                            _formatHour(h),
                            style: const TextStyle(fontFamily: 'Poppins'),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (val) => setState(() => _endHour = val),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _reasonController,
            maxLines: 2,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            decoration: InputDecoration(
              hintText: 'Reason for blocking (optional)',
              hintStyle: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.3),
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
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
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 16,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _submit,
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Add to List',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
