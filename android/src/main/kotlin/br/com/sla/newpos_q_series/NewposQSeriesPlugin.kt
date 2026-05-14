package br.com.sla.newpos_q_series

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.EventChannel

/** NewposQSeriesPlugin */
class NewposQSeriesPlugin :
    FlutterPlugin,
    MethodCallHandler {
    // The MethodChannel that will the communication between Flutter and native Android
    //
    // This local reference serves to register the plugin with the Flutter Engine and unregister it
    // when the Flutter Engine is detached from the Activity
    private lateinit var channel: MethodChannel
    private var eventChannel: EventChannel? = null
    private var printer: NewposQPrinter? = null
    private var methodHandler: NewposQMethodHandler? = null
    private var statusStreamHandler: NewposQStatusStreamHandler? = null

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        printer = NewposQPrinter(flutterPluginBinding.applicationContext)
        methodHandler = NewposQMethodHandler(printer!!)
        statusStreamHandler = NewposQStatusStreamHandler(flutterPluginBinding.applicationContext)
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "newpos_q_series")
        channel.setMethodCallHandler(methodHandler)
        eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "newpos_q_series/status")
        eventChannel?.setStreamHandler(statusStreamHandler)
    }

    override fun onMethodCall(
        call: MethodCall,
        result: Result
    ) {
        if (call.method == "getPlatformVersion") {
            result.success("Android ${android.os.Build.VERSION.RELEASE}")
        } else {
            result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        eventChannel?.setStreamHandler(null)
        statusStreamHandler?.shutdown()
        methodHandler?.shutdown()
        printer?.shutdown()
        eventChannel = null
        statusStreamHandler = null
        methodHandler = null
        printer = null
    }
}
