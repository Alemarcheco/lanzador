package com.feito.lanzador

import android.app.Activity
import android.appwidget.AppWidgetHost
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProviderInfo
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.AdaptiveIconDrawable
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.provider.AlarmClock
import android.provider.Settings
import android.view.Gravity
import android.view.View
import android.widget.TextView
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.FlutterActivityLaunchConfigs
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private var canal: MethodChannel? = null
    private val hilos = Executors.newFixedThreadPool(3)
    private val principal = Handler(Looper.getMainLooper())
    private var receptorRegistrado = false

    // ---- Widgets ----
    private val widgetManager by lazy { AppWidgetManager.getInstance(applicationContext) }
    private val widgetHost by lazy { AppWidgetHost(applicationContext, 1024) }
    private var resultadoWidget: MethodChannel.Result? = null
    private var widgetPendiente = -1

    private val receptorApps = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            canal?.invokeMethod("appsCambiadas", null)
        }
    }

    // Fondo transparente para que se vea el fondo de pantalla del sistema.
    override fun getBackgroundMode(): FlutterActivityLaunchConfigs.BackgroundMode =
        FlutterActivityLaunchConfigs.BackgroundMode.transparent

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val filtro = IntentFilter().apply {
            addAction(Intent.ACTION_PACKAGE_ADDED)
            addAction(Intent.ACTION_PACKAGE_REMOVED)
            addAction(Intent.ACTION_PACKAGE_CHANGED)
            addAction(Intent.ACTION_PACKAGE_REPLACED)
            addDataScheme("package")
        }
        if (Build.VERSION.SDK_INT >= 33) {
            registerReceiver(receptorApps, filtro, Context.RECEIVER_EXPORTED)
        } else {
            registerReceiver(receptorApps, filtro)
        }
        receptorRegistrado = true
    }

    override fun onStart() {
        super.onStart()
        try { widgetHost.startListening() } catch (_: Exception) {}
    }

    override fun onStop() {
        super.onStop()
        try { widgetHost.stopListening() } catch (_: Exception) {}
    }

    override fun onDestroy() {
        if (receptorRegistrado) {
            try { unregisterReceiver(receptorApps) } catch (_: Exception) {}
        }
        hilos.shutdown()
        super.onDestroy()
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        // Se pulsó el botón de inicio estando ya en el launcher.
        if (intent.hasCategory(Intent.CATEGORY_HOME)) {
            canal?.invokeMethod("botonInicio", null)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        flutterEngine.platformViewsController.registry
            .registerViewFactory("com.feito.lanzador/widget", FabricaWidget(this))
        val c = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.feito.lanzador/apps")
        canal = c
        c.setMethodCallHandler { llamada, resultado ->
            val paquete = llamada.argument<String>("paquete")
            val actividad = llamada.argument<String>("actividad")
            when (llamada.method) {
                "apps" -> enHilo(resultado) { listarApps() }
                "icono" -> enHilo(resultado) { icono(paquete!!, actividad!!, llamada.argument<Int>("tam") ?: 144) }
                "abrir" -> resultado.success(intentar {
                    val i = Intent(Intent.ACTION_MAIN)
                        .addCategory(Intent.CATEGORY_LAUNCHER)
                        .setComponent(ComponentName(paquete!!, actividad!!))
                        .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_RESET_TASK_IF_NEEDED)
                    startActivity(i)
                })
                "infoApp" -> resultado.success(intentar {
                    startActivity(
                        Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.parse("package:$paquete"))
                            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    )
                })
                "desinstalar" -> resultado.success(intentar {
                    startActivity(
                        Intent(Intent.ACTION_DELETE, Uri.parse("package:$paquete"))
                            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    )
                })
                "notificaciones" -> resultado.success(intentar {
                    @Suppress("WrongConstant")
                    val servicio = getSystemService("statusbar")
                    Class.forName("android.app.StatusBarManager")
                        .getMethod("expandNotificationsPanel")
                        .invoke(servicio)
                })
                "reloj" -> resultado.success(intentar {
                    startActivity(Intent(AlarmClock.ACTION_SHOW_ALARMS).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
                })
                "calendario" -> resultado.success(intentar {
                    startActivity(
                        Intent.makeMainSelectorActivity(Intent.ACTION_MAIN, Intent.CATEGORY_APP_CALENDAR)
                            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    )
                })
                "fondo" -> resultado.success(intentar {
                    startActivity(
                        Intent.createChooser(Intent(Intent.ACTION_SET_WALLPAPER), "Elegir fondo de pantalla")
                            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    )
                })
                "launcherPredeterminado" -> resultado.success(intentar {
                    startActivity(Intent(Settings.ACTION_HOME_SETTINGS).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
                })
                "proveedoresWidget" -> enHilo(resultado) { proveedoresWidget() }
                "vistaPreviaWidget" -> enHilo(resultado) { vistaPreviaWidget(llamada.argument<String>("proveedor")!!) }
                "anadirWidget" -> anadirWidget(llamada.argument<String>("proveedor")!!, resultado)
                "quitarWidget" -> {
                    try { widgetHost.deleteAppWidgetId(llamada.argument<Int>("id")!!) } catch (_: Exception) {}
                    resultado.success(true)
                }
                "existeWidget" -> resultado.success(widgetManager.getAppWidgetInfo(llamada.argument<Int>("id")!!) != null)
                else -> resultado.notImplemented()
            }
        }
    }

    // ---------------- Widgets ----------------

    private fun dp(px: Int): Int = (px / resources.displayMetrics.density).toInt()

    private fun proveedoresWidget(): List<Map<String, Any>> {
        val pm = packageManager
        return widgetManager.installedProviders.filter { info ->
            // Widgets que su app pide ocultar del selector.
            Build.VERSION.SDK_INT < 28 ||
                (info.widgetFeatures and AppWidgetProviderInfo.WIDGET_FEATURE_HIDE_FROM_PICKER) == 0
        }.map { info ->
            val paquete = info.provider.packageName
            val app = try {
                pm.getApplicationLabel(pm.getApplicationInfo(paquete, 0)).toString()
            } catch (_: Exception) { paquete }
            mapOf(
                "proveedor" to info.provider.flattenToString(),
                "nombre" to info.loadLabel(pm),
                "app" to app,
                "paquete" to paquete,
                "ancho" to dp(info.minWidth),
                "alto" to dp(info.minHeight),
            )
        }
    }

    private fun vistaPreviaWidget(proveedor: String): ByteArray? {
        val cn = ComponentName.unflattenFromString(proveedor) ?: return null
        val info = widgetManager.installedProviders.firstOrNull { it.provider == cn } ?: return null
        val densidad = resources.displayMetrics.densityDpi
        val d = info.loadPreviewImage(this, densidad) ?: info.loadIcon(this, densidad) ?: return null
        var w = d.intrinsicWidth.takeIf { it > 0 } ?: 300
        var h = d.intrinsicHeight.takeIf { it > 0 } ?: 300
        val escala = minOf(1f, 600f / maxOf(w, h))
        w = maxOf(1, (w * escala).toInt()); h = maxOf(1, (h * escala).toInt())
        val mapa = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
        d.setBounds(0, 0, w, h)
        d.draw(Canvas(mapa))
        val salida = ByteArrayOutputStream()
        mapa.compress(Bitmap.CompressFormat.PNG, 100, salida)
        mapa.recycle()
        return salida.toByteArray()
    }

    private fun anadirWidget(proveedor: String, resultado: MethodChannel.Result) {
        val cn = ComponentName.unflattenFromString(proveedor)
        if (cn == null) { resultado.success(mapOf("error" to "Widget no encontrado")); return }
        resultadoWidget?.success(null)
        resultadoWidget = resultado
        val id = widgetHost.allocateAppWidgetId()
        widgetPendiente = id
        val permitido = try {
            widgetManager.bindAppWidgetIdIfAllowed(id, cn)
        } catch (_: Exception) { false }
        if (permitido) {
            configurarWidget(id)
        } else {
            // Android pide permiso al usuario la primera vez.
            val i = Intent(AppWidgetManager.ACTION_APPWIDGET_BIND)
                .putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, id)
                .putExtra(AppWidgetManager.EXTRA_APPWIDGET_PROVIDER, cn)
            try {
                @Suppress("DEPRECATION")
                startActivityForResult(i, PEDIR_PERMISO)
            } catch (_: Exception) { cancelarWidget("Android no dejó pedir el permiso para widgets") }
        }
    }

    private fun configurarWidget(id: Int) {
        val info = widgetManager.getAppWidgetInfo(id)
        if (info == null) { cancelarWidget("La app no permitió crear el widget"); return }
        val configuracionOpcional = Build.VERSION.SDK_INT >= 31 &&
            (info.widgetFeatures and AppWidgetProviderInfo.WIDGET_FEATURE_CONFIGURATION_OPTIONAL) != 0
        if (info.configure == null || configuracionOpcional) { terminarWidget(id); return }
        try {
            if (Build.VERSION.SDK_INT >= 26) {
                widgetHost.startAppWidgetConfigureActivityForResult(this, id, 0, CONFIGURAR, null)
            } else {
                val i = Intent(AppWidgetManager.ACTION_APPWIDGET_CONFIGURE)
                    .setComponent(info.configure)
                    .putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, id)
                @Suppress("DEPRECATION")
                startActivityForResult(i, CONFIGURAR)
            }
        } catch (_: Exception) {
            // Algunos widgets no dejan abrir su configuración desde fuera: se añade igual.
            terminarWidget(id)
        }
    }

    private fun terminarWidget(id: Int) {
        val info = widgetManager.getAppWidgetInfo(id)
        resultadoWidget?.success(mapOf("id" to id, "alto" to (info?.let { dp(it.minHeight) } ?: 120)))
        resultadoWidget = null
        widgetPendiente = -1
    }

    private fun cancelarWidget(motivo: String) {
        if (widgetPendiente != -1) {
            try { widgetHost.deleteAppWidgetId(widgetPendiente) } catch (_: Exception) {}
        }
        widgetPendiente = -1
        resultadoWidget?.success(mapOf("error" to motivo))
        resultadoWidget = null
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        @Suppress("DEPRECATION")
        super.onActivityResult(requestCode, resultCode, data)
        val id = data?.getIntExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetPendiente) ?: widgetPendiente
        when (requestCode) {
            PEDIR_PERMISO ->
                // Algunos teléfonos devuelven "cancelado" aunque el permiso se dio:
                // se comprueba si el widget quedó vinculado.
                if (id != -1 && (resultCode == Activity.RESULT_OK || widgetManager.getAppWidgetInfo(id) != null)) {
                    configurarWidget(id)
                } else {
                    cancelarWidget("Hace falta permitir que Lanzador cree widgets")
                }
            CONFIGURAR ->
                // Muchas apps del clima cierran su configuración sin decir "OK":
                // si el widget sigue existiendo, se añade igual (se puede quitar después).
                if (id != -1 && widgetManager.getAppWidgetInfo(id) != null) {
                    terminarWidget(id)
                } else {
                    cancelarWidget("Se canceló la configuración del widget")
                }
        }
    }

    fun crearVistaWidget(contexto: Context, id: Int, anchoDp: Int, altoDp: Int): View {
        val info: AppWidgetProviderInfo? = widgetManager.getAppWidgetInfo(id)
        if (info == null) {
            return TextView(contexto).apply {
                text = "Widget no disponible (mantén pulsado para quitarlo)"
                setTextColor(0xCCFFFFFF.toInt())
                gravity = Gravity.CENTER
            }
        }
        val vista = widgetHost.createView(contexto, id, info)
        try {
            @Suppress("DEPRECATION")
            vista.updateAppWidgetSize(Bundle(), anchoDp, altoDp, anchoDp, altoDp)
        } catch (_: Exception) {}
        return vista
    }

    private fun intentar(accion: () -> Unit): Boolean = try {
        accion(); true
    } catch (_: Exception) {
        false
    }

    private fun enHilo(resultado: MethodChannel.Result, trabajo: () -> Any?) {
        hilos.execute {
            try {
                val valor = trabajo()
                principal.post { resultado.success(valor) }
            } catch (e: Exception) {
                principal.post { resultado.error("error", e.message, null) }
            }
        }
    }

    private fun listarApps(): List<Map<String, String>> {
        val pm = packageManager
        val intent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER)
        return pm.queryIntentActivities(intent, 0)
            .filter { it.activityInfo.packageName != packageName }
            .map {
                mapOf(
                    "paquete" to it.activityInfo.packageName,
                    "actividad" to it.activityInfo.name,
                    "nombre" to it.loadLabel(pm).toString(),
                )
            }
    }

    companion object {
        private const val PEDIR_PERMISO = 4101
        private const val CONFIGURAR = 4102
    }

    private fun icono(paquete: String, actividad: String, tam: Int): ByteArray {
        val pm = packageManager
        val dibujo = try {
            pm.getActivityIcon(ComponentName(paquete, actividad))
        } catch (_: Exception) {
            pm.defaultActivityIcon
        }
        val mapa = Bitmap.createBitmap(tam, tam, Bitmap.Config.ARGB_8888)
        val lienzo = Canvas(mapa)
        if (Build.VERSION.SDK_INT >= 26 && dibujo is AdaptiveIconDrawable) {
            // Se dibujan las capas completas (sin la máscara del sistema) para que
            // Flutter les dé la forma de cuadrado redondeado.
            val m = tam / 4
            dibujo.background?.let { it.setBounds(-m, -m, tam + m, tam + m); it.draw(lienzo) }
            dibujo.foreground?.let { it.setBounds(-m, -m, tam + m, tam + m); it.draw(lienzo) }
        } else {
            dibujo.setBounds(0, 0, tam, tam)
            dibujo.draw(lienzo)
        }
        val salida = ByteArrayOutputStream()
        mapa.compress(Bitmap.CompressFormat.PNG, 100, salida)
        mapa.recycle()
        return salida.toByteArray()
    }
}

/** Crea la vista nativa de un widget para mostrarla dentro de Flutter. */
class FabricaWidget(private val actividad: MainActivity) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        val p = args as? Map<*, *> ?: emptyMap<String, Any>()
        val id = (p["id"] as? Number)?.toInt() ?: -1
        val ancho = (p["ancho"] as? Number)?.toInt() ?: 300
        val alto = (p["alto"] as? Number)?.toInt() ?: 120
        val vista = actividad.crearVistaWidget(actividad, id, ancho, alto)
        return object : PlatformView {
            override fun getView(): View = vista
            override fun dispose() {}
        }
    }
}
