import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  @override
  Widget build(BuildContext context) {
    Widget neutralPlaceholder() {
      return CircleAvatar(
        radius: widget.radius,
        backgroundColor: const Color(0xFFF4F4F5),
        child: Icon(
          Icons.person_outline_rounded,
          size: widget.radius * 0.95,
          color: const Color(0xFF71717A),
        ),
      );
    }

    return FutureBuilder<String?>(
      future: _resolvedUrl,
      builder: (context, snapshot) {
        final url = snapshot.data;
        if (snapshot.connectionState == ConnectionState.waiting) {
          return neutralPlaceholder();
        }

        if (url == null || url.isEmpty) {
          return neutralPlaceholder();
        }

        return CircleAvatar(
          radius: widget.radius,
          backgroundColor: widget.backgroundColor,
          backgroundImage: NetworkImage(url),
        );
      },
    );
  }
}
