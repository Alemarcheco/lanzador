import 'package:flutter/services.dart';

import 'texto.dart';

/// Una app instalada que se puede abrir.
class AppInfo {
  AppInfo({required this.paquete, required this.actividad, required this.nombre, String? nombreOriginal})
      : letra = letraDe(nombre),
        nombreOriginal = nombreOriginal ?? nombre;

  final String paquete;
  final String actividad;
  final String nombre; // el que se muestra (puede estar renombrado)
  final String nombreOriginal;
  final String letra;

  AppInfo conNombre(String n) =>
      AppInfo(paquete: paquete, actividad: actividad, nombre: n, nombreOriginal: nombreOriginal);

  String get clave => '$paquete/$actividad';
}

/// Icono ya dibujado. Si viene de un paquete de iconos no se recorta.
class IconoDatos {
  IconoDatos(this.png, this.dePack);
  final Uint8List png;
  final bool dePack;
}

/// Paquete de iconos instalado (de Play Store).
class PackIconos {
  PackIconos(this.paquete, this.nombre);
  final String paquete, nombre;
}

/// Un tipo de widget que ofrece alguna app instalada.
class ProveedorWidget {
  ProveedorWidget(Map<Object?, Object?> m)
      : proveedor = m['proveedor'] as String,
        nombre = m['nombre'] as String,
        app = m['app'] as String,
        paquete = m['paquete'] as String,
        ancho = (m['ancho'] as num).toInt(),
        alto = (m['alto'] as num).toInt();

  final String proveedor, nombre, app, paquete;
  final int ancho, alto; // tamaño mínimo en dp
}

/// Puente con Android (lista de apps, iconos, abrir apps…).
class Plataforma {
  static const _canal = MethodChannel('com.feito.lanzador/apps');

  static VoidCallback? alCambiarApps;
  static VoidCallback? alBotonInicio;
  static void Function(Map<String, int>)? alNotificaciones;

  static void iniciar() {
    _canal.setMethodCallHandler((llamada) async {
      switch (llamada.method) {
        case 'appsCambiadas':
          alCambiarApps?.call();
        case 'botonInicio':
          alBotonInicio?.call();
        case 'notificaciones':
          alNotificaciones?.call(_mapaConteo(llamada.arguments));
      }
      return null;
    });
  }

  static Future<List<AppInfo>> apps() async {
    final lista = await _canal.invokeListMethod<Map<Object?, Object?>>('apps') ?? [];
    return [
      for (final m in lista)
        AppInfo(
          paquete: m['paquete'] as String,
          actividad: m['actividad'] as String,
          nombre: m['nombre'] as String,
        ),
    ];
  }

  static Future<IconoDatos?> icono(AppInfo app, String pack) async {
    try {
      final r = await _canal.invokeMapMethod<String, Object?>('icono', {
        'paquete': app.paquete,
        'actividad': app.actividad,
        'tam': 168,
        'pack': pack,
      });
      final png = r?['png'];
      if (png is! Uint8List) return null;
      return IconoDatos(png, r?['pack'] == true);
    } catch (_) {
      return null;
    }
  }

  static Future<List<PackIconos>> packsIconos() async {
    try {
      final l = await _canal.invokeListMethod<Map<Object?, Object?>>('packsIconos') ?? [];
      return [for (final m in l) PackIconos(m['paquete'] as String, m['nombre'] as String)];
    } catch (_) {
      return [];
    }
  }

  static Future<void> _llamar(String metodo, [Map<String, Object?>? args]) async {
    try {
      await _canal.invokeMethod<bool>(metodo, args);
    } catch (_) {}
  }

  static Future<void> abrir(AppInfo a) =>
      _llamar('abrir', {'paquete': a.paquete, 'actividad': a.actividad});
  static Future<void> infoApp(AppInfo a) => _llamar('infoApp', {'paquete': a.paquete});
  static Future<void> desinstalar(AppInfo a) => _llamar('desinstalar', {'paquete': a.paquete});
  static Future<void> panelNotificaciones() => _llamar('panelNotificaciones');

  static Map<String, int> _mapaConteo(Object? a) => {
        if (a is Map)
          for (final e in a.entries)
            if (e.key is String && e.value is num) e.key as String: (e.value as num).toInt(),
      };

  static Future<Map<String, int>> notificaciones() async {
    try {
      return _mapaConteo(await _canal.invokeMethod<Object?>('notificaciones'));
    } catch (_) {
      return {};
    }
  }

  static Future<bool> notificacionesDisponibles() async {
    try {
      return await _canal.invokeMethod<bool>('notificacionesDisponibles') ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> permisoNotificaciones() async {
    try {
      return await _canal.invokeMethod<bool>('permisoNotificaciones') ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<String?> ultimoError() async {
    try {
      return await _canal.invokeMethod<String>('ultimoError');
    } catch (_) {
      return null;
    }
  }

  static Future<void> borrarError() => _llamar('borrarError');

  static Future<void> pedirPermisoNotificaciones() => _llamar('pedirPermisoNotificaciones');
  static Future<void> reloj() => _llamar('reloj');
  static Future<void> calendario() => _llamar('calendario');
  static Future<void> elegirFondo() => _llamar('fondo');
  static Future<List<ProveedorWidget>> proveedoresWidget() async {
    try {
      final l = await _canal.invokeListMethod<Map<Object?, Object?>>('proveedoresWidget') ?? [];
      return [for (final m in l) ProveedorWidget(m)];
    } catch (_) {
      return [];
    }
  }

  static Future<Uint8List?> vistaPreviaWidget(String proveedor) async {
    try {
      return await _canal.invokeMethod<Uint8List>('vistaPreviaWidget', {'proveedor': proveedor});
    } catch (_) {
      return null;
    }
  }

  /// Pide permiso, abre la configuración del widget si la tiene y
  /// devuelve {id, alto} o null si se canceló.
  static Future<Map<Object?, Object?>?> anadirWidget(String proveedor) async {
    try {
      return await _canal.invokeMapMethod<Object?, Object?>('anadirWidget', {'proveedor': proveedor});
    } catch (_) {
      return null;
    }
  }

  static Future<void> quitarWidget(int id) => _llamar('quitarWidget', {'id': id});

  static Future<void> launcherPredeterminado() => _llamar('launcherPredeterminado');
}
