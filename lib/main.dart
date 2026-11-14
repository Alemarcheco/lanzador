import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'modelo.dart';
import 'pantallas/inicio.dart';
import 'plataforma.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  Plataforma.iniciar();
  final modelo = Modelo()..iniciar();
  runApp(Lanzador(modelo: modelo));
}

class Lanzador extends StatelessWidget {
  Lanzador({super.key, required this.modelo});

  final Modelo modelo;
  final _navegador = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lanzador',
      debugShowCheckedModeBanner: false,
      navigatorKey: _navegador,
      color: Colors.transparent,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorSchemeSeed: const Color(0xFF5C7CFA),
        useMaterial3: true,
        fontFamily: 'Nunito',
        scaffoldBackgroundColor: Colors.transparent,
      ),
      home: PantallaInicio(modelo: modelo, navegador: _navegador),
    );
  }
}
