import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../modelo.dart';

/// Muestra un widget de Android (clima, Spotify…) dentro del launcher.
class VistaWidget extends StatelessWidget {
  const VistaWidget({
    super.key,
    required this.widgetColocado,
    required this.modelo,
  });

  final WidgetColocado widgetColocado;
  final Modelo modelo;

  @override
  Widget build(BuildContext context) {
    final w = widgetColocado;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, right: 4),
      child: LayoutBuilder(
        builder: (context, c) {
          return GestureDetector(
            onLongPress: () => _menu(context),
            child: SizedBox(
              height: w.alto,
              width: c.maxWidth,
              child: AndroidView(
                // La clave incluye el tamaño para que el widget se rehaga al cambiarlo.
                key: ValueKey(
                  '${w.id}-${w.alto.round()}-${c.maxWidth.round()}-${modelo.generacionWidgets}',
                ),
                viewType: 'com.feito.lanzador/widget',
                creationParams: {
                  'id': w.id,
                  'ancho': c.maxWidth.round(),
                  'alto': w.alto.round(),
                },
                creationParamsCodec: const StandardMessageCodec(),
              ),
            ),
          );
        },
      ),
    );
  }

  void _menu(BuildContext context) {
    final m = modelo;
    final w = widgetColocado;
    final i = m.widgets.indexOf(w);
    HapticFeedback.mediumImpact();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xF0181C26),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, refrescar) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Widget',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _boton(Icons.remove, 'Más bajo', () {
                      m.cambiarAltoWidget(w, -20);
                      refrescar(() {});
                    }),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        '${w.alto.round()}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    _boton(Icons.add, 'Más alto', () {
                      m.cambiarAltoWidget(w, 20);
                      refrescar(() {});
                    }),
                  ],
                ),
                const SizedBox(height: 8),
                if (i > 0)
                  _opcion(
                    ctx,
                    Icons.arrow_upward,
                    'Subir',
                    () => m.moverWidget(w, -1),
                  ),
                if (i < m.widgets.length - 1)
                  _opcion(
                    ctx,
                    Icons.arrow_downward,
                    'Bajar',
                    () => m.moverWidget(w, 1),
                  ),
                _opcion(
                  ctx,
                  Icons.delete_outline,
                  'Quitar widget',
                  () => m.quitarWidget(w),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _boton(IconData icono, String texto, VoidCallback accion) => Column(
    children: [
      IconButton.filledTonal(onPressed: accion, icon: Icon(icono)),
      Text(texto, style: const TextStyle(color: Colors.white60, fontSize: 12)),
    ],
  );

  Widget _opcion(
    BuildContext ctx,
    IconData icono,
    String texto,
    VoidCallback accion,
  ) => ListTile(
    leading: Icon(icono, color: Colors.white),
    title: Text(
      texto,
      style: const TextStyle(color: Colors.white, fontSize: 16),
    ),
    onTap: () {
      Navigator.pop(ctx);
      accion();
    },
  );
}
