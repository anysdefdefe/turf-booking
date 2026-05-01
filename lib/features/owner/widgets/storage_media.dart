import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:turf_booking/app/theme/app_colors.dart';

class StorageImage extends StatefulWidget {
  final String? storagePath;
  final String bucketName;
  final double width;
  final double height;
  final BoxFit fit;
  final BorderRadius borderRadius;
  final Widget placeholder;

  const StorageImage({
    super.key,
    required this.storagePath,
    required this.bucketName,
    required this.width,
    required this.height,
    this.fit = BoxFit.cover,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    required this.placeholder,
  });

  @override
  State<StorageImage> createState() => _StorageImageState();
}

class _StorageImageState extends State<StorageImage> {
  late Future<String?> _resolvedUrl;

  @override
  void initState() {
    super.initState();
    _resolvedUrl = _resolve();
  }

  @override
  void didUpdateWidget(covariant StorageImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.storagePath != widget.storagePath ||
        oldWidget.bucketName != widget.bucketName) {
      _resolvedUrl = _resolve();
    }
  }

  Future<String?> _resolve() async {
    final storagePath = widget.storagePath;
    if (storagePath == null || storagePath.isEmpty) return null;
    if (storagePath.startsWith('http://') ||
        storagePath.startsWith('https://')) {
      return storagePath;
    }

    try {
      return await Supabase.instance.client.storage
          .from(widget.bucketName)
          .createSignedUrl(storagePath, 60 * 60);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _resolvedUrl,
      builder: (context, snapshot) {
        final url = snapshot.data;
        final child = url == null
            ? widget.placeholder
            : Image.network(
                url,
                width: widget.width,
                height: widget.height,
                fit: widget.fit,
                errorBuilder: (_, __, ___) => widget.placeholder,
              );

        return ClipRRect(
          borderRadius: widget.borderRadius,
          child: SizedBox(
            width: widget.width,
            height: widget.height,
            child: child,
          ),
        );
      },
    );
  }
}

class StorageAvatar extends StatefulWidget {
  final String? storagePath;
  final String bucketName;
  final String displayName;
  final double radius;
  final Color backgroundColor;

  const StorageAvatar({
    super.key,
    required this.storagePath,
    required this.bucketName,
    required this.displayName,
    required this.radius,
    this.backgroundColor = const Color(0xFFF3F4F6),
  });

  @override
  State<StorageAvatar> createState() => _StorageAvatarState();
}

class _StorageAvatarState extends State<StorageAvatar> {
  late Future<String?> _resolvedUrl;

  @override
  void initState() {
    super.initState();
    _resolvedUrl = _resolve();
  }

  @override
  void didUpdateWidget(covariant StorageAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.storagePath != widget.storagePath ||
        oldWidget.bucketName != widget.bucketName) {
      _resolvedUrl = _resolve();
    }
  }

  Future<String?> _resolve() async {
    final storagePath = widget.storagePath;
    if (storagePath == null || storagePath.isEmpty) return null;
    if (storagePath.startsWith('http://') ||
        storagePath.startsWith('https://')) {
      return storagePath;
    }

    try {
      return await Supabase.instance.client.storage
          .from(widget.bucketName)
          .createSignedUrl(storagePath, 60 * 60);
    } catch (_) {
      return null;
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  /// Extracts up to 2 initials from a display name.
  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  /// Always returns the app's primary green to match the brand.
  Color _avatarColor(String _) => AppColors.primary;

  @override
  Widget build(BuildContext context) {
    final initials = _initials(widget.displayName);
    final color = _avatarColor(widget.displayName);

    // Initials placeholder — shown while loading, on error, or when no URL.
    Widget initialsAvatar() {
      if (initials.isEmpty) {
        // Absolute fallback: person icon
        return CircleAvatar(
          radius: widget.radius,
          backgroundColor: const Color(0xFFF4F4F5),
          child: Icon(
            Icons.person_rounded,
            size: widget.radius * 0.95,
            color: const Color(0xFF71717A),
          ),
        );
      }
      return CircleAvatar(
        radius: widget.radius,
        backgroundColor: color,
        child: Text(
          initials,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: widget.radius * 0.75,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
      );
    }

    return FutureBuilder<String?>(
      future: _resolvedUrl,
      builder: (context, snapshot) {
        // While resolving — show initials immediately (no flash)
        if (snapshot.connectionState == ConnectionState.waiting) {
          return initialsAvatar();
        }

        final url = snapshot.data;
        if (url == null || url.isEmpty) {
          return initialsAvatar();
        }

        return CircleAvatar(
          radius: widget.radius,
          backgroundColor: widget.backgroundColor,
          backgroundImage: NetworkImage(url),
          // If the network image fails to load, show initials
          onBackgroundImageError: (_, __) {},
          child: ClipOval(
            child: Image.network(
              url,
              width: widget.radius * 2,
              height: widget.radius * 2,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => initialsAvatar(),
            ),
          ),
        );
      },
    );
  }
}
