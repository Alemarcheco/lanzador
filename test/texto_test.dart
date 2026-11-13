import 'package:flutter_test/flutter_test.dart';
import 'package:lanzador/texto.dart';

void main() {
  test('letra del índice', () {
    expect(letraDe('WhatsApp'), 'W');
    expect(letraDe('instagram'), 'I');
    expect(letraDe('Ágora'), 'A');
    expect(letraDe('Ñandú'), 'N');
    expect(letraDe('7-Zip'), '#');
    expect(letraDe(''), '#');
  });

  test('orden alfabético sin acentos y números al final', () {
    final l = ['Teléfono', '1Password', 'calendario', 'Chrome', 'Ábaco']
      ..sort(compararNombres);
    expect(l, ['Ábaco', 'calendario', 'Chrome', 'Teléfono', '1Password']);
  });

  test('fecha y hora en español', () {
    final d = DateTime(2026, 11, 10, 8, 17);
    expect(fechaCorta(d), 'mar, 10 de nov');
    expect(horaTexto(d), '8:17');
    expect(horaTexto(DateTime(2026, 1, 1, 15, 5), formato24: false), '3:05');
    expect(horaTexto(DateTime(2026, 1, 1, 0, 5), formato24: false), '12:05');
  });
}
