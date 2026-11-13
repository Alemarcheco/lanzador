# Lanzador

Launcher (pantalla de inicio) minimalista para Android, hecho con Flutter.

- Fondo de pantalla del sistema detrás de todo.
- Hora grande y fecha en español arriba a la izquierda (toca la hora → alarmas, la fecha → calendario).
- Lista vertical de apps favoritas con icono y nombre.
- Índice A–Z en el borde derecho: toca o desliza el dedo por las letras para ver las apps de cada letra; la ★ vuelve a los favoritos. El circulito de abajo abre los ajustes.
- Mantén pulsada una app: añadir/quitar de favoritos, información de la app, desinstalar.
- Desliza hacia arriba para buscar entre todas las apps; hacia abajo para abrir las notificaciones.
- Ajustes: ordenar/añadir/quitar favoritos, reloj 12/24 h, mostrar iconos, oscurecer fondo, tamaño del texto, cambiar fondo, elegir como launcher predeterminado.

## Estructura
- `android/app/src/main/kotlin/.../MainActivity.kt`: lista de apps, iconos, abrir apps y demás funciones del sistema (canal `com.feito.lanzador/apps`).
- `lib/modelo.dart`: apps, favoritos y ajustes (guardados con shared_preferences).
- `lib/pantallas/`: inicio, búsqueda y ajustes. `lib/widgets/`: reloj, índice de letras y filas de apps.

## Compilar
```
flutter pub get
flutter test
flutter build apk      # build/app/outputs/flutter-apk/app-release.apk
```
Al subirlo a GitHub, la acción `Compilar APK` genera el APK automáticamente (pestaña Actions).

## Activarlo
Instala el APK, pulsa el botón de inicio y elige "Lanzador" → "Siempre". También desde Ajustes del launcher → "Usar como pantalla de inicio".
