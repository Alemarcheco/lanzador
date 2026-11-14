import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'plataforma.dart';
import 'texto.dart';

/// Apps que se ponen como favoritas la primera vez (si están instaladas),
/// en este orden. Cada grupo son alternativas para la misma función.
const _favoritasIniciales = [
  ['com.whatsapp'],
  ['com.instagram.android'],
  ['com.facebook.katana'],
  ['com.spotify.music'],
  ['com.google.android.gm'],
  ['com.google.android.dialer', 'com.samsung.android.dialer', 'com.android.dialer'],
  ['com.google.android.calendar', 'com.samsung.android.calendar', 'com.android.calendar'],
  ['com.android.chrome'],
];

/// Widget colocado en la pantalla de inicio.
class WidgetColocado {
  WidgetColocado(this.id, this.alto);
  final int id;
  double alto; // dp

  @override
  String toString() => '$id:${alto.round()}';

  static WidgetColocado? leer(String s) {
    final p = s.split(':');
    final id = int.tryParse(p.first);
    if (id == null) return null;
    return WidgetColocado(id, p.length > 1 ? double.tryParse(p[1]) ?? 160 : 160);
  }
}

class Modelo extends ChangeNotifier {
  SharedPreferences? _prefs;

  List<AppInfo> apps = [];
  List<String> _favoritos = [];
  List<WidgetColocado> widgets = [];
  bool cargado = false;

  bool reloj24 = true;
  bool mostrarIconos = true;
  bool oscurecer = true;
  bool fondoGalaxia = false;
  double tamTexto = 20;

  final Map<String, Future<Uint8List?>> _iconos = {};

  Future<void> iniciar() async {
    _prefs = await SharedPreferences.getInstance();
    final p = _prefs!;
    reloj24 = p.getBool('reloj24') ?? true;
    mostrarIconos = p.getBool('mostrarIconos') ?? true;
    oscurecer = p.getBool('oscurecer') ?? true;
    fondoGalaxia = p.getBool('fondoGalaxia') ?? false;
    tamTexto = p.getDouble('tamTexto') ?? 20;
    widgets = (p.getStringList('widgets') ?? [])
        .map(WidgetColocado.leer)
        .whereType<WidgetColocado>()
        .toList();
    final guardados = p.getStringList('favoritos');
    await recargar();
    if (guardados == null) {
      _favoritos = _elegirIniciales();
      _guardarFavoritos();
    } else {
      _favoritos = guardados;
    }
    cargado = true;
    notifyListeners();
  }

  List<String> _elegirIniciales() {
    final res = <String>[];
    for (final grupo in _favoritasIniciales) {
      for (final paquete in grupo) {
        final a = apps.where((x) => x.paquete == paquete).firstOrNull;
        if (a != null) {
          res.add(a.clave);
          break;
        }
      }
    }
    return res;
  }

  Future<void> recargar() async {
    try {
      final nuevas = await Plataforma.apps();
      nuevas.sort((a, b) => compararNombres(a.nombre, b.nombre));
      final claves = nuevas.map((a) => a.clave).toSet();
      _iconos.removeWhere((k, _) => !claves.contains(k));
      apps = nuevas;
      notifyListeners();
    } catch (_) {}
  }

  /// Fuerza a volver a pedir los iconos (por ejemplo tras actualizar una app).
  void olvidarIconos() => _iconos.clear();

  Future<Uint8List?> icono(AppInfo a) =>
      _iconos.putIfAbsent(a.clave, () => Plataforma.icono(a));

  AppInfo? _buscar(String clave) {
    for (final a in apps) {
      if (a.clave == clave) return a;
    }
    // Si la app se actualizó y cambió de actividad, se busca por paquete.
    final paquete = clave.split('/').first;
    for (final a in apps) {
      if (a.paquete == paquete) return a;
    }
    return null;
  }

  List<AppInfo> get favoritas {
    final res = <AppInfo>[];
    final vistas = <String>{};
    for (final c in _favoritos) {
      final a = _buscar(c);
      if (a != null && vistas.add(a.clave)) res.add(a);
    }
    return res;
  }

  bool esFavorita(AppInfo a) => favoritas.any((f) => f.clave == a.clave);

  void alternarFavorita(AppInfo a) {
    if (esFavorita(a)) {
      _favoritos = favoritas.where((f) => f.clave != a.clave).map((f) => f.clave).toList();
    } else {
      _favoritos = [...favoritas.map((f) => f.clave), a.clave];
    }
    _guardarFavoritos();
    notifyListeners();
  }

  void moverFavorita(int desde, int hasta) {
    final lista = favoritas.map((f) => f.clave).toList();
    final c = lista.removeAt(desde);
    lista.insert(hasta, c);
    _favoritos = lista;
    _guardarFavoritos();
    notifyListeners();
  }

  void _guardarFavoritos() => _prefs?.setStringList('favoritos', _favoritos);

  /// Letras que tienen al menos una app, en orden (A–Z y '#' al final).
  List<String> get letras {
    final s = apps.map((a) => a.letra).toSet().toList()..sort((a, b) {
        if (a == '#') return 1;
        if (b == '#') return -1;
        return a.compareTo(b);
      });
    return s;
  }

  List<AppInfo> appsDeLetra(String letra) => apps.where((a) => a.letra == letra).toList();

  List<AppInfo> buscar(String texto) {
    final t = normalizar(texto.trim());
    if (t.isEmpty) return apps;
    final empiezan = <AppInfo>[], contienen = <AppInfo>[];
    for (final a in apps) {
      final n = normalizar(a.nombre);
      if (n.startsWith(t)) {
        empiezan.add(a);
      } else if (n.contains(t) || a.paquete.toUpperCase().contains(t)) {
        contienen.add(a);
      }
    }
    return [...empiezan, ...contienen];
  }

  // ---- Widgets ----
  static const altoMin = 60.0, altoMax = 600.0;

  void _guardarWidgets() =>
      _prefs?.setStringList('widgets', widgets.map((w) => w.toString()).toList());

  void agregarWidget(int id, double alto) {
    widgets.add(WidgetColocado(id, alto.clamp(80, 400).toDouble()));
    _guardarWidgets();
    notifyListeners();
  }

  void quitarWidget(WidgetColocado w) {
    widgets.remove(w);
    Plataforma.quitarWidget(w.id);
    _guardarWidgets();
    notifyListeners();
  }

  void cambiarAltoWidget(WidgetColocado w, double delta) {
    w.alto = (w.alto + delta).clamp(altoMin, altoMax).toDouble();
    _guardarWidgets();
    notifyListeners();
  }

  void moverWidget(WidgetColocado w, int paso) {
    final i = widgets.indexOf(w);
    final j = i + paso;
    if (i < 0 || j < 0 || j >= widgets.length) return;
    widgets
      ..removeAt(i)
      ..insert(j, w);
    _guardarWidgets();
    notifyListeners();
  }

  void ponerReloj24(bool v) {
    reloj24 = v;
    _prefs?.setBool('reloj24', v);
    notifyListeners();
  }

  void ponerMostrarIconos(bool v) {
    mostrarIconos = v;
    _prefs?.setBool('mostrarIconos', v);
    notifyListeners();
  }

  void ponerOscurecer(bool v) {
    oscurecer = v;
    _prefs?.setBool('oscurecer', v);
    notifyListeners();
  }

  void ponerFondoGalaxia(bool v) {
    fondoGalaxia = v;
    _prefs?.setBool('fondoGalaxia', v);
    notifyListeners();
  }

  void ponerTamTexto(double v) {
    tamTexto = v;
    _prefs?.setDouble('tamTexto', v);
    notifyListeners();
  }
}
