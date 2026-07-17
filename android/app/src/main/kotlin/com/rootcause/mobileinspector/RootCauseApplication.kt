package com.rootcause.mobileinspector

import android.app.Application
import androidx.work.Configuration

/**
 * Application propia con inicialización BAJO DEMANDA de WorkManager.
 *
 * El inicializador automático (androidx.startup) se elimina del manifest:
 * en el primer arranque el proceso no ejecuta NADA de WorkManager — menos
 * trabajo y menos superficie de fallo justo donde un crash es más grave.
 * WorkManager solo se inicializa cuando el usuario activa la captura en
 * segundo plano (o cuando el sistema relanza un Worker ya programado).
 */
class RootCauseApplication : Application(), Configuration.Provider {

    override val workManagerConfiguration: Configuration
        get() = Configuration.Builder().build()
}
