import 'dart:async';

import 'package:flutter/material.dart';

import '../plataforma.dart';
import '../texto.dart';
import 'estilo.dart';

/// Hora grande y fecha corta debajo. Tocar la hora abre las alarmas
/// y tocar la fecha abre el calendario.
class Reloj extends StatefulWidget {
  const Reloj({super.key, required this.formato24});

  final bool formato24;

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
    final siguiente = DateTime(ahora.year, ahora.month, ahora.day, ahora.hour, ahora.minute + 1);
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: Plataforma.reloj,
          child: Text(
            horaTexto(_ahora, formato24: widget.formato24),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 76,
              height: 1.0,
              fontWeight: FontWeight.w500,
              letterSpacing: -1,
              shadows: sombraTexto,
            ),
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: Plataforma.calendario,
          child: Text(
            fechaCorta(_ahora),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w600,
              shadows: sombraTexto,
            ),
          ),
        ),
      ],
    );
  }
}
