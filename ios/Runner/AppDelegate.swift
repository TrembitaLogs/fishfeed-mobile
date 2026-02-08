import Flutter
import UIKit
import FirebaseCore
import FirebaseMessaging
import UserNotifications
import workmanager_apple

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    FirebaseApp.configure()

    UNUserNotificationCenter.current().delegate = self
    Messaging.messaging().delegate = self
    application.registerForRemoteNotifications()

    // Register Workmanager background tasks
    // Periodic task for background sync (frequency in seconds, 15 minutes = 900 seconds)
    WorkmanagerPlugin.registerPeriodicTask(
      withIdentifier: "com.fishfeed.app.backgroundSync",
      frequency: NSNumber(value: 15 * 60)
    )

    // Set minimum background fetch interval (15 minutes)
    UIApplication.shared.setMinimumBackgroundFetchInterval(TimeInterval(15 * 60))

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

// MARK: - MessagingDelegate

extension AppDelegate: MessagingDelegate {
  func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
    // Token is handled by firebase_messaging Flutter plugin via method channel
  }
}
