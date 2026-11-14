/// Utilidades de texto: letra del índice, orden alfabético y fecha en español.
library;

const _sinAcento = {
  'Á': 'A', 'À': 'A', 'Â': 'A', 'Ä': 'A', 'Ã': 'A', 'Å': 'A',
  'É': 'E', 'È': 'E', 'Ê': 'E', 'Ë': 'E',
  'Í': 'I', 'Ì': 'I', 'Î': 'I', 'Ï': 'I',
  'Ó': 'O', 'Ò': 'O', 'Ô': 'O', 'Ö': 'O', 'Õ': 'O',
  'Ú': 'U', 'Ù': 'U', 'Û': 'U', 'Ü': 'U',
  'Ñ': 'N', 'Ç': 'C',
};

/// Quita acentos y pasa a mayúsculas (para ordenar y buscar).
String normalizar(String s) {
  final b = StringBuffer();
  for (final r in s.toUpperCase().runes) {
    final c = String.fromCharCode(r);
    b.write(_sinAcento[c] ?? c);
  }
  return b.toString();
}

/// Letra del índice A–Z en la que aparece una app. Lo que no empieza
/// por letra va a '#'.
String letraDe(String nombre) {
  final t = normalizar(nombre.trim());
  if (t.isEmpty) return '#';
  final c = t[0];
  return RegExp(r'^[A-Z]$').hasMatch(c) ? c : '#';
}

/// Compara dos nombres de app sin tener en cuenta acentos ni mayúsculas;
/// los que empiezan por número o símbolo van al final.
int compararNombres(String a, String b) {
  final la = letraDe(a), lb = letraDe(b);
  if (la == '#' && lb != '#') return 1;
  if (lb == '#' && la != '#') return -1;
  return normalizar(a).compareTo(normalizar(b));
}

const _dias = ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'];
const _meses = [
  'ene', 'feb', 'mar', 'abr', 'may', 'jun',
  'jul', 'ago', 'sept', 'oct', 'nov', 'dic',
];

/// "mar, 10 de nov"
String fechaCorta(DateTime d) =>
    '${_dias[d.weekday - 1]}, ${d.day} de ${_meses[d.month - 1]}';

/// "8:17" (24 h) o "8:17" / "11:05" (12 h, sin a. m./p. m.)
String horaTexto(DateTime d, {bool formato24 = true}) {
  final m = d.minute.toString().padLeft(2, '0');
  if (formato24) return '${d.hour}:$m';
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  return '$h:$m';
}

const _unidades = [
  'cero', 'uno', 'dos', 'tres', 'cuatro', 'cinco', 'seis', 'siete', 'ocho', 'nueve',
  'diez', 'once', 'doce', 'trece', 'catorce', 'quince', 'dieciséis', 'diecisiete',
  'dieciocho', 'diecinueve', 'veinte', 'veintiuno', 'veintidós', 'veintitrés',
  'veinticuatro', 'veinticinco', 'veintiséis', 'veintisiete', 'veintiocho', 'veintinueve',
];
const _decenas = {30: 'treinta', 40: 'cuarenta', 50: 'cincuenta'};

/// Número de 0 a 59 en palabras.
String numeroEnPalabras(int n) {
  if (n < 30) return _unidades[n];
  final d = (n ~/ 10) * 10, u = n % 10;
  return u == 0 ? _decenas[d]! : '${_decenas[d]} y ${_unidades[u]}';
}

/// "Son las ocho\ny diecisiete", "Es la una\ny cuarto", "Son las doce\nen punto"
String horaEnPalabras(DateTime d) {
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final nombreHora = h == 1 ? 'una' : numeroEnPalabras(h);
  final inicio = h == 1 ? 'Es la $nombreHora' : 'Son las $nombreHora';
  final m = d.minute;
  final String fin;
  if (m == 0) {
    fin = 'en punto';
  } else if (m == 15) {
    fin = 'y cuarto';
  } else if (m == 30) {
    fin = 'y media';
  } else {
    fin = 'y ${numeroEnPalabras(m)}';
  }
  return '$inicio\n$fin';
}
