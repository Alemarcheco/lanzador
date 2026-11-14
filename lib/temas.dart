import 'package:flutter/material.dart';

/// Tema visual del launcher: colores, letra y brillo del texto.
class Tema {
  const Tema({
    required this.id,
    required this.nombre,
    required this.fuente,
    required this.texto,
    required this.acento,
    this.brillo = false,
    this.peso = FontWeight.w600,
  });

  final String id;
  final String nombre;
  final String fuente;
  final Color texto;
  final Color acento;
  final bool brillo; // texto con resplandor de color
  final FontWeight peso;

  List<Shadow> get sombras => brillo
      ? [
          Shadow(blurRadius: 14, color: acento.withValues(alpha: 0.9)),
          Shadow(blurRadius: 4, color: acento.withValues(alpha: 0.7)),
          const Shadow(blurRadius: 2, color: Color(0x88000000), offset: Offset(0, 1)),
        ]
      : const [
          Shadow(blurRadius: 8, color: Color(0x99000000)),
          Shadow(blurRadius: 2, color: Color(0x66000000), offset: Offset(0, 1)),
        ];

  TextStyle estilo(double tam, {Color? color, FontWeight? peso, double? altura}) => TextStyle(
        fontFamily: fuente,
        fontSize: tam,
        color: color ?? texto,
        fontWeight: peso ?? this.peso,
        height: altura,
        shadows: sombras,
      );
}

const temas = <Tema>[
  Tema(id: 'galaxia', nombre: 'Galaxia', fuente: 'Nunito',
      texto: Colors.white, acento: Color(0xFFFFD54F)),
  Tema(id: 'neon', nombre: 'Neón', fuente: 'Orbitron',
      texto: Color(0xFFE6FDFF), acento: Color(0xFF00E5FF), brillo: true, peso: FontWeight.w500),
  Tema(id: 'elegante', nombre: 'Elegante', fuente: 'PlayfairDisplay',
      texto: Color(0xFFFFF8E7), acento: Color(0xFFD4AF37), peso: FontWeight.w500),
  Tema(id: 'retro', nombre: 'Retro', fuente: 'SpaceMono',
      texto: Color(0xFFC8FFC8), acento: Color(0xFF39FF14), brillo: true, peso: FontWeight.w400),
  Tema(id: 'pastel', nombre: 'Pastel', fuente: 'Comfortaa',
      texto: Color(0xFFFFF0F6), acento: Color(0xFFFF9EC9), peso: FontWeight.w700),
  Tema(id: 'moderno', nombre: 'Moderno', fuente: 'Outfit',
      texto: Colors.white, acento: Color(0xFF82B1FF)),
  Tema(id: 'atardecer', nombre: 'Atardecer', fuente: 'Nunito',
      texto: Color(0xFFFFE3C7), acento: Color(0xFFFF8A50), brillo: true),
  Tema(id: 'rosa', nombre: 'Rosa neón', fuente: 'Comfortaa',
      texto: Color(0xFFFFE6F4), acento: Color(0xFFFF2DAA), brillo: true, peso: FontWeight.w700),
  Tema(id: 'noche', nombre: 'Noche pura', fuente: 'Outfit',
      texto: Color(0xFFDADADA), acento: Color(0xFFA0A0A0), peso: FontWeight.w300),
];

Tema temaPorId(String id) => temas.firstWhere((t) => t.id == id, orElse: () => temas.first);

/// Estilos de reloj (inspirados en los de pantalla de bloqueo).
const estilosReloj = <String, String>{
  'clasico': 'Clásico',
  'apilado': 'Apilado',
  'fino': 'Fino',
  'neon': 'Digital neón',
  'analogico': 'Analógico',
  'palabras': 'En palabras',
  'minimo': 'Mínimo',
};

/// Formas de los iconos.
const formasIcono = <String, String>{
  'redondeado': 'Redondeado',
  'circulo': 'Círculo',
  'squircle': 'Squircle',
  'cuadrado': 'Cuadrado',
  'lagrima': 'Lágrima',
  'hoja': 'Hoja',
};
