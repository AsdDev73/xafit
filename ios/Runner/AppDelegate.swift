import Flutter
import UIKit
import UserNotifications
import flutter_local_notifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    // Asignamos el delegate de notificaciones a esta clase (AppDelegate).
    // Esto es necesario para que flutter_local_notifications pueda
    // mostrar notificaciones cuando la app está en primer plano (foreground).
    UNUserNotificationCenter.current().delegate = self

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // Este método es necesario para registrar los plugins de Flutter
  // cuando el motor se inicializa de forma implícita (sin un FlutterViewController explícito).
  // flutter_local_notifications lo requiere para funcionar correctamente en iOS.
  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {

    // Registramos el callback que conecta flutter_local_notifications
    // con el sistema de plugins de Flutter.
    FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { registry in
      GeneratedPluginRegistrant.register(with: registry)
    }

    // Registramos todos los plugins generados automáticamente por Flutter
    // (incluidos file_picker, share_plus, flutter_local_notifications, etc.)
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}