package br.com.sla.newpos_q_series

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import io.flutter.plugin.common.EventChannel

class NewposQStatusStreamHandler(
    private val context: Context,
) : EventChannel.StreamHandler {
    private var receiver: BroadcastReceiver? = null

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        if (events == null || receiver != null) return

        receiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                val action = intent?.action ?: return
                events.success(
                    mapOf(
                        "action" to action,
                        "status" to action.toPrinterStatus(),
                    )
                )
            }
        }

        context.registerReceiver(receiver, printerStatusFilter())
    }

    override fun onCancel(arguments: Any?) {
        receiver?.let {
            try {
                context.unregisterReceiver(it)
            } catch (_: IllegalArgumentException) {
            }
        }
        receiver = null
    }

    fun shutdown() {
        onCancel(null)
    }

    private fun printerStatusFilter(): IntentFilter {
        return IntentFilter().apply {
            addAction(PRINTER_NORMAL_ACTION)
            addAction(PRINTER_PAPERLESS_ACTION)
            addAction(PRINTER_PAPEREXISTS_ACTION)
            addAction(PRINTER_THP_HIGHTEMP_ACTION)
            addAction(PRINTER_THP_NORMALTEMP_ACTION)
            addAction(PRINTER_MOTOR_HIGHTEMP_ACTION)
            addAction(PRINTER_BUSY_ACTION)
            addAction(PRINTER_CURRENT_TASK_PRINT_COMPLETE_ACTION)
        }
    }

    private fun String.toPrinterStatus(): Int? {
        return when (this) {
            PRINTER_NORMAL_ACTION,
            PRINTER_PAPEREXISTS_ACTION,
            PRINTER_CURRENT_TASK_PRINT_COMPLETE_ACTION,
            -> 0
            PRINTER_PAPERLESS_ACTION -> 1
            PRINTER_THP_HIGHTEMP_ACTION -> 2
            PRINTER_MOTOR_HIGHTEMP_ACTION -> 3
            PRINTER_BUSY_ACTION -> 4
            else -> null
        }
    }

    companion object {
        private const val PRINTER_NORMAL_ACTION = "com.iposprinter.iposprinterservice.NORMAL_ACTION"
        private const val PRINTER_PAPERLESS_ACTION = "com.iposprinter.iposprinterservice.PAPERLESS_ACTION"
        private const val PRINTER_PAPEREXISTS_ACTION = "com.iposprinter.iposprinterservice.PAPEREXISTS_ACTION"
        private const val PRINTER_THP_HIGHTEMP_ACTION = "com.iposprinter.iposprinterservice.THP_HIGHTEMP_ACTION"
        private const val PRINTER_THP_NORMALTEMP_ACTION = "com.iposprinter.iposprinterservice.THP_NORMALTEMP_ACTION"
        private const val PRINTER_MOTOR_HIGHTEMP_ACTION = "com.iposprinter.iposprinterservice.MOTOR_HIGHTEMP_ACTION"
        private const val PRINTER_BUSY_ACTION = "com.iposprinter.iposprinterservice.BUSY_ACTION"
        private const val PRINTER_CURRENT_TASK_PRINT_COMPLETE_ACTION =
            "com.iposprinter.iposprinterservice.CURRENT_TASK_PRINT_COMPLETE_ACTION"
    }
}
