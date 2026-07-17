import Flutter
import UIKit

/// Registra el canal `rootcause/collectors` que el núcleo Dart consume.
/// iOS expone menos que Android; lo que no existe se declara honestamente
/// (`appsAuditSupported=false`, `temperatureAvailable=false`).
///
/// Los colectores viven en este mismo archivo (enum `IosCollectors`) para
/// no requerir cambios manuales en project.pbxproj.
@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let channel = FlutterMethodChannel(
      name: "rootcause/collectors",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "collect":
        DispatchQueue.global(qos: .userInitiated).async {
          let payload = IosCollectors.collect()
          DispatchQueue.main.async { result(payload) }
        }
      case "documentsPath":
        let docs = FileManager.default.urls(
          for: .documentDirectory, in: .userDomainMask
        ).first?.path
        result(docs)
      case "openSystemScreen":
        // iOS solo permite abrir los ajustes de la PROPIA app; cualquier
        // otra pantalla se declara no disponible en vez de fingirse.
        if let url = URL(string: UIApplication.openSettingsURLString),
          UIApplication.shared.canOpenURL(url)
        {
          UIApplication.shared.open(url)
          result(true)
        } else {
          result(false)
        }
      case "clearOwnCache":
        DispatchQueue.global(qos: .utility).async {
          let freed = IosCollectors.clearOwnCache()
          DispatchQueue.main.async { result(freed) }
        }
      case "requestBlePermissions", "configureBackgroundCapture",
        "requestNotificationPermissions", "notifyCritical":
        // Escaneo BLE, captura en segundo plano y notificaciones locales:
        // fuera del alcance iOS actual (distribución en pausa). Se
        // declara, no se simula.
        result(false)
      case "bleScan":
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}

/// Colectores nativos iOS — solo APIs públicas. Devuelve el mapa del
/// contrato `rootcause/collectors` (docs/ARCHITECTURE.md). Los campos que
/// iOS no permite observar se entregan con su flag de no-disponible en vez
/// de valores inventados.
enum IosCollectors {

  static func collect() -> [String: Any?] {
    return [
      "memory": memory(),
      "storage": storage(),
      "battery": battery(),
      "network": network(),
      // iOS no permite listar apps instaladas: lista vacía +
      // appsAuditSupported=false para que la UI lo explique.
      "apps": [],
      "device": device(),
    ]
  }

  private static func memory() -> [String: Any?] {
    let total = Int64(ProcessInfo.processInfo.physicalMemory)
    let available = Int64(os_proc_available_memory())
    return [
      "totalBytes": total,
      "availableBytes": available,
      "lowMemory": false,
    ]
  }

  private static func storage() -> [String: Any?] {
    var total: Int64 = 0
    var free: Int64 = 0
    if let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
      if let values = try? url.resourceValues(forKeys: [
        .volumeTotalCapacityKey, .volumeAvailableCapacityForImportantUsageKey,
      ]) {
        total = Int64(values.volumeTotalCapacity ?? 0)
        free = values.volumeAvailableCapacityForImportantUsage ?? 0
      }
    }
    return [
      "totalBytes": total,
      "freeBytes": free,
      "appCacheBytes": cacheSize(),
    ]
  }

  /// Borra la caché propia (directorio Caches del sandbox) y devuelve los
  /// bytes liberados.
  static func clearOwnCache() -> Int64 {
    let before = cacheSize()
    guard let cacheUrl = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
    else { return 0 }
    if let children = try? FileManager.default.contentsOfDirectory(
      at: cacheUrl, includingPropertiesForKeys: nil
    ) {
      for child in children {
        try? FileManager.default.removeItem(at: child)
      }
    }
    return max(0, before - cacheSize())
  }

  private static func cacheSize() -> Int64 {
    guard let cacheUrl = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
    else { return 0 }
    var totalSize: Int64 = 0
    if let enumerator = FileManager.default.enumerator(
      at: cacheUrl,
      includingPropertiesForKeys: [.fileSizeKey],
      options: [],
      errorHandler: nil
    ) {
      for case let fileUrl as URL in enumerator {
        if let size = try? fileUrl.resourceValues(forKeys: [.fileSizeKey]).fileSize {
          totalSize += Int64(size)
        }
      }
    }
    return totalSize
  }

  private static func battery() -> [String: Any?] {
    UIDevice.current.isBatteryMonitoringEnabled = true
    let level = UIDevice.current.batteryLevel
    let state = UIDevice.current.batteryState
    let charging = state == .charging || state == .full
    return [
      "levelPercent": level < 0 ? -1 : Int(level * 100),
      "charging": charging,
      // iOS no expone temperatura ni salud de batería a apps de usuario.
      "temperatureCelsius": 0.0,
      "temperatureAvailable": false,
      "voltageMillivolts": 0,
      "healthy": true,
      "healthLabel": "unknown",
    ]
  }

  private static func network() -> [String: Any?] {
    // Captura puntual y síncrona: se reporta lo mínimo verificable sin
    // monitores asíncronos. Ampliación prevista en el roadmap.
    return [
      "connected": true,
      "transport": "unknown",
      "vpnActive": vpnActive(),
      "metered": false,
      "downstreamKbps": 0,
      "upstreamKbps": 0,
      "totalRxBytes": 0,
      "totalTxBytes": 0,
    ]
  }

  private static func vpnActive() -> Bool {
    guard
      let settings = CFNetworkCopySystemProxySettings()?.takeRetainedValue() as? [String: Any],
      let scoped = settings["__SCOPED__"] as? [String: Any]
    else { return false }
    let vpnInterfaces = ["tap", "tun", "ppp", "ipsec", "utun"]
    return scoped.keys.contains { key in
      vpnInterfaces.contains { key.lowercased().hasPrefix($0) }
    }
  }

  private static func device() -> [String: Any?] {
    return [
      "manufacturer": "Apple",
      "model": deviceModelIdentifier(),
      "osVersion": UIDevice.current.systemVersion,
      "sdkInt": 0,
      "securityPatch": "iOS \(UIDevice.current.systemVersion)",
      "cpuCores": ProcessInfo.processInfo.activeProcessorCount,
      "uptimeMillis": Int64(ProcessInfo.processInfo.systemUptime * 1000),
      "rootIndicators": jailbreakIndicators(),
      "appsAuditSupported": false,
    ]
  }

  private static func deviceModelIdentifier() -> String {
    var systemInfo = utsname()
    uname(&systemInfo)
    let mirror = Mirror(reflecting: systemInfo.machine)
    let identifier = mirror.children.reduce(into: "") { result, element in
      guard let value = element.value as? Int8, value != 0 else { return }
      result.append(String(UnicodeScalar(UInt8(value))))
    }
    return identifier.isEmpty ? UIDevice.current.model : identifier
  }

  /// Indicadores honestos de jailbreak: rutas conocidas y escritura fuera
  /// del sandbox. Es un INDICIO, no una prueba.
  private static func jailbreakIndicators() -> [String] {
    var indicators: [String] = []
    let paths = [
      "/Applications/Cydia.app",
      "/Applications/Sileo.app",
      "/Library/MobileSubstrate/MobileSubstrate.dylib",
      "/bin/bash",
      "/usr/sbin/sshd",
      "/etc/apt",
      "/private/var/lib/apt",
    ]
    for path in paths where FileManager.default.fileExists(atPath: path) {
      indicators.append(path)
    }
    let probe = "/private/rootcause-jb-probe-\(UUID().uuidString).txt"
    if FileManager.default.createFile(atPath: probe, contents: Data()) {
      indicators.append("write-outside-sandbox")
      try? FileManager.default.removeItem(atPath: probe)
    }
    return indicators
  }
}
