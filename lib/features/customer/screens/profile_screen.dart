import 'package:flutter/material.dart';

import '../../../app/constants/app_constants.dart';
import '../../../app/theme/app_colors.dart';
import '../data/repositories/customer_preferences_repository.dart';
import '../widgets/customer_floating_nav_bar.dart';

// ─────────────────────────────────────────────
//  Profile data model (simple value holder)
// ─────────────────────────────────────────────
class _ProfileData {
  String name;
  String location;
  String phone;
  String avatarUrl;

  _ProfileData({
    this.name = 'Name',
    this.location = 'Mumbai, India',
    this.phone = '+91 90000 00000',
    this.avatarUrl = '',
  });

  _ProfileData copyWith({
    String? name,
    String? location,
    String? phone,
    String? avatarUrl,
  }) => _ProfileData(
    name: name ?? this.name,
    location: location ?? this.location,
    phone: phone ?? this.phone,
    avatarUrl: avatarUrl ?? this.avatarUrl,
  );
}

// ─────────────────────────────────────────────
//  ProfileScreen
// ─────────────────────────────────────────────
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const bool _isOwner = false;
  static const bool _isApproved = false;

  _ProfileData _profile = _ProfileData();

  void _onNavTap(int index) {
    if (index == 2) return;
    if (index == 0) {
      Navigator.pushReplacementNamed(context, AppConstants.routeHome);
      return;
    }
    if (index == 1) {
      Navigator.pushReplacementNamed(context, AppConstants.routeMyBookings);
    }
  }

  Future<void> _openEditSheet() async {
    final updated = await showModalBottomSheet<_ProfileData>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditProfileSheet(current: _profile),
    );
    if (updated != null) {
      setState(() => _profile = updated);
    }
  }

  @override
  Widget build(BuildContext context) {
    final likes = CustomerPreferencesRepository.instance.likedCourtIds;

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
        title: const Text(
          'Profile',
          style: TextStyle(
            fontFamily: 'Poppins',
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
      body: ValueListenableBuilder<Set<String>>(
        valueListenable: likes,
        builder: (context, likedIds, _) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
            children: [
              _ProfileHeroCard(profile: _profile),
              const SizedBox(height: 20),
              _isOwner
                  ? const _OwnerStatsRow()
                  : _CustomerStatsRow(likedCount: likedIds.length),
              const SizedBox(height: 20),
              _isOwner
                  ? const _OwnerInfoCard(isApproved: _isApproved)
                  : const _CustomerInfoCard(),
              const SizedBox(height: 20),
              const _SectionLabel(label: 'Account'),
              const SizedBox(height: 10),
              _ActionTile(
                icon: Icons.receipt_long_rounded,
                label: 'My Bookings',
                onTap: () => Navigator.pushReplacementNamed(
                  context,
                  AppConstants.routeMyBookings,
                ),
              ),
              _ActionTile(
                icon: Icons.favorite_border_rounded,
                label: 'Wishlist',
                trailing: likedIds.isNotEmpty
                    ? _Badge(count: likedIds.length)
                    : null,
                onTap: () => Navigator.pushReplacementNamed(
                  context,
                  AppConstants.routeHome,
                  arguments: {'feed': 'wishlist'},
                ),
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
              const SizedBox(height: 20),
              _LogoutButton(onTap: () {}),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Edit Profile Bottom Sheet
// ─────────────────────────────────────────────
class _EditProfileSheet extends StatefulWidget {
  final _ProfileData current;

  const _EditProfileSheet({required this.current});

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _locationCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _avatarCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.current.name);
    _locationCtrl = TextEditingController(text: widget.current.location);
    _phoneCtrl = TextEditingController(text: widget.current.phone);
    _avatarCtrl = TextEditingController(text: widget.current.avatarUrl);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _locationCtrl.dispose();
    _phoneCtrl.dispose();
    _avatarCtrl.dispose();
    super.dispose();
  }

  void _save() {
    Navigator.pop(
      context,
      widget.current.copyWith(
        name: _nameCtrl.text.trim(),
        location: _locationCtrl.text.trim(),
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Drag handle ──
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 14, bottom: 20),
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),

          // ── Avatar preview ──
          Center(child: _AvatarPreview(controller: _avatarCtrl)),
          const SizedBox(height: 24),

          const Text(
            'Edit Profile',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 16),

          _SheetField(
            controller: _nameCtrl,
            label: 'Name',
            icon: Icons.person_outline_rounded,
            inputType: TextInputType.name,
          ),
          const SizedBox(height: 12),
          _SheetField(
            controller: _locationCtrl,
            label: 'Location',
            icon: Icons.location_on_outlined,
            inputType: TextInputType.streetAddress,
          ),
          const SizedBox(height: 12),
          _SheetField(
            controller: _phoneCtrl,
            label: 'Phone',
            icon: Icons.phone_outlined,
            inputType: TextInputType.phone,
          ),
          const SizedBox(height: 24),

          // ── Save button ──
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.textPrimary,
                foregroundColor: AppColors.background,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
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

// ─────────────────────────────────────────────
//  Avatar preview with tap-to-edit URL dialog
// ─────────────────────────────────────────────
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Avatar URL',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: AppColors.textPrimary,
          ),
        ),
        content: TextField(
          controller: tempCtrl,
          autofocus: true,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: 'https://...',
            hintStyle: const TextStyle(
              fontFamily: 'Poppins',
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
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
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontFamily: 'Poppins',
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              widget.controller.text = tempCtrl.text;
              Navigator.pop(context);
            },
            child: const Text(
              'Apply',
              style: TextStyle(
                fontFamily: 'Poppins',
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
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surface,
              border: Border.all(color: AppColors.divider, width: 1.5),
            ),
            child: ClipOval(
              child: hasUrl
                  ? Image.network(
                      url,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
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
          // Edit badge
          Container(
            width: 27,
            height: 27,
            decoration: BoxDecoration(
              color: AppColors.textPrimary,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.background, width: 2),
            ),
            child: Icon(
              Icons.edit_rounded,
              size: 13,
              color: AppColors.background,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Reusable text field for bottom sheet
// ─────────────────────────────────────────────
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
      style: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 13.5,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12.5,
          color: AppColors.textSecondary,
        ),
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

// ─────────────────────────────────────────────
//  Edit button (top-right)
// ─────────────────────────────────────────────
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
        child: const Text(
          'Edit',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Profile hero card — reflects live _ProfileData
// ─────────────────────────────────────────────
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
          Container(
            width: 64,
            height: 64,
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
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.person_outline_rounded,
                        size: 28,
                        color: AppColors.textPrimary,
                      ),
                    )
                  : const Icon(
                      Icons.person_outline_rounded,
                      size: 28,
                      color: AppColors.textPrimary,
                    ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.name,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 3),
                const _MetaRow(
                  icon: Icons.mail_outline_rounded,
                  text: 'email@example.com',
                ),
                const SizedBox(height: 2),
                _MetaRow(
                  icon: Icons.location_on_outlined,
                  text: profile.location,
                ),
                const SizedBox(height: 2),
                _MetaRow(icon: Icons.phone_outlined, text: profile.phone),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Small icon + text row used inside hero card
// ─────────────────────────────────────────────
class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MetaRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 12, color: AppColors.textSecondary),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  Stats row — Customer
// ─────────────────────────────────────────────
class _CustomerStatsRow extends StatelessWidget {
  final int likedCount;

  const _CustomerStatsRow({required this.likedCount});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const _StatChip(value: '0', label: 'Bookings'),
        const SizedBox(width: 10),
        _StatChip(value: '$likedCount', label: 'Favourites'),
        const SizedBox(width: 10),
        const _StatChip(value: '₹0', label: 'Spent'),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  Stats row — Owner
// ─────────────────────────────────────────────
class _OwnerStatsRow extends StatelessWidget {
  const _OwnerStatsRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        _StatChip(value: '0', label: 'Courts'),
        SizedBox(width: 10),
        _StatChip(value: '0', label: "Today's"),
        SizedBox(width: 10),
        _StatChip(value: '₹0', label: 'Revenue'),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  Single stat chip
// ─────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final String value;
  final String label;

  const _StatChip({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider, width: 1),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Customer info card
// ─────────────────────────────────────────────
class _CustomerInfoCard extends StatelessWidget {
  const _CustomerInfoCard();

  @override
  Widget build(BuildContext context) {
    return const _InfoCard(
      tag: 'Customer',
      description: 'You\'re browsing and booking courts as a customer.',
      trailingWidget: _RoleBadge(label: 'Active', isPositive: true),
    );
  }
}

// ─────────────────────────────────────────────
//  Owner info card
// ─────────────────────────────────────────────
class _OwnerInfoCard extends StatelessWidget {
  final bool isApproved;

  const _OwnerInfoCard({required this.isApproved});

  @override
  Widget build(BuildContext context) {
    return _InfoCard(
      tag: 'Court Owner',
      description: isApproved
          ? 'Your ownership is verified. Manage your courts and bookings.'
          : 'Your ownership request is pending approval. We\'ll notify you once verified.',
      trailingWidget: _RoleBadge(
        label: isApproved ? 'Verified' : 'Pending',
        isPositive: isApproved,
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Generic info card (reusable)
// ─────────────────────────────────────────────
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
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  description,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
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

// ─────────────────────────────────────────────
//  Role badge pill
// ─────────────────────────────────────────────
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
          fontFamily: 'Poppins',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isPositive ? const Color(0xFF1A7A4A) : const Color(0xFFC97A00),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Section label
// ─────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
        letterSpacing: 0.6,
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Action tile (reusable list item)
// ─────────────────────────────────────────────
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
                  style: const TextStyle(
                    fontFamily: 'Poppins',
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

// ─────────────────────────────────────────────
//  Badge count pill
// ─────────────────────────────────────────────
class _Badge extends StatelessWidget {
  final int count;

  const _Badge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.textPrimary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Logout button
// ─────────────────────────────────────────────
class _LogoutButton extends StatelessWidget {
  final VoidCallback onTap;

  const _LogoutButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: const Color(0xFFFF3B30).withOpacity(0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFFFF3B30).withOpacity(0.18),
            width: 1,
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded, size: 17, color: Color(0xFFFF3B30)),
            SizedBox(width: 8),
            Text(
              'Log Out',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFFFF3B30),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
