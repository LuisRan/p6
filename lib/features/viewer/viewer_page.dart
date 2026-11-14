import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../../main.dart';
import '../browser/file_actions.dart';
import 'image_viewer.dart';
import 'text_viewer.dart';

enum ViewerKind {
  text, markdown, json, xml, image, unsupported;

  static ViewerKind fromPath(String path) {
    switch (p.extension(path).toLowerCase().replaceFirst('.', '')) {
      case 'txt': case 'log': case 'csv': return text;
      case 'md': case 'markdown': return markdown;
      case 'json': return json;
      case 'xml': case 'plist': case 'svg': case 'html': return xml;
      case 'png': case 'jpg': case 'jpeg': case 'gif': case 'webp': case 'bmp': return image;
      default: return unsupported;
    }
  }
}

/// Contenedor del visor: AppBar con acciones comunes y cuerpo por tipo.
class ViewerPage extends StatelessWidget {
  const ViewerPage({super.key, required this.services, required this.path, required this.kind});
  final AppServices services;
  final String path;
  final ViewerKind kind;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(p.basename(path), overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(tooltip: 'Propiedades', icon: const Icon(Icons.info_outline),
              onPressed: () => showMetadata(context, services, path)),
          IconButton(tooltip: 'Compartir', icon: const Icon(Icons.share),
              onPressed: () => shareFile(context, path)),
        ],
      ),
      body: kind == ViewerKind.image
          ? ImageViewer(path: path)
          : TextViewer(services: services, path: path, kind: kind),
    );
  }
}
