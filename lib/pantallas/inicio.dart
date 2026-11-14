import 'package:flutter/material.dart';

import '../modelo.dart';
import '../temas.dart';
import '../plataforma.dart';
import '../widgets/fila_app.dart';
import '../widgets/indice.dart';
import '../widgets/reloj.dart';
import '../widgets/vista_widget.dart';
import 'ajustes.dart';
import 'buscar.dart';
import 'elegir_widget.dart';
import 'personalizar.dart';

class PantallaInicio extends StatefulWidget {
  const PantallaInicio({
    super.key,
    required this.modelo,
    required this.navegador,
  });

  final Modelo modelo;
  final GlobalKey<NavigatorState> navegador;

  @override
  State<PantallaInicio> createState() => _PantallaInicioState();
}

class _PantallaInicioState extends State<PantallaInicio>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  // Animación suave al volver al inicio desde una app.
  late final AnimationController _entrada = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 180),
    value: 1,
  );
  late final Animation<double> _curva = CurvedAnimation(
    parent: _entrada,
    curve: Curves.easeOutCubic,
  );

  String _seleccion = marcaFavoritos;
  Modelo get m => widget.modelo;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Plataforma.alBotonInicio = _volverAlInicio;
    Plataforma.alNotificaciones = m.ponerNotificaciones;
    m.comprobarPermisoNotificaciones();
    Plataforma.alCambiarApps = () {
      m.olvidarIconos();
      m.recargar();
    };
  }

  @override
  void dispose() {
    _entrada.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _entrada.forward(from: _entrada.value);
      m.recargar();
      m.recrearWidgets();
      m.comprobarPermisoNotificaciones();
    }
    if (state == AppLifecycleState.paused) {
      _entrada.value = 0;
      // Al volver al launcher se muestran otra vez los favoritos.
      _volverAlInicio();
    }
  }

  void _volverAlInicio() {
    widget.navegador.currentState?.popUntil((r) => r.isFirst);
    if (mounted && _seleccion != marcaFavoritos) {
      setState(() => _seleccion = marcaFavoritos);
    }
  }

  void _abrir(AppInfo a) {
    Plataforma.abrir(a);
  }

  Future<void> _apagarPantalla() async {
    final r = await Plataforma.bloquearPantalla();
    if (r == 'ok' || !mounted) return;
    final accesibilidad = r == 'falta_accesibilidad';
    final ir = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Apagar con doble toque'),
        content: Text(
          accesibilidad
              ? 'Activa "Lanzador: apagar pantalla con doble toque" en Accesibilidad → Aplicaciones instaladas. '
                    'Si Samsung dice "configuración restringida": Ajustes → Aplicaciones → Lanzador → ⋮ → '
                    'Permitir configuración restringida, y vuelve a intentarlo.'
              : 'Para apagar la pantalla, Android pide activar al Lanzador como "administrador" '
                    '(solo para bloquear). Ojo: tras apagarla así, se desbloquea con PIN o patrón '
                    'en lugar de huella o cara.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Ahora no'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Activar'),
          ),
        ],
      ),
    );
    if (ir == true) Plataforma.pedirPermisoBloqueo();
  }

  void _abrirBuscar({bool teclado = true}) {
    Navigator.of(context).push(
      rutaTransparente(
        PantallaBuscar(modelo: m, alAbrir: _abrir, teclado: teclado),
      ),
    );
  }

  void _abrirAjustes() {
    Navigator.of(context).push(rutaTransparente(PantallaAjustes(modelo: m)));
  }

  void _menuInicio() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xF0181C26),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.widgets_outlined, color: Colors.white),
              title: const Text(
                'Añadir widget',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => PantallaElegirWidget(modelo: m),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.palette_outlined, color: Colors.white),
              title: const Text(
                'Temas',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => PantallaTemas(modelo: m),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.schedule, color: Colors.white),
              title: const Text(
                'Editar reloj',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => PantallaReloj(modelo: m),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.apps, color: Colors.white),
              title: const Text(
                'Editar iconos',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => PantallaIconos(modelo: m),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.wallpaper, color: Colors.white),
              title: const Text(
                'Fondo de pantalla',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              onTap: () {
                Navigator.pop(ctx);
                Plataforma.elegirFondo();
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined, color: Colors.white),
              title: const Text(
                'Ajustes del launcher',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _abrirAjustes();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: m,
      builder: (context, _) {
        final letras = [marcaFavoritos, ...m.letras];
        if (!letras.contains(_seleccion)) _seleccion = marcaFavoritos;
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop && _seleccion != marcaFavoritos) {
              setState(() => _seleccion = marcaFavoritos);
            }
          },
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Stack(
              children: [
                if (m.fondoGalaxia)
                  Positioned.fill(
                    child: Image.asset(
                      'assets/fondos/galaxia.jpg',
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                    ),
                  ),
                if (m.oscurecer)
                  const Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              Color(0x66000000),
                              Color(0x11000000),
                              Color(0x44000000),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                FadeTransition(
                  opacity: _curva,
                  child: ScaleTransition(
                    scale: Tween(begin: 0.97, end: 1.0).animate(_curva),
                    child: SafeArea(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: _zonaPrincipal(context)),
                          if (m.navegacion == 'letras')
                            SizedBox(
                              width: 46,
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  bottom: 12,
                                  top: 140,
                                ),
                                child: IndiceLetras(
                                  letras: letras,
                                  seleccion: _seleccion,
                                  alElegir: (l) =>
                                      setState(() => _seleccion = l),
                                  alAjustes: _abrirAjustes,
                                  tema: m.tema,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (m.navegacion == 'boton')
                  Positioned(
                    right: 20,
                    bottom: 20 + MediaQuery.paddingOf(context).bottom,
                    child: FadeTransition(
                      opacity: _curva,
                      child: _BotonApps(
                        tema: m.tema,
                        alTocar: () => _abrirBuscar(teclado: false),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _zonaPrincipal(BuildContext context) {
    final alto = MediaQuery.sizeOf(context).height;
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onVerticalDragEnd: (d) {
        final v = d.primaryVelocity ?? 0;
        if (v > 300) Plataforma.panelNotificaciones();
        if (v < -300) _abrirBuscar();
      },
      onLongPress: _menuInicio,
      onDoubleTap: m.dobleToque ? _apagarPantalla : null,
      child: Padding(
        padding: const EdgeInsets.only(left: 28, right: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: alto * 0.14),
            Reloj(modelo: m),
            const SizedBox(height: 22),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 160),
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween(
                      begin: const Offset(-0.04, 0),
                      end: Offset.zero,
                    ).animate(anim),
                    child: child,
                  ),
                ),
                child: KeyedSubtree(key: ValueKey(_seleccion), child: _lista()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _lista() {
    if (!m.cargado) return const SizedBox();
    final esFav = _seleccion == marcaFavoritos;
    final lista = esFav ? m.favoritas : m.appsDeLetra(_seleccion);
    if (esFav && lista.isEmpty && m.widgets.isEmpty) {
      return Align(
        alignment: Alignment.topLeft,
        child: TextButton.icon(
          onPressed: _abrirAjustes,
          icon: Icon(Icons.add, color: m.tema.texto),
          label: Text('Añadir favoritos', style: m.tema.estilo(18)),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        if (!esFav)
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 4),
            child: Text(
              _seleccion,
              style: m.tema.estilo(
                30,
                color: m.tema.acento,
                peso: FontWeight.w700,
              ),
            ),
          ),
        if (esFav)
          for (final w in m.widgets)
            VistaWidget(key: ObjectKey(w), widgetColocado: w, modelo: m),
        for (final a in lista)
          FilaApp(app: a, modelo: m, alAbrir: () => _abrir(a)),
      ],
    );
  }
}

/// Ruta que deja ver el fondo de pantalla detrás.
Route<void> rutaTransparente(Widget pantalla) => PageRouteBuilder<void>(
  opaque: false,
  barrierColor: Colors.transparent,
  transitionDuration: const Duration(milliseconds: 200),
  reverseTransitionDuration: const Duration(milliseconds: 160),
  pageBuilder: (_, _, _) => pantalla,
  transitionsBuilder: (_, anim, _, child) => FadeTransition(
    opacity: anim,
    child: SlideTransition(
      position: Tween(
        begin: const Offset(0, 0.04),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
      child: child,
    ),
  ),
);

/// Botón redondo de la esquina inferior derecha que abre todas las apps.
class _BotonApps extends StatelessWidget {
  const _BotonApps({required this.tema, required this.alTocar});

  final Tema tema;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0x55000000),
      shape: CircleBorder(
        side: BorderSide(color: tema.texto.withValues(alpha: 0.7), width: 1.5),
      ),
      elevation: 0,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: alTocar,
        child: SizedBox.square(
          dimension: 60,
          child: Icon(
            Icons.apps_rounded,
            size: 30,
            color: tema.texto,
            shadows: tema.sombras,
          ),
        ),
      ),
    );
  }
}
