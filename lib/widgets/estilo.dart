import 'package:flutter/material.dart';

/// Sombra suave para que el texto blanco se lea sobre cualquier fondo.
const sombraTexto = [
  Shadow(blurRadius: 8, color: Color(0x99000000)),
  Shadow(blurRadius: 2, color: Color(0x66000000), offset: Offset(0, 1)),
];
