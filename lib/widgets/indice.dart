import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'estilo.dart';

/// Marca usada en el índice para "favoritos".
const marcaFavoritos = '★';

/// Índice vertical en el borde derecho: ★ y las letras que tienen apps.
/// Se puede tocar una letra o deslizar el dedo a lo largo del índice.
class IndiceLetras extends StatefulWidget {
  const IndiceLetras({
    super.key,
    required this.letras,
    required this.seleccion,
    required this.alElegir,
    required this.alAjustes,
  });

  /// Incluye la marca de favoritos en primer lugar.
  final List<String> letras;
  final String seleccion;
  final ValueChanged<String> alElegir;
  final VoidCallback alAjustes;

  @override
  State<IndiceLetras> createState() => _IndiceLetrasState();
}

class _IndiceLetrasState extends State<IndiceLetras> {
  int? _tocando; // índice bajo el dedo mientras se arrastra

  void _elegirEn(double y, double altoLetra) {
    final n = widget.letras.length;
    final i = (y / altoLetra).floor().clamp(0, n - 1);
    if (i != _tocando) {
      HapticFeedback.selectionClick();
      setState(() => _tocando = i);
      widget.alElegir(widget.letras[i]);
    }
  }

  void _soltar() => setState(() => _tocando = null);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final n = widget.letras.length;
      const altoAjustes = 30.0;
      final altoLetra = ((c.maxHeight - altoAjustes) / n).clamp(8.0, 30.0);
      final fuente = (altoLetra * 0.92).clamp(8.0, 24.0);
      return Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (d) => _elegirEn(d.localPosition.dy, altoLetra),
            onTapUp: (_) => _soltar(),
            onTapCancel: _soltar,
            onVerticalDragStart: (d) => _elegirEn(d.localPosition.dy, altoLetra),
            onVerticalDragUpdate: (d) => _elegirEn(d.localPosition.dy, altoLetra),
            onVerticalDragEnd: (_) => _soltar(),
            onVerticalDragCancel: _soltar,
            child: SizedBox(
              width: c.maxWidth,
              height: altoLetra * n,
              child: Column(
                children: [
                  for (var i = 0; i < n; i++)
                    SizedBox(
                      height: altoLetra,
                      child: _letra(i, fuente),
                    ),
                ],
              ),
            ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.alAjustes,
            child: SizedBox(
              width: c.maxWidth,
              height: altoAjustes,
              child: Center(
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.6),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _letra(int i, double fuente) {
    final letra = widget.letras[i];
    final elegida = letra == widget.seleccion;
    // Efecto "ola": la letra bajo el dedo crece y se desplaza a la izquierda.
    var escala = 1.0, desplazar = 0.0;
    if (_tocando != null) {
      final d = (i - _tocando!).abs();
      if (d == 0) {
        escala = 1.9;
        desplazar = -26;
      } else if (d == 1) {
        escala = 1.35;
        desplazar = -12;
      } else if (d == 2) {
        escala = 1.12;
        desplazar = -4;
      }
    }
    final esFav = letra == marcaFavoritos;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 90),
      transform: Matrix4.translationValues(desplazar, 0, 0),
      transformAlignment: Alignment.center,
      child: Center(
        child: AnimatedScale(
          duration: const Duration(milliseconds: 90),
          scale: escala,
          child: esFav
              ? Icon(Icons.star_outline_rounded,
                  color: Colors.white, size: fuente * 1.15, shadows: sombraTexto)
              : Text(
                  letra,
                  style: TextStyle(
                    color: elegida ? const Color(0xFFFFD54F) : Colors.white,
                    fontSize: fuente,
                    height: 1,
                    fontWeight: elegida ? FontWeight.w700 : FontWeight.w600,
                    shadows: sombraTexto,
                  ),
                ),
        ),
      ),
    );
  }
}
