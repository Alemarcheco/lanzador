import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Recorta el icono con la forma elegida.
class RecorteIcono extends CustomClipper<Path> {
  const RecorteIcono(this.forma);

  final String forma;

  @override
  Path getClip(Size s) => caminoForma(forma, s);

  @override
  bool shouldReclip(RecorteIcono old) => old.forma != forma;
}

Path caminoForma(String forma, Size s) {
  final r = Offset.zero & s;
  final w = s.width;
  Radius rad(double f) => Radius.circular(w * f);
  switch (forma) {
    case 'circulo':
      return Path()..addOval(r);
    case 'cuadrado':
      return Path()..addRRect(RRect.fromRectAndRadius(r, rad(0.08)));
    case 'lagrima':
      return Path()
        ..addRRect(RRect.fromRectAndCorners(r,
            topLeft: rad(0.5), bottomLeft: rad(0.5), bottomRight: rad(0.5), topRight: rad(0.12)));
    case 'hoja':
      return Path()
        ..addRRect(RRect.fromRectAndCorners(r,
            topLeft: rad(0.5), bottomRight: rad(0.5), topRight: rad(0.1), bottomLeft: rad(0.1)));
    case 'squircle':
      // Superelipse |x|^4 + |y|^4 = 1
      final p = Path();
      final cx = w / 2, cy = s.height / 2;
      for (var i = 0; i <= 96; i++) {
        final t = i / 96 * 2 * math.pi;
        final c = math.cos(t), sn = math.sin(t);
        final x = cx + cx * c.sign * math.pow(c.abs(), 0.5);
        final y = cy + cy * sn.sign * math.pow(sn.abs(), 0.5);
        if (i == 0) {
          p.moveTo(x, y);
        } else {
          p.lineTo(x, y);
        }
      }
      return p..close();
    default: // redondeado
      return Path()..addRRect(RRect.fromRectAndRadius(r, rad(0.26)));
  }
}

const _matrizByN = <double>[
  0.2126, 0.7152, 0.0722, 0, 0,
  0.2126, 0.7152, 0.0722, 0, 0,
  0.2126, 0.7152, 0.0722, 0, 0,
  0, 0, 0, 1, 0,
];

const filtroByN = ColorFilter.matrix(_matrizByN);
