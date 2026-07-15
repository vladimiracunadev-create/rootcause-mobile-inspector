package com.rootcause.mobileinspector

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Actividad principal: registra el canal `rootcause/collectors` que el
 * núcleo Dart consume. La captura corre fuera del hilo de UI.
 */
class MainActivity : FlutterActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "rootcause/collectors",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "collect" -> {
                    Thread {
                        val payload = try {
                            AndroidCollectors(applicationContext).collect()
                        } catch (_: Exception) {
                            // El Dart degrada un mapa vacío a snapshot neutro.
                            emptyMap<String, Any?>()
                        }
                        runOnUiThread { result.success(payload) }
                    }.start()
                }
                "documentsPath" -> result.success(filesDir.absolutePath)
                else -> result.notImplemented()
            }
        }
    }
}
