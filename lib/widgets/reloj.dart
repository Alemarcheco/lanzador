import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../modelo.dart';
import '../plataforma.dart';
import '../temas.dart';
import '../texto.dart';

/// Reloj de la pantalla de inicio en el estilo elegido.
/// Tocar la hora abre las alarmas y tocar la fecha abre el calendario.
class Reloj extends StatefulWidget {
  const Reloj({
    super.key,
    required this.modelo,
    this.alMantener,
    this.horaFija,
  });

  final Modelo modelo;
  final VoidCallback? alMantener;

  /// Para vistas previas: muestra siempre esta hora.
  final DateTime? horaFija;

  @override
  State<Reloj> createState() => _RelojState();
}

class _RelojState extends State<Reloj> with WidgetsBindingObserver {
  DateTime _ahora = DateTime.now();
  Timer? _temporizador;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _programar();
  }

  void _programar() {
    _temporizador?.cancel();
    final ahora = DateTime.now();
    final siguiente = DateTime(
      ahora.year,
      ahora.month,
      ahora.day,
      ahora.hour,
      ahora.minute + 1,
    );
    _temporizador = Timer(siguiente.difference(ahora), () {
      if (!mounted) return;
      setState(() => _ahora = DateTime.now());
      _programar();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setState(() => _ahora = DateTime.now());
      _programar();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _temporizador?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.modelo;
    return EstiloReloj(
      estilo: m.estiloReloj,
      tema: m.tema,
      hora: widget.horaFija ?? _ahora,
      formato24: m.reloj24,
      escala: m.escalaReloj,
      acento: m.relojAcento,
      centrado: m.relojCentrado,
      fecha: m.mostrarFecha,
      alTocarHora: Plataforma.reloj,
      alTocarFecha: Plataforma.calendario,
      alMantener: widget.alMantener,
    );
  }
}

/// Dibuja un reloj con un estilo y tema concretos (se usa también en las vistas previas).
class EstiloReloj extends StatelessWidget {
  const EstiloReloj({
    super.key,
    required this.estilo,
    required this.tema,
    required this.hora,
    this.formato24 = true,
    this.escala = 1,
    this.acento = false,
    this.centrado = false,
    this.fecha = true,
    this.alTocarHora,
    this.alTocarFecha,
    this.alMantener,
  });

  final String estilo;
  final Tema tema;
  final DateTime hora;
  final bool formato24, acento, centrado, fecha;
  final double escala;
  final VoidCallback? alTocarHora, alTocarFecha, alMantener;

  @override
  Widget build(BuildContext context) {
    final color = acento ? tema.acento : tema.texto;
    final e = escala;
    final alin = centrado
        ? CrossAxisAlignment.center
        : CrossAxisAlignment.start;
    final alinTexto = centrado ? TextAlign.center : TextAlign.left;
    final h = horaTexto(hora, formato24: formato24);
    final textoFecha = fechaCorta(hora);

    Widget fechaW(double tam) => GestureDetector(
      onTap: alTocarFecha,
      child: Text(
        textoFecha,
        style: tema.estilo(tam * e, peso: FontWeight.w600),
      ),
    );

    Widget cuerpo;
    switch (estilo) {
      case 'apilado':
        final hh = formato24
            ? hora.hour.toString().padLeft(2, '0')
            : (hora.hour % 12 == 0 ? 12 : hora.hour % 12).toString().padLeft(
                2,
                '0',
              );
        final mm = hora.minute.toString().padLeft(2, '0');
        final st = TextStyle(
          fontFamily: 'BebasNeue',
          fontSize: 118 * e,
          height: 0.86,
          color: color,
          shadows: tema.sombras,
        );
        cuerpo = Column(
          crossAxisAlignment: alin,
          children: [
            GestureDetector(
              onTap: alTocarHora,
              child: Column(
                crossAxisAlignment: alin,
                children: [
                  Text(hh, style: st),
                  Text(
                    mm,
                    style: st.copyWith(
                      color: acento ? tema.texto : tema.acento,
                    ),
                  ),
                ],
              ),
            ),
            if (fecha) ...[const SizedBox(height: 10), fechaW(20)],
          ],
        );
      case 'fino':
        cuerpo = Column(
          crossAxisAlignment: alin,
          children: [
            GestureDetector(
              onTap: alTocarHora,
              child: Text(
                h,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w200,
                  fontSize: 100 * e,
                  height: 1,
                  letterSpacing: -2,
                  color: color,
                  shadows: tema.sombras,
                ),
              ),
            ),
            if (fecha) ...[const SizedBox(height: 4), fechaW(20)],
          ],
        );
      case 'neon':
        final brillo = acento ? tema.texto : tema.acento;
        cuerpo = Column(
          crossAxisAlignment: alin,
          children: [
            GestureDetector(
              onTap: alTocarHora,
              child: Text(
                h,
                style: TextStyle(
                  fontFamily: 'Orbitron',
                  fontWeight: FontWeight.w700,
                  fontSize: 64 * e,
                  height: 1.1,
                  color: Colors.white,
                  shadows: [
                    Shadow(blurRadius: 24, color: brillo),
                    Shadow(blurRadius: 10, color: brillo),
                    Shadow(blurRadius: 3, color: brillo),
                  ],
                ),
              ),
            ),
            if (fecha) ...[const SizedBox(height: 8), fechaW(18)],
          ],
        );
      case 'analogico':
        final lado = 170 * e;
        cuerpo = Column(
          crossAxisAlignment: alin,
          children: [
            GestureDetector(
              onTap: alTocarHora,
              child: SizedBox.square(
                dimension: lado,
                child: CustomPaint(painter: _Esfera(hora, color, tema.acento)),
              ),
            ),
            if (fecha) ...[const SizedBox(height: 10), fechaW(20)],
          ],
        );
      case 'palabras':
        cuerpo = Column(
          crossAxisAlignment: alin,
          children: [
            GestureDetector(
              onTap: alTocarHora,
              child: Text(
                horaEnPalabras(hora),
                textAlign: alinTexto,
                style: tema.estilo(
                  40 * e,
                  color: color,
                  peso: FontWeight.w700,
                  altura: 1.1,
                ),
              ),
            ),
            if (fecha) ...[const SizedBox(height: 10), fechaW(20)],
          ],
        );
      case 'minimo':
        cuerpo = GestureDetector(
          onTap: alTocarHora,
          child: Text(
            fecha ? '$h  ·  $textoFecha' : h,
            style: tema.estilo(28 * e, color: color, peso: FontWeight.w600),
          ),
        );
      default: // clásico
        cuerpo = Column(
          crossAxisAlignment: alin,
          children: [
            GestureDetector(
              onTap: alTocarHora,
              child: Text(
                h,
                style: tema.estilo(
                  76 * e,
                  color: color,
                  peso: FontWeight.w500,
                  altura: 1,
                ),
              ),
            ),
            if (fecha) ...[const SizedBox(height: 6), fechaW(22)],
          ],
        );
    }
    return GestureDetector(
      onLongPress: alMantener,
      onTap: alTocarHora,
      child: SizedBox(
        width: double.infinity,
        child: Column(crossAxisAlignment: alin, children: [cuerpo]),
      ),
    );
  }
}

class _Esfera extends CustomPainter {
  _Esfera(this.hora, this.color, this.acento);

  final DateTime hora;
  final Color color, acento;

  @override
  void paint(Canvas canvas, Size s) {
    final c = s.center(Offset.zero);
    final r = s.width / 2;
    final sombra = Paint()
      ..color = const Color(0x55000000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(
      c,
      r - 2,
      sombra
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );
    final borde = Paint()
      ..color = color.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(c, r - 2, borde);
    for (var i = 0; i < 12; i++) {
      final a = i * math.pi / 6;
      final largo = i % 3 == 0 ? 0.16 : 0.08;
      final p1 = c + Offset(math.sin(a), -math.cos(a)) * (r * 0.9);
      final p2 = c + Offset(math.sin(a), -math.cos(a)) * (r * (0.9 - largo));
      canvas.drawLine(
        p1,
        p2,
        Paint()
          ..color = color
          ..strokeWidth = i % 3 == 0 ? 3 : 1.5
          ..strokeCap = StrokeCap.round,
      );
    }
    void aguja(double ang, double largo, double grosor, Color col) {
      final fin = c + Offset(math.sin(ang), -math.cos(ang)) * (r * largo);
      canvas.drawLine(
        c,
        fin,
        Paint()
          ..color = const Color(0x66000000)
          ..strokeWidth = grosor + 2
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
      canvas.drawLine(
        c,
        fin,
        Paint()
          ..color = col
          ..strokeWidth = grosor
          ..strokeCap = StrokeCap.round,
      );
    }

    final min = hora.minute;
    final hr = (hora.hour % 12) + min / 60;
    aguja(hr * math.pi / 6, 0.5, 6, color);
    aguja(min * math.pi / 30, 0.75, 4, acento);
    canvas.drawCircle(c, 6, Paint()..color = acento);
  }

  @override
  bool shouldRepaint(_Esfera o) =>
      o.hora != hora || o.color != color || o.acento != acento;
}
