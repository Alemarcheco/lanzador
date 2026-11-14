import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../modelo.dart';
import '../plataforma.dart';
import 'estilo.dart';

class IconoApp extends StatelessWidget {
  const IconoApp({super.key, required this.app, required this.modelo, this.tam = 48});

  final AppInfo app;
  final Modelo modelo;
  final double tam;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: tam,
      child: FutureBuilder<Uint8List?>(
        future: modelo.icono(app),
        builder: (context, snap) {
          final datos = snap.data;
          if (datos == null) return const SizedBox();
          return ClipRRect(
            borderRadius: BorderRadius.circular(tam * 0.26),
            child: Image.memory(
              datos,
              width: tam,
              height: tam,
              gaplessPlayback: true,
              filterQuality: FilterQuality.medium,
            ),
          );
        },
      ),
    );
  }
}

/// Fila de la lista: icono + nombre, como en la pantalla de inicio.
class FilaApp extends StatelessWidget {
  const FilaApp({
    super.key,
    required this.app,
    required this.modelo,
    required this.alAbrir,
  });

  final AppInfo app;
  final Modelo modelo;
  final VoidCallback alAbrir;

  @override
  Widget build(BuildContext context) {
    final tam = modelo.tamTexto;
    final icono = (tam * 2.4).clamp(36.0, 64.0);
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: alAbrir,
      onLongPress: () => mostrarMenuApp(context, app, modelo),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: tam * 0.45, horizontal: 4),
        child: Row(
          children: [
            if (modelo.mostrarIconos) ...[
              IconoApp(app: app, modelo: modelo, tam: icono),
              SizedBox(width: tam * 1.2),
            ],
            Flexible(
              child: Text(
                app.nombre,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: tam,
                  fontWeight: FontWeight.w600,
                  shadows: sombraTexto,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Menú al mantener pulsada una app.
Future<void> mostrarMenuApp(BuildContext context, AppInfo app, Modelo modelo) {
  final fav = modelo.esFavorita(app);
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: const Color(0xF0181C26),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          ListTile(
            leading: IconoApp(app: app, modelo: modelo, tam: 40),
            title: Text(app.nombre,
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
            subtitle: Text(app.paquete, style: const TextStyle(color: Colors.white54, fontSize: 12)),
          ),
          const Divider(color: Colors.white12),
          _opcion(ctx, fav ? Icons.star : Icons.star_border,
              fav ? 'Quitar de favoritos' : 'Añadir a favoritos', () => modelo.alternarFavorita(app)),
          _opcion(ctx, Icons.info_outline, 'Información de la app', () => Plataforma.infoApp(app)),
          _opcion(ctx, Icons.delete_outline, 'Desinstalar', () => Plataforma.desinstalar(app)),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

Widget _opcion(BuildContext ctx, IconData icono, String texto, VoidCallback accion) => ListTile(
      leading: Icon(icono, color: Colors.white),
      title: Text(texto, style: const TextStyle(color: Colors.white, fontSize: 16)),
      onTap: () {
        Navigator.pop(ctx);
        accion();
      },
    );
