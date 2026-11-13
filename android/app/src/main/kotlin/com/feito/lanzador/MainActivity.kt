package com.feito.lanzador

import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.graphics.Bitmap
import android.graphics.Canvas
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.provider.AlarmClock
import android.provider.Settings
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
                else -> resultado.notImplemented()
            }
        }
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

    private fun icono(paquete: String, actividad: String, tam: Int): ByteArray {
        val pm = packageManager
        val dibujo = try {
            pm.getActivityIcon(ComponentName(paquete, actividad))
        } catch (_: Exception) {
            pm.defaultActivityIcon
        }
        val mapa = Bitmap.createBitmap(tam, tam, Bitmap.Config.ARGB_8888)
        val lienzo = Canvas(mapa)
        dibujo.setBounds(0, 0, tam, tam)
        dibujo.draw(lienzo)
        val salida = ByteArrayOutputStream()
        mapa.compress(Bitmap.CompressFormat.PNG, 100, salida)
        mapa.recycle()
        return salida.toByteArray()
    }
}
