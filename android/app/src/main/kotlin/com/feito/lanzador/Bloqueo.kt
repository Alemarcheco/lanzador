package com.feito.lanzador

import android.accessibilityservice.AccessibilityService
import android.app.admin.DeviceAdminReceiver
import android.view.accessibility.AccessibilityEvent

/** Administrador de dispositivo: solo se usa para apagar la pantalla (lockNow). */
class AdminBloqueo : DeviceAdminReceiver()

/**
 * Servicio de accesibilidad (solo en la versión "con notificaciones"): apaga la pantalla
 * como el botón de encendido, sin obligar a usar el PIN en lugar de la huella.
 */
class ServicioBloqueo : AccessibilityService() {
    companion object {
        @Volatile var instancia: ServicioBloqueo? = null
    }

    override fun onServiceConnected() {
        instancia = this
    }

    override fun onUnbind(intent: android.content.Intent?): Boolean {
        instancia = null
        return super.onUnbind(intent)
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {}

    override fun onInterrupt() {}

    fun bloquear(): Boolean =
        if (android.os.Build.VERSION.SDK_INT >= 28) performGlobalAction(GLOBAL_ACTION_LOCK_SCREEN) else false
}
