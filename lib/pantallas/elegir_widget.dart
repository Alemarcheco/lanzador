import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../modelo.dart';
import '../plataforma.dart';
import '../texto.dart';

/// Lista de widgets disponibles, agrupados por app.
class PantallaElegirWidget extends StatefulWidget {
  const PantallaElegirWidget({super.key, required this.modelo});

  final Modelo modelo;

  @override
  State<PantallaElegirWidget> createState() => _PantallaElegirWidgetState();
}

class _PantallaElegirWidgetState extends State<PantallaElegirWidget> {
  Map<String, List<ProveedorWidget>>? _grupos;
  String _texto = '';
  bool _ocupado = false;
  final Map<String, Future<Uint8List?>> _vistas = {};

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final lista = await Plataforma.proveedoresWidget();
    final grupos = <String, List<ProveedorWidget>>{};
    for (final p in lista) {
      grupos.putIfAbsent(p.app, () => []).add(p);
    }
    final claves = grupos.keys.toList()..sort(compararNombres);
    if (!mounted) return;
    setState(() => _grupos = {for (final k in claves) k: grupos[k]!});
  }

  Future<void> _anadir(ProveedorWidget p) async {
    if (_ocupado) return;
    setState(() => _ocupado = true);
    final r = await Plataforma.anadirWidget(p.proveedor);
    if (!mounted) return;
    setState(() => _ocupado = false);
    if (r == null || r['id'] == null) {
      final motivo = r?['error'] as String? ?? 'No se pudo añadir el widget';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(motivo)));
      return;
    }
    final id = (r['id'] as num).toInt();
    final alto = (r['alto'] as num?)?.toDouble() ?? p.alto.toDouble();
    widget.modelo.agregarWidget(id, alto);
    Navigator.of(context).popUntil((ruta) => ruta.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final grupos = _grupos;
    final t = normalizar(_texto.trim());
    final visibles = grupos == null
        ? <MapEntry<String, List<ProveedorWidget>>>[]
        : grupos.entries
              .where(
                (e) =>
                    t.isEmpty ||
                    normalizar(e.key).contains(t) ||
                    e.value.any((p) => normalizar(p.nombre).contains(t)),
              )
              .toList();
    return Scaffold(
      backgroundColor: const Color(0xFF101420),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: TextField(
          style: const TextStyle(color: Colors.white),
          cursorColor: Colors.white,
          decoration: const InputDecoration(
            hintText: 'Buscar widget (clima, Spotify…)',
            hintStyle: TextStyle(color: Colors.white54),
            border: InputBorder.none,
          ),
          onChanged: (v) => setState(() => _texto = v),
        ),
      ),
      body: Stack(
        children: [
          if (grupos == null)
            const Center(child: CircularProgressIndicator())
          else if (visibles.isEmpty)
            const Center(
              child: Text(
                'No hay widgets',
                style: TextStyle(color: Colors.white60),
              ),
            )
          else
            ListView(
              padding: const EdgeInsets.only(bottom: 32),
              children: [
                for (final e in visibles)
                  ExpansionTile(
                    iconColor: Colors.white,
                    collapsedIconColor: Colors.white70,
                    title: Text(
                      e.key,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(
                      '${e.value.length} widget${e.value.length == 1 ? '' : 's'}',
                      style: const TextStyle(color: Colors.white54),
                    ),
                    children: [for (final p in e.value) _tarjeta(p)],
                  ),
              ],
            ),
          if (_ocupado)
            const ColoredBox(
              color: Color(0x66000000),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _tarjeta(ProveedorWidget p) {
    final celdasAncho = ((p.ancho + 30) / 70).ceil().clamp(1, 5);
    final celdasAlto = ((p.alto + 30) / 70).ceil().clamp(1, 5);
    return InkWell(
      onTap: () => _anadir(p),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 180),
              child: FutureBuilder<Uint8List?>(
                future: _vistas.putIfAbsent(
                  p.proveedor,
                  () => Plataforma.vistaPreviaWidget(p.proveedor),
                ),
                builder: (_, s) => s.data == null
                    ? const SizedBox(height: 60)
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.memory(s.data!, fit: BoxFit.contain),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              p.nombre,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '$celdasAncho × $celdasAlto · toca para añadir',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
