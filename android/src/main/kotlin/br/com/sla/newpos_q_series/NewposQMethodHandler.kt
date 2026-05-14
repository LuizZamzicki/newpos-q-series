package br.com.sla.newpos_q_series

import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

class NewposQMethodHandler(private val printer: NewposQPrinter) : MethodChannel.MethodCallHandler {
    private val executor: ExecutorService = Executors.newCachedThreadPool()
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "getPlatformVersion" -> result.success("Android ${android.os.Build.VERSION.RELEASE}")
                "bind" -> runAsync(result) {
                    printer.bind(call.longArg("timeoutMs", 10_000L))
                }
                "unbind" -> {
                    printer.unbind()
                    result.success(null)
                }
                "isBound" -> result.success(printer.isBound())
                "diagnostics" -> result.success(printer.diagnostics())
                "getPrinterStatus" -> runAsync(result) {
                    printer.getStatus()
                }
                "execute" -> runAsync(result) {
                    val operations = call.operations()
                    val timeoutMs = call.longArg("timeoutMs", 10_000L)
                    printer.execute(operations, timeoutMs)
                }
                else -> result.notImplemented()
            }
        } catch (e: IllegalArgumentException) {
            result.error("INVALID_ARGUMENT", e.message, null)
        } catch (e: IllegalStateException) {
            result.error("PRINTER_ERROR", e.message, e.cause?.message)
        } catch (e: Exception) {
            result.error("UNEXPECTED_ERROR", e.message, null)
        }
    }

    fun shutdown() {
        executor.shutdownNow()
    }

    private fun runAsync(
        result: MethodChannel.Result,
        action: () -> Any?,
    ) {
        executor.execute {
            try {
                val value = action()
                mainHandler.post {
                    result.success(value)
                }
            } catch (e: IllegalArgumentException) {
                mainHandler.post {
                    result.error("INVALID_ARGUMENT", e.message, null)
                }
            } catch (e: IllegalStateException) {
                mainHandler.post {
                    result.error("PRINTER_ERROR", e.message, e.cause?.message)
                }
            } catch (e: Exception) {
                mainHandler.post {
                    result.error("UNEXPECTED_ERROR", e.message, null)
                }
            }
        }
    }
}

private fun MethodCall.longArg(key: String, default: Long): Long {
    val value = argument<Any>(key) ?: return default
    return when (value) {
        is Int -> value.toLong()
        is Long -> value
        is Number -> value.toLong()
        else -> default
    }
}

@Suppress("UNCHECKED_CAST")
private fun MethodCall.operations(): List<Map<String, Any?>> {
    return argument<List<Map<String, Any?>>>("operations")
        ?: throw IllegalArgumentException("Missing operations")
}
