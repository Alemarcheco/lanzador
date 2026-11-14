import 'package:flutter/material.dart';

import '../modelo.dart';
import '../plataforma.dart';
import '../widgets/fila_app.dart';

/// Todas las apps con buscador (deslizar hacia arriba en el inicio).
class PantallaBuscar extends StatefulWidget {
  const PantallaBuscar({
    super.key,
    required this.modelo,
    required this.alAbrir,
    this.teclado = true,
  });

  /// Abrir el teclado al entrar (al deslizar sí; con el botón de apps no).
  final bool teclado;

  final Modelo modelo;
  final ValueChanged<AppInfo> alAbrir;

  @override
  State<PantallaBuscar> createState() => _PantallaBuscarState();
}

class _PantallaBuscarState extends State<PantallaBuscar> {
  String _texto = '';

  void _abrir(AppInfo a) {
    Navigator.pop(context);
    widget.alAbrir(a);
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.modelo;
    return ListenableBuilder(
      listenable: m,
      builder: (context, _) {
        final lista = m.buscar(_texto);
        return Scaffold(
          backgroundColor: const Color(0xB3000000),
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: TextField(
                    autofocus: widget.teclado,
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                    cursorColor: Colors.white,
                    textInputAction: TextInputAction.go,
                    onChanged: (t) => setState(() => _texto = t),
                    onSubmitted: (_) {
                      if (lista.isNotEmpty) _abrir(lista.first);
                    },
                    decoration: InputDecoration(
                      hintText: 'Buscar aplicaciones',
                      hintStyle: const TextStyle(color: Colors.white54),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Colors.white70,
                      ),
                      filled: true,
                      fillColor: const Color(0x22FFFFFF),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(28),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(28, 8, 20, 24),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    itemCount: lista.length,
                    itemBuilder: (_, i) => FilaApp(
                      app: lista[i],
                      modelo: m,
                      alAbrir: () => _abrir(lista[i]),
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
}
