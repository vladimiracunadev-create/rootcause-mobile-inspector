# Reglas R8 del proyecto.
#
# BackgroundCaptureWorker se instancia por nombre de clase (reflexión de
# WorkManager) y RootCauseApplication por el manifest. La app propia es
# diminuta: mantenerla íntegra cuesta KB y elimina de raíz cualquier
# riesgo de strip/rename agresivo en release — el crash de arranque solo
# en release es exactamente la clase de fallo que esto previene.
-keep class com.rootcause.mobileinspector.** { *; }

# CAUSA RAÍZ del crash de arranque de v0.2.0 (verificada con el stack
# trace real): R8 eliminaba el constructor sin argumentos de
# androidx.work.impl.WorkDatabase_Impl, que WorkManager instancia por
# reflexión (NoSuchMethodException → proceso muerto al primer arranque).
# Se conservan los constructores de las bases Room y el impl de
# WorkManager completos.
-keep class * extends androidx.room.RoomDatabase { <init>(); }
-keep class androidx.work.impl.** { *; }
