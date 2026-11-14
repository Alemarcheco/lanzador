package com.feito.lanzador

import android.app.Notification
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification

/**
 * Lee qué apps tienen notificaciones pendientes para dibujar el punto junto a su nombre.
 * Solo funciona si el usuario da "Acceso a notificaciones" al Lanzador.
 */
class Notificaciones : NotificationListenerService() {

    companion object {
        @Volatile var activo: Notificaciones? = null
        @Volatile var alCambiar: ((Map<String, Int>) -> Unit)? = null

        fun conteo(): Map<String, Int> {
            val s = activo ?: return emptyMap()
            return try {
                val res = HashMap<String, Int>()
                for (n in s.activeNotifications ?: emptyArray()) {
                    val f = n.notification.flags
                    val esResumen = (f and Notification.FLAG_GROUP_SUMMARY) != 0
                    val enCurso = (f and Notification.FLAG_ONGOING_EVENT) != 0 ||
                        (f and Notification.FLAG_FOREGROUND_SERVICE) != 0
                    if (esResumen || enCurso) continue
                    res[n.packageName] = (res[n.packageName] ?: 0) + 1
                }
                res
            } catch (_: Exception) {
                emptyMap()
            }
        }

        private fun avisar() {
            alCambiar?.invoke(conteo())
        }
    }

    override fun onListenerConnected() {
        activo = this
        avisar()
    }

    override fun onListenerDisconnected() {
        activo = null
        alCambiar?.invoke(emptyMap())
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) = avisar()

    override fun onNotificationRemoved(sbn: StatusBarNotification?) = avisar()
}
