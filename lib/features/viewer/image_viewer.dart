import 'dart:io';

import 'package:flutter/material.dart';

/// Imagen con zoom/desplazamiento (InteractiveViewer) y rotación en pasos de 90°.
class ImageViewer extends StatefulWidget {
  const ImageViewer({super.key, required this.path});
  final String path;
  @override
  State<ImageViewer> createState() => _ImageViewerState();
}

class _ImageViewerState extends State<ImageViewer> {
  int _quarter = 0;
  final _ctrl = TransformationController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Expanded(
        child: ClipRect(
          child: InteractiveViewer(
            transformationController: _ctrl,
            minScale: 0.5,
            maxScale: 8,
            child: Center(
              child: RotatedBox(
                quarterTurns: _quarter,
                child: Image.file(
                  File(widget.path),
                  fit: BoxFit.contain,
                  // Falla de lectura/decodificación: mensaje en vez de crash.
                  errorBuilder: (_, e, _) => const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('No se pudo leer la imagen (archivo dañado o no disponible).'),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      SafeArea(
        top: false,
        child: Wrap(alignment: WrapAlignment.center, spacing: 8, children: [
          IconButton(tooltip: 'Girar a la izquierda', icon: const Icon(Icons.rotate_left),
              onPressed: () => setState(() => _quarter = (_quarter + 3) % 4)),
          IconButton(tooltip: 'Girar a la derecha', icon: const Icon(Icons.rotate_right),
              onPressed: () => setState(() => _quarter = (_quarter + 1) % 4)),
          IconButton(tooltip: 'Restablecer', icon: const Icon(Icons.restart_alt),
              onPressed: () => setState(() { _quarter = 0; _ctrl.value = Matrix4.identity(); })),
        ]),
      ),
    ]);
  }
}
