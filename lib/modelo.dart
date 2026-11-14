import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'plataforma.dart';
import 'temas.dart';
import 'texto.dart';

/// Apps que se ponen como favoritas la primera vez (si están instaladas),
/// en este orden. Cada grupo son alternativas para la misma función.
const _favoritasIniciales = [
  ['com.whatsapp'],
  ['com.instagram.android'],
  ['com.facebook.katana'],
  ['com.spotify.music'],
  ['com.google.android.gm'],
  [
    'com.google.android.dialer',
    'com.samsung.android.dialer',
    'com.android.dialer',
  ],
  [
    'com.google.android.calendar',
    'com.samsung.android.calendar',
    'com.android.calendar',
  ],
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
    return WidgetColocado(
      id,
      p.length > 1 ? double.tryParse(p[1]) ?? 160 : 160,
    );
  }
}

class Modelo extends ChangeNotifier {
  SharedPreferences? _prefs;

  List<AppInfo> apps = [];
  List<String> _favoritos = [];
  List<WidgetColocado> widgets = [];

  /// Sube cada vez que se vuelve al inicio para recrear las vistas de los widgets.
  int generacionWidgets = 0;

  /// Apps con notificaciones pendientes (paquete → cantidad).
  Map<String, int> notificaciones = {};
  bool puntosNotificacion = true;
  bool permisoNotificaciones = false;
  bool notificacionesDisponibles = false;
  bool cargado = false;

  bool reloj24 = true;
  bool mostrarIconos = true;
  bool oscurecer = true;
  bool fondoGalaxia = false;
  double tamTexto = 20;

  // Personalización
  String temaId = 'galaxia';
  bool dobleToque = false;
  String navegacion =
      'letras'; // 'letras' (índice A–Z) o 'boton' (botón de apps)
  String estiloReloj = 'clasico';
  bool relojAcento = false; // reloj con el color de acento del tema
  double escalaReloj = 1.0;
  bool relojCentrado = false;
  bool mostrarFecha = true;
  String formaIcono = 'redondeado';
  double escalaIcono = 1.0;
  bool iconosByN = false;
  String packIconos = '';
  Map<String, String> _nombres = {};
  List<AppInfo> _appsSistema = [];

  Tema get tema => temaPorId(temaId);

  final Map<String, Future<IconoDatos?>> _iconos = {};

  Future<void> iniciar() async {
    _prefs = await SharedPreferences.getInstance();
    final p = _prefs!;
    reloj24 = p.getBool('reloj24') ?? true;
    mostrarIconos = p.getBool('mostrarIconos') ?? true;
    oscurecer = p.getBool('oscurecer') ?? true;
    fondoGalaxia = p.getBool('fondoGalaxia') ?? false;
    tamTexto = p.getDouble('tamTexto') ?? 20;
    temaId = p.getString('temaId') ?? 'galaxia';
    navegacion = p.getString('navegacion') ?? 'letras';
    dobleToque = p.getBool('dobleToque') ?? false;
    puntosNotificacion = p.getBool('puntosNotificacion') ?? true;
    estiloReloj = p.getString('estiloReloj') ?? 'clasico';
    relojAcento = p.getBool('relojAcento') ?? false;
    escalaReloj = p.getDouble('escalaReloj') ?? 1.0;
    relojCentrado = p.getBool('relojCentrado') ?? false;
    mostrarFecha = p.getBool('mostrarFecha') ?? true;
    formaIcono = p.getString('formaIcono') ?? 'redondeado';
    escalaIcono = p.getDouble('escalaIcono') ?? 1.0;
    iconosByN = p.getBool('iconosByN') ?? false;
    packIconos = p.getString('packIconos') ?? '';
    _nombres = {
      for (final linea in p.getStringList('nombres') ?? <String>[])
        if (linea.contains('\t'))
          linea.split('\t').first: linea.split('\t').last,
    };
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
      _appsSistema = await Plataforma.apps();
      _aplicarNombres();
      final claves = apps.map((a) => a.clave).toSet();
      _iconos.removeWhere((k, _) => !claves.contains(k.split('|').first));
      notifyListeners();
    } catch (_) {}
  }

  void _aplicarNombres() {
    final lista = [
      for (final a in _appsSistema)
        if (_nombres[a.clave] case final n? when n.trim().isNotEmpty)
          a.conNombre(n.trim())
        else
          a,
    ];
    lista.sort((a, b) => compararNombres(a.nombre, b.nombre));
    apps = lista;
  }

  void renombrar(AppInfo a, String nombre) {
    final n = nombre.trim();
    if (n.isEmpty || n == a.nombreOriginal) {
      _nombres.remove(a.clave);
    } else {
      _nombres[a.clave] = n;
    }
    _prefs?.setStringList('nombres', [
      for (final e in _nombres.entries) '${e.key}\t${e.value}',
    ]);
    _aplicarNombres();
    notifyListeners();
  }

  /// Fuerza a volver a pedir los iconos (por ejemplo tras actualizar una app).
  void olvidarIconos() => _iconos.clear();

  Future<IconoDatos?> icono(AppInfo a) => _iconos.putIfAbsent(
    '${a.clave}|$packIconos',
    () => Plataforma.icono(a, packIconos),
  );

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
      _favoritos = favoritas
          .where((f) => f.clave != a.clave)
          .map((f) => f.clave)
          .toList();
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
    final s = apps.map((a) => a.letra).toSet().toList()
      ..sort((a, b) {
        if (a == '#') return 1;
        if (b == '#') return -1;
        return a.compareTo(b);
      });
    return s;
  }

  List<AppInfo> appsDeLetra(String letra) =>
      apps.where((a) => a.letra == letra).toList();

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

  void _guardarWidgets() => _prefs?.setStringList(
    'widgets',
    widgets.map((w) => w.toString()).toList(),
  );

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

  // ---- Personalización ----
  void _s(String k, Object v) {
    final p = _prefs;
    if (p == null) return;
    if (v is bool) p.setBool(k, v);
    if (v is double) p.setDouble(k, v);
    if (v is String) p.setString(k, v);
  }

  void ponerPuntosNotificacion(bool v) {
    puntosNotificacion = v;
    _s('puntosNotificacion', v);
    notifyListeners();
  }

  void ponerNotificaciones(Map<String, int> n) {
    notificaciones = n;
    notifyListeners();
  }

  Future<void> comprobarPermisoNotificaciones() async {
    notificacionesDisponibles = await Plataforma.notificacionesDisponibles();
    permisoNotificaciones = await Plataforma.permisoNotificaciones();
    if (permisoNotificaciones)
      notificaciones = await Plataforma.notificaciones();
    notifyListeners();
  }

  void recrearWidgets() {
    generacionWidgets++;
    notifyListeners();
  }

  void ponerDobleToque(bool v) {
    dobleToque = v;
    _s('dobleToque', v);
    notifyListeners();
  }

  void ponerNavegacion(String v) {
    navegacion = v;
    _s('navegacion', v);
    notifyListeners();
  }

  void ponerTema(String v) {
    temaId = v;
    _s('temaId', v);
    notifyListeners();
  }

  void ponerEstiloReloj(String v) {
    estiloReloj = v;
    _s('estiloReloj', v);
    notifyListeners();
  }

  void ponerRelojAcento(bool v) {
    relojAcento = v;
    _s('relojAcento', v);
    notifyListeners();
  }

  void ponerEscalaReloj(double v) {
    escalaReloj = v;
    _s('escalaReloj', v);
    notifyListeners();
  }

  void ponerRelojCentrado(bool v) {
    relojCentrado = v;
    _s('relojCentrado', v);
    notifyListeners();
  }

  void ponerMostrarFecha(bool v) {
    mostrarFecha = v;
    _s('mostrarFecha', v);
    notifyListeners();
  }

  void ponerFormaIcono(String v) {
    formaIcono = v;
    _s('formaIcono', v);
    notifyListeners();
  }

  void ponerEscalaIcono(double v) {
    escalaIcono = v;
    _s('escalaIcono', v);
    notifyListeners();
  }

  void ponerIconosByN(bool v) {
    iconosByN = v;
    _s('iconosByN', v);
    notifyListeners();
  }

  void ponerPackIconos(String v) {
    packIconos = v;
    _s('packIconos', v);
    notifyListeners();
  }

  void ponerTamTexto(double v) {
    tamTexto = v;
    _prefs?.setDouble('tamTexto', v);
    notifyListeners();
  }
}
