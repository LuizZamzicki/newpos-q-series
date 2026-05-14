package br.com.sla.newpos_q_series

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.ServiceConnection
import android.content.pm.PackageManager
import android.graphics.BitmapFactory
import android.os.Build
import android.os.IBinder
import android.os.RemoteException
import com.iposprinter.iposprinterservice.IPosPrinterCallback
import com.iposprinter.iposprinterservice.IPosPrinterService
import java.util.concurrent.CountDownLatch
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit

class NewposQPrinter(private val context: Context) {
    private val executor: ExecutorService = Executors.newSingleThreadExecutor()
    private var service: IPosPrinterService? = null
    private var bindLatch: CountDownLatch? = null
    private val bindAttempts = mutableListOf<Map<String, Any?>>()

    private val connection = object : ServiceConnection {
        override fun onServiceConnected(name: ComponentName?, binder: IBinder?) {
            service = IPosPrinterService.Stub.asInterface(binder)
            bindLatch?.countDown()
        }

        override fun onServiceDisconnected(name: ComponentName?) {
            service = null
        }
    }

    fun bind(timeoutMs: Long = DEFAULT_TIMEOUT_MS): Boolean {
        if (service != null) return true

        bindAttempts.clear()
        for (intent in serviceIntents()) {
            if (tryBind(intent, timeoutMs)) {
                return true
            }
        }

        return false
    }

    private fun tryBind(intent: Intent, timeoutMs: Long): Boolean {
        val latch = CountDownLatch(1)
        bindLatch = latch
        var error: String? = null

        val started = try {
            context.bindService(intent, connection, Context.BIND_AUTO_CREATE)
        } catch (exception: SecurityException) {
            error = exception.message ?: exception.javaClass.simpleName
            false
        } catch (exception: IllegalArgumentException) {
            error = exception.message ?: exception.javaClass.simpleName
            false
        }

        if (!started) {
            bindLatch = null
            bindAttempts.add(
                bindAttempt(
                    intent,
                    started = false,
                    connected = false,
                    error = error,
                )
            )
            return false
        }

        val connected = latch.await(timeoutMs, TimeUnit.MILLISECONDS)
        bindLatch = null
        bindAttempts.add(
            bindAttempt(
                intent,
                started = true,
                connected = connected && service != null,
                error = error,
            )
        )
        return connected && service != null
    }

    private fun serviceIntents(): List<Intent> {
        val packageManager = context.packageManager
        val actionIntent = printerActionIntent()
        val resolvedIntents = packageManager.queryIntentServicesCompat(actionIntent)
            .mapNotNull { serviceName ->
                val parts = serviceName.split("/", limit = 2)
                if (parts.size != 2) return@mapNotNull null
                Intent().apply {
                    component = ComponentName(parts[0], parts[1])
                    action = PRINTER_SERVICE_ACTION
                    addCategory(Intent.CATEGORY_DEFAULT)
                }
            }

        return (resolvedIntents + listOf(
            Intent().apply {
                component = ComponentName(PRINTER_SERVICE_PACKAGE, PRINTER_SERVICE_CLASS)
                action = PRINTER_SERVICE_ACTION
                addCategory(Intent.CATEGORY_DEFAULT)
            },
            actionIntent,
        )).distinctBy { "${it.component?.flattenToString()}|${it.`package`}|${it.action}|${it.categories}" }
    }

    private fun printerActionIntent() = Intent().apply {
        setPackage(PRINTER_SERVICE_PACKAGE)
        action = PRINTER_SERVICE_ACTION
        addCategory(Intent.CATEGORY_DEFAULT)
    }

    private fun bindAttempt(
        intent: Intent,
        started: Boolean,
        connected: Boolean,
        error: String?,
    ): Map<String, Any?> {
        return mapOf(
            "component" to intent.component?.flattenToString(),
            "package" to intent.`package`,
            "action" to intent.action,
            "categories" to intent.categories?.toList(),
            "started" to started,
            "connected" to connected,
            "error" to error,
        )
    }

    fun unbind() {
        try {
            if (service != null) {
                context.unbindService(connection)
            }
        } catch (_: IllegalArgumentException) {
        } finally {
            service = null
            bindLatch = null
        }
    }

    fun isBound(): Boolean = service != null

    fun getStatus(): Int {
        val printer = requireService()
        return printer.getPrinterStatus()
    }

    fun diagnostics(): Map<String, Any?> {
        val packageManager = context.packageManager
        val packageInstalled = try {
            packageManager.getPackageInfo(PRINTER_SERVICE_PACKAGE, 0)
            true
        } catch (_: PackageManager.NameNotFoundException) {
            false
        }

        val actionIntent = printerActionIntent()
        val componentIntent = Intent().apply {
            component = ComponentName(PRINTER_SERVICE_PACKAGE, PRINTER_SERVICE_CLASS)
            action = PRINTER_SERVICE_ACTION
            addCategory(Intent.CATEGORY_DEFAULT)
        }

        return mapOf(
            "servicePackage" to PRINTER_SERVICE_PACKAGE,
            "serviceAction" to PRINTER_SERVICE_ACTION,
            "serviceClass" to PRINTER_SERVICE_CLASS,
            "packageInstalled" to packageInstalled,
            "actionServices" to packageManager.queryIntentServicesCompat(actionIntent),
            "componentServices" to packageManager.queryIntentServicesCompat(componentIntent),
            "bindAttempts" to bindAttempts.toList(),
            "bound" to isBound(),
        )
    }

    fun execute(operations: List<Map<String, Any?>>, timeoutMs: Long): List<Boolean> {
        val task = executor.submit<List<Boolean>> {
            val printer = ensureBoundService(timeoutMs)
            val callback = logOnlyCallback()
            operations.map { executeOperation(printer, it, callback) }
        }
        return task.get(timeoutMs * operations.size.coerceAtLeast(1), TimeUnit.MILLISECONDS)
    }

    private fun ensureBoundService(timeoutMs: Long): IPosPrinterService {
        if (!bind(timeoutMs)) {
            throw IllegalStateException("Printer service is not available")
        }
        return requireService()
    }

    private fun requireService(): IPosPrinterService {
        return service ?: throw IllegalStateException("Printer service is not bound")
    }

    private fun executeOperation(
        printer: IPosPrinterService,
        operation: Map<String, Any?>,
        callback: IPosPrinterCallback,
    ): Boolean {
        val type = operation["type"] as? String
            ?: throw IllegalArgumentException("Missing operation type")

        try {
            when (type) {
                "init" -> printer.printerInit(callback)
                "setDepth" -> printer.setPrinterPrintDepth(operation.int("depth", 6), callback)
                "setFontSize" -> printer.setPrinterPrintFontSize(operation.int("fontSize", 24), callback)
                "setAlignment" -> printer.setPrinterPrintAlignment(operation.int("alignment", 0), callback)
                "feedLines" -> printer.printerFeedLines(operation.int("lines", 160), callback)
                "blankLines" -> printer.printBlankLines(
                    operation.int("lines", 1),
                    operation.int("height", 24),
                    callback,
                )
                "text" -> printer.printText(operation.string("text"), callback)
                "formattedText" -> printer.PrintSpecFormatText(
                    operation.string("text"),
                    operation.string("typeface", "ST"),
                    operation.int("fontSize", 24),
                    operation.int("alignment", 0),
                    callback,
                )
                "columnsText" -> printer.printColumnsText(
                    operation.stringList("columns").toTypedArray(),
                    operation.intList("widths").toIntArray(),
                    operation.intList("alignments").toIntArray(),
                    operation.int("continuous", 0),
                    callback,
                )
                "bitmap" -> printer.printBitmap(
                    operation.int("alignment", 1),
                    operation.int("size", 10),
                    decodeBitmap(operation.bytes("bytes")),
                    callback,
                )
                "barcode" -> printer.printBarCode(
                    operation.string("data"),
                    operation.int("symbology", 8),
                    operation.int("height", 6),
                    operation.int("width", 12),
                    operation.int("textPosition", 2),
                    callback,
                )
                "qrcode" -> printer.printQRCode(
                    operation.string("data"),
                    operation.int("moduleSize", 10),
                    operation.int("errorCorrectionLevel", 1),
                    callback,
                )
                "rawData" -> printer.printRawData(operation.bytes("bytes"), callback)
                "escPos" -> printer.sendUserCMDData(operation.bytes("bytes"), callback)
                "performPrint" -> printer.printerPerformPrint(operation.int("feedLines", 160), callback)
                else -> throw IllegalArgumentException("Unsupported operation type: $type")
            }
            return true
        } catch (e: RemoteException) {
            throw IllegalStateException("Printer service call failed", e)
        }
    }

    private fun logOnlyCallback(): IPosPrinterCallback {
        return object : IPosPrinterCallback.Stub() {
            override fun onRunResult(isSuccess: Boolean) {
            }

            override fun onReturnString(result: String?) {
            }
        }
    }

    private fun decodeBitmap(bytes: ByteArray) =
        BitmapFactory.decodeByteArray(bytes, 0, bytes.size)
            ?: throw IllegalArgumentException("Invalid bitmap bytes")

    fun shutdown() {
        unbind()
        executor.shutdownNow()
    }

    companion object {
        private const val PRINTER_SERVICE_PACKAGE = "com.iposprinter.iposprinterservice"
        private const val PRINTER_SERVICE_ACTION = "com.iposprinter.iposprinterservice.IPosPrintService"
        private const val PRINTER_SERVICE_CLASS = "com.iposprinter.iposprinterservice.IPosPrintService"
        private const val DEFAULT_TIMEOUT_MS = 10_000L
    }
}

private fun PackageManager.queryIntentServicesCompat(intent: Intent): List<String> {
    val services = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
        queryIntentServices(intent, PackageManager.ResolveInfoFlags.of(0))
    } else {
        @Suppress("DEPRECATION")
        queryIntentServices(intent, 0)
    }

    return services.mapNotNull { info ->
        info.serviceInfo?.let { "${it.packageName}/${it.name}" }
    }
}

private fun Map<String, Any?>.int(key: String, default: Int? = null): Int {
    val value = this[key] ?: return default
        ?: throw IllegalArgumentException("Missing int argument: $key")
    return when (value) {
        is Int -> value
        is Long -> value.toInt()
        is Number -> value.toInt()
        else -> throw IllegalArgumentException("Invalid int argument: $key")
    }
}

private fun Map<String, Any?>.string(key: String, default: String? = null): String {
    return this[key] as? String ?: default
        ?: throw IllegalArgumentException("Missing string argument: $key")
}

@Suppress("UNCHECKED_CAST")
private fun Map<String, Any?>.stringList(key: String): List<String> {
    return this[key] as? List<String>
        ?: (this[key] as? List<*>)?.map { it.toString() }
        ?: throw IllegalArgumentException("Missing string list argument: $key")
}

private fun Map<String, Any?>.intList(key: String): List<Int> {
    val value = this[key] as? List<*>
        ?: throw IllegalArgumentException("Missing int list argument: $key")
    return value.map {
        when (it) {
            is Int -> it
            is Long -> it.toInt()
            is Number -> it.toInt()
            else -> throw IllegalArgumentException("Invalid int list argument: $key")
        }
    }
}

private fun Map<String, Any?>.bytes(key: String): ByteArray {
    val value = this[key] ?: throw IllegalArgumentException("Missing byte array argument: $key")
    return when (value) {
        is ByteArray -> value
        is List<*> -> ByteArray(value.size) { index ->
            val item = value[index]
            when (item) {
                is Int -> item.toByte()
                is Long -> item.toByte()
                is Number -> item.toByte()
                else -> throw IllegalArgumentException("Invalid byte array argument: $key")
            }
        }
        else -> throw IllegalArgumentException("Invalid byte array argument: $key")
    }
}
