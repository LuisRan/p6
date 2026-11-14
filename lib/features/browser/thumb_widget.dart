import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/services/thumbnail_cache.dart';

/// Miniatura de imagen servida desde la caché de disco.
class ImageThumb extends StatefulWidget {
  const ImageThumb({super.key, required this.cache, required this.path, this.size = 48});
  final ThumbnailCache cache;
  final String path;
  final double size;
  @override
  State<ImageThumb> createState() => _ThumbState();
}

class _ThumbState extends State<ImageThumb> {
  late Future<File?> _f;
  @override
  void initState() {
    super.initState();
    _f = widget.cache.thumbnailFor(File(widget.path));
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: FutureBuilder<File?>(
          future: _f,
          builder: (_, s) => s.data != null
              ? Image.file(s.data!, fit: BoxFit.cover)
              : const ColoredBox(color: Colors.black12, child: Icon(Icons.image)),
        ),
      ),
    );
  }
}
