package com.rootcause.mobileinspector

import android.content.Context
import android.os.Handler
import android.os.Looper
import androidx.work.Constraints
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.Worker
import androidx.work.WorkerParameters
import androidx.work.WorkManager
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit

/**
 * Programación de la captura periódica en segundo plano. WorkManager
 * impone un mínimo de 15 minutos entre ejecuciones — se documenta tal
 * cual, no se promete lo que el SO no permite. Con `chargingOnly` el
 * monitoreo continuo queda restringido al teléfono enchufado.
 */
object BackgroundCapture {

    private const val WORK_NAME = "rootcause-background-capture"

    fun configure(context: Context, enabled: Boolean, chargingOnly: Boolean) {
        val workManager = WorkManager.getInstance(context)
        if (!enabled) {
            workManager.cancelUniqueWork(WORK_NAME)
            return
        }
        val constraints = Constraints.Builder()
            .setRequiresCharging(chargingOnly)
            .build()
        val request = PeriodicWorkRequestBuilder<BackgroundCaptureWorker>(
            15,
            TimeUnit.MINUTES,
        ).setConstraints(constraints).build()
        workManager.enqueueUniquePeriodicWork(
            WORK_NAME,
            ExistingPeriodicWorkPolicy.UPDATE,
            request,
        )
    }
}

/**
 * Ejecuta la captura levantando un engine Flutter sin UI que corre el
 * entrypoint Dart `backgroundCapture` de lib/main.dart: el MISMO núcleo
 * (colectores, umbrales configurados, motor de reglas, historial) que la
 * app abierta. Cero lógica duplicada que pueda divergir en silencio.
 */
class BackgroundCaptureWorker(
    context: Context,
    params: WorkerParameters,
) : Worker(context, params) {

    override fun doWork(): Result {
        val latch = CountDownLatch(1)
        val mainHandler = Handler(Looper.getMainLooper())
        var engine: FlutterEngine? = null

        mainHandler.post {
            try {
                val loader = FlutterInjector.instance().flutterLoader()
                if (!loader.initialized()) {
                    loader.startInitialization(applicationContext)
                    loader.ensureInitializationComplete(applicationContext, null)
                }
                val headless = FlutterEngine(applicationContext)
                engine = headless
                CollectorsChannel.register(
                    headless.dartExecutor.binaryMessenger,
                    applicationContext,
                )
                MethodChannel(
                    headless.dartExecutor.binaryMessenger,
                    "rootcause/background",
                ).setMethodCallHandler { call, result ->
                    if (call.method == "done") {
                        result.success(null)
                        latch.countDown()
                    } else {
                        result.notImplemented()
                    }
                }
                headless.dartExecutor.executeDartEntrypoint(
                    DartExecutor.DartEntrypoint(
                        loader.findAppBundlePath(),
                        "backgroundCapture",
                    ),
                )
            } catch (_: Exception) {
                latch.countDown()
            }
        }

        val completed = latch.await(90, TimeUnit.SECONDS)
        mainHandler.post {
            try {
                engine?.destroy()
            } catch (_: Exception) {
                // Un engine ya muerto no debe tumbar el Worker.
            }
        }
        return if (completed) Result.success() else Result.retry()
    }
}
