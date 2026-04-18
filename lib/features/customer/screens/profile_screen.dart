import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:turf_booking/features/auth/providers/auth_controller.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../data/repositories/customer_preferences_repository.dart';
import '../widgets/customer_floating_nav_bar.dart';

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
  final String avatarUrl;
  final bool isOwner;
  final bool isApproved;
  final bool isAdmin;
  final DateTime createdAt;

  const _ProfileData({
    required this.id,
    required this.email,
    required this.fullName,
    required this.phone,
    required this.avatarUrl,
    required this.isOwner,
    required this.isApproved,
    required this.isAdmin,
    required this.createdAt,
  });

  _ProfileData copyWith({String? fullName, String? phone, String? avatarUrl}) {
    return _ProfileData(
      id: id,
      email: email,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
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
      avatarUrl: rowData['avatar_url'] as String? ?? '',
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
  static const bool _isOwner = false;
  static const bool _isApproved = false;

  final _client = Supabase.instance.client;

  _ProfileData? _profile;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
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
    }
  }

  Future<void> _openEditSheet() async {
    final current = _profile;
    if (current == null) return;

    final updated = await showModalBottomSheet<_ProfileData>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditProfileSheet(current: current),
    );

    if (updated == null) return;

    await _saveProfile(updated);
  }

  Future<void> _saveProfile(_ProfileData profile) async {
    setState(() => _isLoading = true);

    try {
      final payload = {
        'id': profile.id,
        'full_name': profile.fullName,
        'phone': profile.phone.isEmpty ? null : profile.phone,
        'avatar_url': profile.avatarUrl.isEmpty ? null : profile.avatarUrl,
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
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
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
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFFFEE2E2),
                        const Color(0xFFFECACA).withOpacity(0.6),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    color: Color(0xFFDC2626),
                    size: 26,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Log out?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0A0A0B),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'You will need to sign in again\nto continue using the app.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: const Color(0xFF71717A),
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
                          side: const BorderSide(
                            color: Color(0xFFE4E4E7),
                            width: 1.2,
                          ),
                          foregroundColor: const Color(0xFF0A0A0B),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
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
                          backgroundColor: const Color(0xFFDC2626),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          'Log out',
                          style: TextStyle(
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
    final likedIds = CustomerPreferencesRepository.instance.likedCourtIds.value;
    final profile = _profile;

    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: CustomerFloatingNavBar(
        selectedIndex: 2,
        onTap: _onNavTap,
      ),
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: false,
        title: Text(
          'Profile',
          style: TextStyle(
            fontSize: 22,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _EditButton(onTap: _openEditSheet),
          ),
        ],
      ),
      body: _isLoading && profile == null
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF0A0A0B)),
            )
          : RefreshIndicator(
              onRefresh: _loadProfile,
              color: const Color(0xFF0A0A0B),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  if (_error != null) ...[
                    _ErrorBanner(message: _error!),
                    const SizedBox(height: 16),
                  ],
                  if (profile != null) ...[
                    _ProfileHeroCard(profile: profile),
                    const SizedBox(height: 20),
                    _isOwner
                        ? const _OwnerStatsRow()
                        : _CustomerStatsRow(likedCount: likedIds.length),
                    const SizedBox(height: 20),
                    _isOwner
                        ? const _OwnerInfoCard(isApproved: _isApproved)
                        : const _CustomerInfoCard(),
                    const SizedBox(height: 24),
                    _ProfileDetailsCard(profile: profile),
                    const SizedBox(height: 24),
                    const _SectionLabel(label: 'Account'),
                    const SizedBox(height: 10),
                    _ActionTile(
                      icon: Icons.receipt_long_rounded,
                      label: 'My Bookings',
                      onTap: () => context.go('/customer/my-bookings'),
                    ),
                    _ActionTile(
                      icon: Icons.favorite_border_rounded,
                      label: 'Wishlist',
                      trailing: likedIds.isNotEmpty
                          ? _Badge(count: likedIds.length)
                          : null,
                      onTap: () => context.go('/customer/home', extra: {'feed': 'wishlist'}),
                    ),
                    _ActionTile(
                      icon: Icons.notifications_none_rounded,
                      label: 'Notifications',
                      onTap: () {},
                    ),
                    const SizedBox(height: 20),
                    const _SectionLabel(label: 'General'),
                    const SizedBox(height: 10),
                    _ActionTile(
                      icon: Icons.help_outline_rounded,
                      label: 'Help & Support',
                      onTap: () {},
                    ),
                    _ActionTile(
                      icon: Icons.privacy_tip_outlined,
                      label: 'Privacy Policy',
                      onTap: () {},
                    ),
                    const SizedBox(height: 24),
                    _LogoutButton(onTap: _handleLogout),
                  ] else ...[
                    const SizedBox(height: 32),
                    const Center(child: Text('Unable to load profile data.')),
                  ],
                ],
              ),
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
  late final TextEditingController _avatarCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.current.fullName);
    _phoneCtrl = TextEditingController(text: widget.current.phone);
    _avatarCtrl = TextEditingController(text: widget.current.avatarUrl);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _avatarCtrl.dispose();
    super.dispose();
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
      widget.current.copyWith(
        fullName: fullName,
        phone: _phoneCtrl.text.trim(),
        avatarUrl: _avatarCtrl.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          Center(child: _AvatarPreview(controller: _avatarCtrl)),
          const SizedBox(height: 24),
          Text(
            'Edit Profile',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Update your personal information',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
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
          _SheetField(
            controller: _avatarCtrl,
            label: 'Avatar URL',
            icon: Icons.image_outlined,
            inputType: TextInputType.url,
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.textPrimary,
                foregroundColor: AppColors.background,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              child: const Text('Save Changes'),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Avatar Preview Widget ───────────────────────────────────────────────────

class _AvatarPreview extends StatefulWidget {
  final TextEditingController controller;

  const _AvatarPreview({required this.controller});

  @override
  State<_AvatarPreview> createState() => _AvatarPreviewState();
}

class _AvatarPreviewState extends State<_AvatarPreview> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_rebuild);
  }

  void _rebuild() => setState(() {});

  @override
  void dispose() {
    widget.controller.removeListener(_rebuild);
    super.dispose();
  }

  void _showUrlDialog() {
    final tempCtrl = TextEditingController(text: widget.controller.text);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Avatar URL',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: AppColors.textPrimary,
          ),
        ),
        content: TextField(
          controller: tempCtrl,
          autofocus: true,
          style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'https://...',
            hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.divider),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.divider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.textPrimary,
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              widget.controller.text = tempCtrl.text;
              Navigator.pop(context);
            },
            child: Text(
              'Apply',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final url = widget.controller.text.trim();
    final hasUrl = url.isNotEmpty;

    return GestureDetector(
      onTap: _showUrlDialog,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surface,
              border: Border.all(color: AppColors.divider, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipOval(
              child: hasUrl
                  ? Image.network(
                      url,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.person_outline_rounded,
                        size: 36,
                        color: AppColors.textPrimary,
                      ),
                    )
                  : const Icon(
                      Icons.person_outline_rounded,
                      size: 36,
                      color: AppColors.textPrimary,
                    ),
            ),
          ),
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.background, width: 2.5),
            ),
            child: Icon(
              Icons.camera_alt_rounded,
              size: 13,
              color: Colors.white,
            ),
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
      style: TextStyle(fontSize: 13.5, color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
        prefixIcon: Icon(icon, size: 18, color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppColors.textPrimary,
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

class _ProfileHeroCard extends StatelessWidget {
  final _ProfileData profile;

  const _ProfileHeroCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    final hasAvatar = profile.avatarUrl.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.divider, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar on the left
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: AppColors.background,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.divider, width: 1.5),
            ),
            child: ClipOval(
              child: hasAvatar
                  ? Image.network(
                      profile.avatarUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.person_outline_rounded,
                        size: 30,
                        color: AppColors.textPrimary,
                      ),
                    )
                  : const Icon(
                      Icons.person_outline_rounded,
                      size: 30,
                      color: AppColors.textPrimary,
                    ),
            ),
          ),
          const SizedBox(width: 16),
          // Info on the right
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.fullName,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                _HeroInfoRow(
                  icon: Icons.mail_outline_rounded,
                  text: profile.email,
                ),
                const SizedBox(height: 3),
                _HeroInfoRow(
                  icon: Icons.phone_outlined,
                  text: profile.phone.isEmpty
                      ? 'No phone added'
                      : profile.phone,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroInfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _HeroInfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ─── Profile Details Card (essential info only) ────────────────────────────

class _ProfileDetailsCard extends StatelessWidget {
  final _ProfileData profile;

  const _ProfileDetailsCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    final createdAt = MaterialLocalizations.of(
      context,
    ).formatMediumDate(profile.createdAt);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Personal Information',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: -0.1,
            ),
          ),
          const SizedBox(height: 16),
          _DetailRow(
            icon: Icons.mail_outline_rounded,
            label: 'Email',
            value: profile.email,
          ),
          _DetailDivider(),
          _DetailRow(
            icon: Icons.phone_outlined,
            label: 'Phone',
            value: profile.phone.isEmpty ? 'Not added' : profile.phone,
          ),
          _DetailDivider(),
          _DetailRow(
            icon: Icons.calendar_month_outlined,
            label: 'Member since',
            value: createdAt,
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: AppColors.textSecondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: AppColors.divider.withOpacity(0.6),
    );
  }
}

// ─── Stats Row ───────────────────────────────────────────────────────────────

class _CustomerStatsRow extends StatelessWidget {
  final int likedCount;

  const _CustomerStatsRow({required this.likedCount});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const _StatChip(
          value: '0',
          label: 'Bookings',
          icon: Icons.event_note_rounded,
        ),
        const SizedBox(width: 10),
        _StatChip(
          value: '$likedCount',
          label: 'Favourites',
          icon: Icons.favorite_rounded,
        ),
        const SizedBox(width: 10),
        const _StatChip(
          value: '₹0',
          label: 'Spent',
          icon: Icons.account_balance_wallet_rounded,
        ),
      ],
    );
  }
}

class _OwnerStatsRow extends StatelessWidget {
  const _OwnerStatsRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        _StatChip(
          value: '0',
          label: 'Courts',
          icon: Icons.sports_soccer_rounded,
        ),
        SizedBox(width: 10),
        _StatChip(value: '0', label: "Today's", icon: Icons.today_rounded),
        SizedBox(width: 10),
        _StatChip(
          value: '₹0',
          label: 'Revenue',
          icon: Icons.trending_up_rounded,
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;

  const _StatChip({
    required this.value,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider, width: 1),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Info Cards ──────────────────────────────────────────────────────────────

class _CustomerInfoCard extends StatelessWidget {
  const _CustomerInfoCard();

  @override
  Widget build(BuildContext context) {
    return const _InfoCard(
      tag: 'Customer',
      description: 'You are browsing and booking courts as a customer.',
      trailingWidget: _RoleBadge(label: 'Active', isPositive: true),
    );
  }
}

class _OwnerInfoCard extends StatelessWidget {
  final bool isApproved;

  const _OwnerInfoCard({required this.isApproved});

  @override
  Widget build(BuildContext context) {
    return _InfoCard(
      tag: 'Owner',
      description: isApproved
          ? 'Your ownership is verified. Manage your courts and bookings.'
          : 'Your ownership request is pending approval.',
      trailingWidget: _RoleBadge(
        label: isApproved ? 'Verified' : 'Pending',
        isPositive: isApproved,
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String tag;
  final String description;
  final Widget trailingWidget;

  const _InfoCard({
    required this.tag,
    required this.description,
    required this.trailingWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tag,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          trailingWidget,
        ],
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final String label;
  final bool isPositive;

  const _RoleBadge({required this.label, required this.isPositive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isPositive
            ? const Color(0xFF1A7A4A).withOpacity(0.12)
            : const Color(0xFFC97A00).withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isPositive ? const Color(0xFF1A7A4A) : const Color(0xFFC97A00),
        ),
      ),
    );
  }
}

// ─── Section Label ───────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
        letterSpacing: 0.6,
      ),
    );
  }
}

// ─── Action Tile ─────────────────────────────────────────────────────────────

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? trailing;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.divider, width: 1),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: AppColors.textPrimary),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (trailing != null) ...[trailing!, const SizedBox(width: 8)],
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 13,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Badge ───────────────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  final int count;

  const _Badge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

// ─── Error Banner ────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Text(
        message,
        style: TextStyle(
          fontSize: 12.5,
          color: const Color(0xFFB91C1C),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ─── Logout Button ───────────────────────────────────────────────────────────

class _LogoutButton extends StatelessWidget {
  final VoidCallback onTap;

  const _LogoutButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFFECACA), width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.logout_rounded,
              size: 18,
              color: Color(0xFFDC2626),
            ),
            const SizedBox(width: 8),
            Text(
              'Log out',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFDC2626),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Edit Button ─────────────────────────────────────────────────────────────

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
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.divider, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.edit_rounded, size: 13, color: AppColors.textSecondary),
            const SizedBox(width: 5),
            Text(
              'Edit',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
