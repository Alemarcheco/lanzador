import 'package:flutter/material.dart';

import '../modelo.dart';
import '../plataforma.dart';
import '../widgets/estilo.dart';
import '../widgets/fila_app.dart';
import '../widgets/indice.dart';
import '../widgets/reloj.dart';
import 'ajustes.dart';
import 'buscar.dart';

class PantallaInicio extends StatefulWidget {
  const PantallaInicio({super.key, required this.modelo, required this.navegador});

  final Modelo modelo;
  final GlobalKey<NavigatorState> navegador;

  @override
  State<PantallaInicio> createState() => _PantallaInicioState();
}

class _PantallaInicioState extends State<PantallaInicio> with WidgetsBindingObserver {
  String _seleccion = marcaFavoritos;
  Modelo get m => widget.modelo;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Plataforma.alBotonInicio = _volverAlInicio;
    Plataforma.alCambiarApps = () {
      m.olvidarIconos();
      m.recargar();
    };
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) m.recargar();
    if (state == AppLifecycleState.paused) {
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

  void _abrirBuscar() {
    Navigator.of(context).push(rutaTransparente(PantallaBuscar(modelo: m, alAbrir: _abrir)));
  }

  void _abrirAjustes() {
    Navigator.of(context).push(rutaTransparente(PantallaAjustes(modelo: m)));
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
                if (m.oscurecer)
                  const Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [Color(0x66000000), Color(0x11000000), Color(0x44000000)],
                          ),
                        ),
                      ),
                    ),
                  ),
                SafeArea(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: _zonaPrincipal(context)),
                      SizedBox(
                        width: 46,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 12, top: 140),
                          child: IndiceLetras(
                            letras: letras,
                            seleccion: _seleccion,
                            alElegir: (l) => setState(() => _seleccion = l),
                            alAjustes: _abrirAjustes,
                          ),
                        ),
                      ),
                    ],
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
        if (v > 300) Plataforma.notificaciones();
        if (v < -300) _abrirBuscar();
      },
      onLongPress: _abrirAjustes,
      child: Padding(
        padding: const EdgeInsets.only(left: 28, right: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: alto * 0.14),
            Reloj(formato24: m.reloj24),
            const SizedBox(height: 22),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 160),
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween(begin: const Offset(-0.04, 0), end: Offset.zero).animate(anim),
                    child: child,
                  ),
                ),
                child: KeyedSubtree(
                  key: ValueKey(_seleccion),
                  child: _lista(),
                ),
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
    if (esFav && lista.isEmpty) {
      return Align(
        alignment: Alignment.topLeft,
        child: TextButton.icon(
          onPressed: _abrirAjustes,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text('Añadir favoritos',
              style: TextStyle(color: Colors.white, fontSize: 18, shadows: sombraTexto)),
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
              style: const TextStyle(
                color: Color(0xCCFFFFFF),
                fontSize: 30,
                fontWeight: FontWeight.w800,
                shadows: sombraTexto,
              ),
            ),
          ),
        for (final a in lista) FilaApp(app: a, modelo: m, alAbrir: () => _abrir(a)),
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
          position: Tween(begin: const Offset(0, 0.04), end: Offset.zero)
              .animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
          child: child,
        ),
      ),
    );
