import 'package:flutter/material.dart';

import '../modelo.dart';
import '../plataforma.dart';
import '../temas.dart';
import '../widgets/fila_app.dart';
import '../widgets/forma_icono.dart';
import '../widgets/reloj.dart';

const _fondo = Color(0xFF0E1220);
const _blanco = TextStyle(color: Colors.white, fontSize: 16);
const _gris = TextStyle(color: Colors.white60, fontSize: 13);
const _cielo = BoxDecoration(
  gradient: LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0B1B3A), Color(0xFF1B3B6F), Color(0xFF0A0F1E)],
  ),
);

AppBar _barra(String t) => AppBar(
  backgroundColor: Colors.transparent,
  foregroundColor: Colors.white,
  title: Text(t),
);

Widget _titulo(String t) => Padding(
  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
  child: Text(
    t.toUpperCase(),
    style: const TextStyle(
      color: Color(0xFFFFD54F),
      fontSize: 12,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.2,
    ),
  ),
);

/// Elegir tema: tarjetas con una muestra de cada uno.
class PantallaTemas extends StatelessWidget {
  const PantallaTemas({super.key, required this.modelo});
  final Modelo modelo;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: modelo,
      builder: (context, _) => Scaffold(
        backgroundColor: _fondo,
        appBar: _barra('Temas'),
        body: GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 0.78,
          ),
          itemCount: temas.length,
          itemBuilder: (_, i) {
            final t = temas[i];
            final elegido = t.id == modelo.temaId;
            return GestureDetector(
              onTap: () => modelo.ponerTema(t.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.all(14),
                decoration: _cielo.copyWith(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: elegido ? t.acento : Colors.white12,
                    width: elegido ? 3 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '8:17',
                      style: t.estilo(40, peso: FontWeight.w500, altura: 1),
                    ),
                    Text('vie, 13 de nov', style: t.estilo(12)),
                    const SizedBox(height: 10),
                    for (final (n, c) in [
                      ('WhatsApp', const Color(0xFF25D366)),
                      ('Spotify', const Color(0xFF1DB954)),
                      ('Chrome', const Color(0xFF4285F4)),
                    ])
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: c,
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(n, style: t.estilo(13)),
                          ],
                        ),
                      ),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            t.nombre,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (elegido)
                          Icon(Icons.check_circle, color: t.acento, size: 20),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Editar el reloj: estilo, tamaño, color, posición y fecha.
class PantallaReloj extends StatelessWidget {
  const PantallaReloj({super.key, required this.modelo});
  final Modelo modelo;

  @override
  Widget build(BuildContext context) {
    final m = modelo;
    final hora = DateTime(2026, 11, 10, 8, 17);
    return ListenableBuilder(
      listenable: m,
      builder: (context, _) => Scaffold(
        backgroundColor: _fondo,
        appBar: _barra('Reloj'),
        body: ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            // Vista previa grande
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: _cielo.copyWith(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Reloj(modelo: m, horaFija: hora),
            ),
            _titulo('Estilo'),
            SizedBox(
              height: 150,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  for (final e in estilosReloj.entries)
                    GestureDetector(
                      onTap: () => m.ponerEstiloReloj(e.key),
                      child: Container(
                        width: 150,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.all(10),
                        decoration: _cielo.copyWith(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: e.key == m.estiloReloj
                                ? m.tema.acento
                                : Colors.white12,
                            width: e.key == m.estiloReloj ? 3 : 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.topLeft,
                                child: SizedBox(
                                  width: 300,
                                  child: EstiloReloj(
                                    estilo: e.key,
                                    tema: m.tema,
                                    hora: hora,
                                    formato24: m.reloj24,
                                    acento: m.relojAcento,
                                  ),
                                ),
                              ),
                            ),
                            Text(
                              e.value,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            _titulo('Ajustes'),
            ListTile(
              leading: const Icon(Icons.format_size, color: Colors.white),
              title: const Text('Tamaño', style: _blanco),
              subtitle: Slider(
                value: m.escalaReloj,
                min: 0.6,
                max: 1.6,
                divisions: 10,
                label: '${(m.escalaReloj * 100).round()} %',
                onChanged: m.ponerEscalaReloj,
              ),
            ),
            SwitchListTile(
              secondary: const Icon(
                Icons.color_lens_outlined,
                color: Colors.white,
              ),
              title: const Text('Color de acento del tema', style: _blanco),
              subtitle: const Text(
                'Si está apagado se usa el color del texto',
                style: _gris,
              ),
              value: m.relojAcento,
              onChanged: m.ponerRelojAcento,
            ),
            SwitchListTile(
              secondary: const Icon(
                Icons.format_align_center,
                color: Colors.white,
              ),
              title: const Text('Reloj centrado', style: _blanco),
              value: m.relojCentrado,
              onChanged: m.ponerRelojCentrado,
            ),
            SwitchListTile(
              secondary: const Icon(Icons.event, color: Colors.white),
              title: const Text('Mostrar la fecha', style: _blanco),
              value: m.mostrarFecha,
              onChanged: m.ponerMostrarFecha,
            ),
            SwitchListTile(
              secondary: const Icon(Icons.schedule, color: Colors.white),
              title: const Text('Formato de 24 horas', style: _blanco),
              value: m.reloj24,
              onChanged: m.ponerReloj24,
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Text(
                'Consejo: mantén pulsado el reloj en la pantalla de inicio para volver aquí. '
                'Los relojes de Samsung de la pantalla de bloqueo no se pueden usar fuera de Samsung, '
                'pero también puedes añadir como widget cualquier reloj que tengas instalado.',
                style: _gris,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Editar iconos: forma, tamaño, blanco y negro y paquete de iconos.
class PantallaIconos extends StatefulWidget {
  const PantallaIconos({super.key, required this.modelo});
  final Modelo modelo;

  @override
  State<PantallaIconos> createState() => _PantallaIconosState();
}

class _PantallaIconosState extends State<PantallaIconos> {
  List<PackIconos>? _packs;

  @override
  void initState() {
    super.initState();
    Plataforma.packsIconos().then((p) {
      if (mounted) setState(() => _packs = p);
    });
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.modelo;
    return ListenableBuilder(
      listenable: m,
      builder: (context, _) {
        final muestra = m.favoritas.take(4).toList();
        if (muestra.length < 4) {
          muestra.addAll(
            m.apps.where((a) => !muestra.contains(a)).take(4 - muestra.length),
          );
        }
        return Scaffold(
          backgroundColor: _fondo,
          appBar: _barra('Iconos'),
          body: ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 12,
                ),
                decoration: _cielo.copyWith(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    for (final a in muestra)
                      IconoApp(app: a, modelo: m, tam: 56 * m.escalaIcono),
                  ],
                ),
              ),
              _titulo('Forma'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final f in formasIcono.entries)
                      GestureDetector(
                        onTap: () => m.ponerFormaIcono(f.key),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: f.key == m.formaIcono
                                      ? m.tema.acento
                                      : Colors.transparent,
                                  width: 2.5,
                                ),
                              ),
                              child: ClipPath(
                                clipper: RecorteIcono(f.key),
                                child: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Color(0xFF5C7CFA),
                                        Color(0xFFB04DFF),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              f.value,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              _titulo('Ajustes'),
              ListTile(
                leading: const Icon(
                  Icons.photo_size_select_small,
                  color: Colors.white,
                ),
                title: const Text('Tamaño de los iconos', style: _blanco),
                subtitle: Slider(
                  value: m.escalaIcono,
                  min: 0.7,
                  max: 1.4,
                  divisions: 7,
                  label: '${(m.escalaIcono * 100).round()} %',
                  onChanged: m.ponerEscalaIcono,
                ),
              ),
              SwitchListTile(
                secondary: const Icon(
                  Icons.filter_b_and_w,
                  color: Colors.white,
                ),
                title: const Text('Iconos en blanco y negro', style: _blanco),
                value: m.iconosByN,
                onChanged: m.ponerIconosByN,
              ),
              SwitchListTile(
                secondary: const Icon(Icons.apps, color: Colors.white),
                title: const Text('Mostrar iconos', style: _blanco),
                subtitle: const Text(
                  'Apágalo para ver solo los nombres',
                  style: _gris,
                ),
                value: m.mostrarIconos,
                onChanged: m.ponerMostrarIconos,
              ),
              _titulo('Paquete de iconos'),
              RadioGroup<String>(
                groupValue: m.packIconos,
                onChanged: (v) => m.ponerPackIconos(v ?? ''),
                child: Column(
                  children: [
                    const RadioListTile<String>(
                      value: '',
                      title: Text('Iconos del sistema', style: _blanco),
                    ),
                    for (final p in _packs ?? <PackIconos>[])
                      RadioListTile<String>(
                        value: p.paquete,
                        title: Text(p.nombre, style: _blanco),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Text(
                  _packs == null
                      ? 'Buscando paquetes de iconos…'
                      : 'Instala paquetes de iconos desde Play Store (busca "icon pack", por ejemplo '
                            'los compatibles con Nova o ADW) y aparecerán aquí. Las apps que el paquete '
                            'no tenga conservan su icono normal.',
                  style: _gris,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
