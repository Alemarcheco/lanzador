import 'package:flutter/services.dart';

import 'texto.dart';

/// Una app instalada que se puede abrir.
class AppInfo {
  AppInfo({required this.paquete, required this.actividad, required this.nombre})
      : letra = letraDe(nombre);

  final String paquete;
  final String actividad;
  final String nombre;
  final String letra;

  String get clave => '$paquete/$actividad';
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

  static void iniciar() {
    _canal.setMethodCallHandler((llamada) async {
      switch (llamada.method) {
        case 'appsCambiadas':
          alCambiarApps?.call();
        case 'botonInicio':
          alBotonInicio?.call();
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

  static Future<Uint8List?> icono(AppInfo app) async {
    try {
      return await _canal.invokeMethod<Uint8List>('icono', {
        'paquete': app.paquete,
        'actividad': app.actividad,
        'tam': 144,
      });
    } catch (_) {
      return null;
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
  static Future<void> notificaciones() => _llamar('notificaciones');
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
