import 'package:flutter/material.dart';

import '../modelo.dart';
import '../plataforma.dart';
import '../widgets/fila_app.dart';

const _fondoPanel = Color(0xE6101420);
const _blanco = TextStyle(color: Colors.white, fontSize: 16);
const _gris = TextStyle(color: Colors.white60, fontSize: 13);

class PantallaAjustes extends StatelessWidget {
  const PantallaAjustes({super.key, required this.modelo});

  final Modelo modelo;

  @override
  Widget build(BuildContext context) {
    final m = modelo;
    return ListenableBuilder(
      listenable: m,
      builder: (context, _) => Scaffold(
        backgroundColor: _fondoPanel,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          title: const Text('Ajustes del launcher'),
        ),
        body: ListView(
          children: [
            _titulo('Favoritos'),
            ListTile(
              leading: const Icon(Icons.star, color: Colors.white),
              title: const Text('Editar favoritos', style: _blanco),
              subtitle: Text('${m.favoritas.length} apps · ordenar, quitar y añadir', style: _gris),
              trailing: const Icon(Icons.chevron_right, color: Colors.white54),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(builder: (_) => PantallaFavoritos(modelo: m)),
              ),
            ),
            _titulo('Aspecto'),
            SwitchListTile(
              secondary: const Icon(Icons.schedule, color: Colors.white),
              title: const Text('Reloj de 24 horas', style: _blanco),
              value: m.reloj24,
              onChanged: m.ponerReloj24,
            ),
            SwitchListTile(
              secondary: const Icon(Icons.apps, color: Colors.white),
              title: const Text('Mostrar iconos', style: _blanco),
              value: m.mostrarIconos,
              onChanged: m.ponerMostrarIconos,
            ),
            SwitchListTile(
              secondary: const Icon(Icons.landscape, color: Colors.white),
              title: const Text('Fondo de galaxia', style: _blanco),
              subtitle: const Text('Apagado: se usa el fondo de pantalla del teléfono', style: _gris),
              value: m.fondoGalaxia,
              onChanged: m.ponerFondoGalaxia,
            ),
            SwitchListTile(
              secondary: const Icon(Icons.contrast, color: Colors.white),
              title: const Text('Oscurecer un poco el fondo', style: _blanco),
              subtitle: const Text('Ayuda a leer con fondos claros', style: _gris),
              value: m.oscurecer,
              onChanged: m.ponerOscurecer,
            ),
            ListTile(
              leading: const Icon(Icons.format_size, color: Colors.white),
              title: const Text('Tamaño del texto', style: _blanco),
              subtitle: Slider(
                value: m.tamTexto,
                min: 15,
                max: 28,
                divisions: 13,
                label: m.tamTexto.round().toString(),
                onChanged: m.ponerTamTexto,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.wallpaper, color: Colors.white),
              title: const Text('Cambiar fondo de pantalla del teléfono', style: _blanco),
              onTap: Plataforma.elegirFondo,
            ),
            _titulo('Sistema'),
            ListTile(
              leading: const Icon(Icons.home_outlined, color: Colors.white),
              title: const Text('Usar como pantalla de inicio', style: _blanco),
              subtitle: const Text('Elige "Lanzador" como app de inicio predeterminada', style: _gris),
              onTap: Plataforma.launcherPredeterminado,
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 24, 20, 32),
              child: Text(
                'Gestos: toca o desliza por las letras de la derecha para ver las apps de cada letra; '
                'la estrella vuelve a los favoritos. Desliza hacia arriba para buscar entre todas las apps '
                'y hacia abajo para abrir las notificaciones. Mantén pulsada una app para añadirla a '
                'favoritos, ver su información o desinstalarla.',
                style: _gris,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _titulo(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
        child: Text(t.toUpperCase(),
            style: const TextStyle(
                color: Color(0xFFFFD54F), fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
      );
}

/// Ordenar (arrastrando), quitar y añadir favoritos.
class PantallaFavoritos extends StatelessWidget {
  const PantallaFavoritos({super.key, required this.modelo});

  final Modelo modelo;

  @override
  Widget build(BuildContext context) {
    final m = modelo;
    return ListenableBuilder(
      listenable: m,
      builder: (context, _) {
        final favs = m.favoritas;
        return Scaffold(
          backgroundColor: const Color(0xFF101420),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            title: const Text('Favoritos'),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => PantallaElegirApps(modelo: m)),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Añadir'),
          ),
          body: favs.isEmpty
              ? const Center(child: Text('No hay favoritos todavía', style: _gris))
              : ReorderableListView.builder(
                  padding: const EdgeInsets.only(bottom: 96),
                  itemCount: favs.length,
                  onReorderItem: m.moverFavorita,
                  itemBuilder: (_, i) {
                    final a = favs[i];
                    return ListTile(
                      key: ValueKey(a.clave),
                      leading: IconoApp(app: a, modelo: m, tam: 40),
                      title: Text(a.nombre, style: _blanco),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'Quitar',
                            icon: const Icon(Icons.remove_circle_outline, color: Colors.white70),
                            onPressed: () => m.alternarFavorita(a),
                          ),
                          ReorderableDragStartListener(
                            index: i,
                            child: const Padding(
                              padding: EdgeInsets.all(8),
                              child: Icon(Icons.drag_handle, color: Colors.white70),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}

/// Lista de todas las apps con casillas para marcar favoritos.
class PantallaElegirApps extends StatefulWidget {
  const PantallaElegirApps({super.key, required this.modelo});

  final Modelo modelo;

  @override
  State<PantallaElegirApps> createState() => _PantallaElegirAppsState();
}

class _PantallaElegirAppsState extends State<PantallaElegirApps> {
  String _texto = '';

  @override
  Widget build(BuildContext context) {
    final m = widget.modelo;
    return ListenableBuilder(
      listenable: m,
      builder: (context, _) {
        final lista = m.buscar(_texto);
        return Scaffold(
          backgroundColor: const Color(0xFF101420),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            title: TextField(
              style: const TextStyle(color: Colors.white),
              cursorColor: Colors.white,
              decoration: const InputDecoration(
                hintText: 'Buscar app',
                hintStyle: TextStyle(color: Colors.white54),
                border: InputBorder.none,
              ),
              onChanged: (t) => setState(() => _texto = t),
            ),
          ),
          body: ListView.builder(
            itemCount: lista.length,
            itemBuilder: (_, i) {
              final a = lista[i];
              return CheckboxListTile(
                value: m.esFavorita(a),
                onChanged: (_) => m.alternarFavorita(a),
                secondary: IconoApp(app: a, modelo: m, tam: 40),
                title: Text(a.nombre, style: _blanco),
              );
            },
          ),
        );
      },
    );
  }
}
