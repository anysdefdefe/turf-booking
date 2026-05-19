import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:turf_booking/features/auth/providers/auth_controller.dart';
import 'package:go_router/go_router.dart';
import '../../../app/constants/app_constants.dart';
import '../../../app/theme/theme_controller.dart';
import '../../../app/theme/theme_mode_selector.dart';
import '../widgets/customer_bottom_nav_bar.dart';
import 'package:turf_booking/features/owner/widgets/storage_media.dart';
import 'package:turf_booking/shared/services/storage_image_service.dart';

DateTime _parseCreatedAt(dynamic value, dynamic fallback) {
  if (value is DateTime) return value;
  if (value is String) {
    final parsed = DateTime.tryParse(value);
    if (parsed != null) return parsed;
  }
  if (fallback is DateTime) return fallback;
  return DateTime.now();
}

class _ProfileData {
  final String id;
  final String email;
  final String fullName;
  final String phone;
  final String avatarStoragePath;
  final bool isOwner;
  final bool isApproved;
  final bool isAdmin;
  final DateTime createdAt;

  const _ProfileData({
    required this.id,
    required this.email,
    required this.fullName,
    required this.phone,
    required this.avatarStoragePath,
    required this.isOwner,
    required this.isApproved,
    required this.isAdmin,
    required this.createdAt,
  });

  _ProfileData copyWith({
    String? fullName,
    String? phone,
    String? avatarStoragePath,
  }) {
    return _ProfileData(
      id: id,
      email: email,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      avatarStoragePath: avatarStoragePath ?? this.avatarStoragePath,
      isOwner: isOwner,
      isApproved: isApproved,
      isAdmin: isAdmin,
      createdAt: createdAt,
    );
  }

  factory _ProfileData.fromSession({
    required Session session,
    required User user,
    Map<String, dynamic>? row,
  }) {
    final metadata = user.userMetadata ?? const <String, dynamic>{};
    final rowData = row ?? const <String, dynamic>{};

    return _ProfileData(
      id: user.id,
      email: user.email ?? rowData['email'] as String? ?? '',
      fullName:
          (rowData['full_name'] as String?) ??
          (metadata['full_name'] as String?) ??
          user.email?.split('@').first ??
          'Profile',
      phone: rowData['phone'] as String? ?? '',
      avatarStoragePath: rowData['avatar_url'] as String? ?? '',
      isOwner: rowData['is_owner'] as bool? ?? false,
      isApproved: rowData['is_approved'] as bool? ?? false,
      isAdmin: rowData['is_admin'] as bool? ?? false,
      createdAt: _parseCreatedAt(rowData['created_at'], user.createdAt),
    );
  }
}

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _client = Supabase.instance.client;
  late final StorageImageService _storageImageService;

  _ProfileData? _profile;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _storageImageService = StorageImageService(_client);
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final session = _client.auth.currentSession;
      final user = _client.auth.currentUser;

      if (session == null || user == null) {
        throw Exception('No active session found');
      }

      final row = await _client
          .from('users')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (!mounted) return;
      setState(() {
        _profile = _ProfileData.fromSession(
          session: session,
          user: user,
          row: row,
        );
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _onNavTap(int index) {
    if (index == 2) return;
    if (index == 0) {
      context.go('/customer/home');
      return;
    }
    if (index == 1) {
      context.go('/customer/my-bookings');
      return;
    }
  }

  void _switchMode() {
    context.go('/mode-selection');
  }

  Future<void> _openThemeSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => const Padding(
        padding: EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: ThemeModeSelector(title: 'Appearance'),
      ),
    );
  }

  String _themeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }

  Future<void> _openEditSheet() async {
    final current = _profile;
    if (current == null) return;

    final updated = await showModalBottomSheet<_ProfileEditResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditProfileSheet(current: current),
    );

    if (updated == null) return;

    await _saveProfile(updated);
  }

  Future<void> _saveProfile(_ProfileEditResult result) async {
    final current = _profile;
    if (current == null) return;

    setState(() => _isLoading = true);

    try {
      final email = current.email.isNotEmpty
          ? current.email
          : _client.auth.currentUser?.email;
      if (email == null || email.isEmpty) {
        throw Exception('No email found for the current profile');
      }

      var avatarStoragePath = current.avatarStoragePath;
      if (result.avatarFile != null) {
        final selectedFile = result.avatarFile!;
        await _storageImageService.validatePickedImage(selectedFile);
        avatarStoragePath =
            await _storageImageService.uploadImageBytes(
              bucketName: AppConstants.storageImageBucket,
              ownerId: current.id,
              folder: AppConstants.storageProfileImageFolder,
              sourcePath: selectedFile.path,
              bytes: await selectedFile.readAsBytes(),
              oldStoragePath: current.avatarStoragePath,
            ) ??
            avatarStoragePath;
      }

      final profile = result.profile.copyWith(
        avatarStoragePath: avatarStoragePath,
      );

      final payload = {
        'id': profile.id,
        'email': email,
        'full_name': profile.fullName,
        'phone': profile.phone.isEmpty ? null : profile.phone,
        'avatar_url': profile.avatarStoragePath.isEmpty
            ? null
            : profile.avatarStoragePath,
        'is_owner': profile.isOwner,
        'is_approved': profile.isApproved,
        'is_admin': profile.isAdmin,
      };

      await _client.from('users').upsert(payload, onConflict: 'id');

      if (!mounted) return;
      setState(() {
        _profile = profile;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to update profile: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _handleLogout() async {
    final cs = Theme.of(context).colorScheme;

    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 32,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: cs.errorContainer,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(Icons.logout_rounded, color: cs.error, size: 26),
                ),
                const SizedBox(height: 20),
                Text(
                  'Log out?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'You will need to sign in again\nto continue using the app.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w400,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: cs.outlineVariant,
                            width: 1.2,
                          ),
                          foregroundColor: cs.onSurface,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: cs.error,
                          foregroundColor: cs.onError,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Text(
                          'Log out',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (shouldLogout != true || !mounted) {
      return;
    }

    await ref.read(authControllerProvider.notifier).signOut();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final profile = _profile;

    return Scaffold(
      backgroundColor: cs.surface,
      bottomNavigationBar: CustomerBottomNavBar(
        selectedIndex: 2,
        onTap: _onNavTap,
      ),
      appBar: AppBar(
        backgroundColor: cs.surface,
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: false,
        title: const Text('Profile'),
      ),
      body: _isLoading && profile == null
          ? Center(child: CircularProgressIndicator(color: cs.primary))
          : RefreshIndicator(
              onRefresh: _loadProfile,
              color: cs.primary,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 32),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  if (_error != null) ...[
                    _ErrorBanner(message: _error!),
                    const SizedBox(height: 16),
                  ],
                  if (profile != null) ...[
                    _ProfileHeaderPanel(
                      profile: profile,
                      onEdit: _openEditSheet,
                      onLogout: _handleLogout,
                    ),
                    const SizedBox(height: 18),
                    _SettingsGroupCard(
                      title: 'General settings',
                      children: [
                        _SettingsStaticRow(label: 'Language', value: 'English'),
                        ValueListenableBuilder<ThemeMode>(
                          valueListenable: ThemeController.instance,
                          builder: (context, currentMode, _) {
                            return _SettingsActionRow(
                              label: 'Appearance',
                              trailingText: _themeLabel(currentMode),
                              onTap: _openThemeSheet,
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _SettingsGroupCard(
                      title: 'Account settings',
                      children: [
                        _SettingsActionRow(
                          label: 'My bookings',
                          onTap: () => context.go('/customer/my-bookings'),
                        ),
                        _SettingsActionRow(
                          label: 'Switch role',
                          onTap: _switchMode,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _SettingsGroupCard(
                      title: 'Support',
                      children: [
                        _SettingsActionRow(
                          label: 'Help & support',
                          onTap: () {},
                        ),
                        _SettingsActionRow(
                          label: 'Privacy policy',
                          onTap: () {},
                        ),
                      ],
                    ),
                  ] else ...[
                    const SizedBox(height: 32),
                    Center(
                      child: Text(
                        'Unable to load profile data.',
                        style: TextStyle(color: cs.onSurfaceVariant),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

class _ProfileHeaderPanel extends StatelessWidget {
  final _ProfileData profile;
  final VoidCallback onEdit;
  final VoidCallback onLogout;

  const _ProfileHeaderPanel({
    required this.profile,
    required this.onEdit,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        Row(
          children: [
            const Spacer(),
            _EditButton(onTap: onEdit),
            const SizedBox(width: 8),
            _LogoutIconButton(onTap: onLogout),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          width: 98,
          height: 98,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: cs.surfaceContainerLowest,
            border: Border.all(color: cs.outlineVariant, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: cs.shadow.withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: StorageAvatar(
            storagePath: profile.avatarStoragePath,
            bucketName: AppConstants.storageImageBucket,
            displayName: profile.fullName,
            radius: 49,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          profile.fullName,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
            letterSpacing: -0.25,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          profile.email,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            color: cs.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _SettingsGroupCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsGroupCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          ...children,
        ],
      ),
    );
  }
}

class _SettingsActionRow extends StatelessWidget {
  final String label;
  final String? trailingText;
  final VoidCallback onTap;

  const _SettingsActionRow({
    required this.label,
    required this.onTap,
    this.trailingText,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 11),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: cs.onSurface,
                ),
              ),
            ),
            if (trailingText != null)
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Text(
                  trailingText!,
                  style: TextStyle(
                    fontSize: 13,
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: cs.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsStaticRow extends StatelessWidget {
  final String label;
  final String value;

  const _SettingsStaticRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 11),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: cs.onSurface,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Edit Profile Bottom Sheet ───────────────────────────────────────────────

class _EditProfileSheet extends StatefulWidget {
  final _ProfileData current;

  const _EditProfileSheet({required this.current});

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  final _imagePicker = ImagePicker();
  XFile? _selectedAvatar;
  String? _selectionError;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.current.fullName);
    _phoneCtrl = TextEditingController(text: widget.current.phone);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final selected = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (selected == null) return;

    try {
      final service = StorageImageService(Supabase.instance.client);
      await service.validatePickedImage(selected);
      if (!mounted) return;
      setState(() {
        _selectedAvatar = selected;
        _selectionError = null;
      });
    } on FormatException catch (error) {
      if (!mounted) return;
      setState(() {
        _selectionError = error.message;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  void _save() {
    final fullName = _nameCtrl.text.trim();
    if (fullName.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Name is required')));
      return;
    }

    Navigator.pop(
      context,
      _ProfileEditResult(
        profile: widget.current.copyWith(
          fullName: fullName,
          phone: _phoneCtrl.text.trim(),
        ),
        avatarFile: _selectedAvatar,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomInset =
        mediaQuery.viewInsets.bottom + mediaQuery.padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 14, bottom: 20),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          Text(
            'Edit Profile',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Update your personal information',
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          _SheetField(
            controller: _nameCtrl,
            label: 'Full Name',
            icon: Icons.person_outline_rounded,
            inputType: TextInputType.name,
          ),
          const SizedBox(height: 14),
          _SheetField(
            controller: _phoneCtrl,
            label: 'Phone Number',
            icon: Icons.phone_outlined,
            inputType: TextInputType.phone,
          ),
          const SizedBox(height: 14),
          _ProfileImagePicker(
            current: widget.current,
            selectedAvatar: _selectedAvatar,
            onPickImage: _pickAvatar,
          ),
          if (_selectionError != null) ...[
            const SizedBox(height: 10),
            Text(
              _selectionError!,
              style: TextStyle(
                fontSize: 12.5,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                textStyle: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              child: const Text('Save Changes'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileEditResult {
  final _ProfileData profile;
  final XFile? avatarFile;

  const _ProfileEditResult({required this.profile, this.avatarFile});
}

// ─── Avatar Picker Widget ───────────────────────────────────────────────────

class _ProfileImagePicker extends StatelessWidget {
  final _ProfileData current;
  final XFile? selectedAvatar;
  final VoidCallback onPickImage;

  const _ProfileImagePicker({
    required this.current,
    required this.selectedAvatar,
    required this.onPickImage,
  });

  @override
  Widget build(BuildContext context) {
    final hasSelectedAvatar = selectedAvatar != null;
    final hasStoredAvatar = current.avatarStoragePath.isNotEmpty;

    return GestureDetector(
      onTap: onPickImage,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerLowest,
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: hasSelectedAvatar
                          ? Image.file(
                              File(selectedAvatar!.path),
                              fit: BoxFit.cover,
                              width: 88,
                              height: 88,
                            )
                          : hasStoredAvatar
                          ? StorageAvatar(
                              storagePath: current.avatarStoragePath,
                              bucketName: AppConstants.storageImageBucket,
                              displayName: current.fullName,
                              radius: 44,
                            )
                          : Icon(
                              Icons.person_outline_rounded,
                              size: 36,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                    ),
                  ),
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).colorScheme.surface,
                        width: 2.5,
                      ),
                    ),
                    child: Icon(
                      Icons.camera_alt_rounded,
                      size: 13,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Upload profile image',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'JPG or PNG only, under 10 MB',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: onPickImage,
                      icon: const Icon(Icons.upload_rounded, size: 18),
                      label: const Text('Choose image'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Sheet Field ─────────────────────────────────────────────────────────────

class _SheetField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType inputType;

  const _SheetField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.inputType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: inputType,
      style: TextStyle(
        fontSize: 13.5,
        color: Theme.of(context).colorScheme.onSurface,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          fontSize: 12.5,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        prefixIcon: Icon(
          icon,
          size: 18,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceContainerLowest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
      ),
    );
  }
}

// ─── Profile Hero Card ───────────────────────────────────────────────────────

// ─── Error Banner ────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.errorContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.error.withValues(alpha: 0.35)),
      ),
      child: Text(
        message,
        style: TextStyle(
          fontSize: 12.5,
          color: cs.onErrorContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ─── Logout Button ───────────────────────────────────────────────────────────

class _LogoutIconButton extends StatelessWidget {
  final VoidCallback onTap;

  const _LogoutIconButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: cs.onSurfaceVariant.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Icon(Icons.logout_rounded, size: 18, color: cs.onSurfaceVariant),
      ),
    );
  }
}

class _EditButton extends StatelessWidget {
  final VoidCallback onTap;

  const _EditButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.edit_rounded,
              size: 13,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 5),
            Text(
              'Edit',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
