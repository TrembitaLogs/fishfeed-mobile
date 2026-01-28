import Flutter
import UIKit
// import FirebaseCore  // Disabled for Personal Team testing (no valid GoogleService-Info.plist)
// import FirebaseMessaging  // Disabled for Personal Team testing
// import UserNotifications  // Disabled for Personal Team testing
import workmanager_apple

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Firebase disabled for Personal Team testing (no valid GoogleService-Info.plist)
    // FirebaseApp.configure()

    // Push notifications disabled for Personal Team testing
    // UNUserNotificationCenter.current().delegate = self
    // Messaging.messaging().delegate = self
    // application.registerForRemoteNotifications()

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

  // MARK: - Push notifications disabled for Personal Team testing
  // APNs Token Handling, Remote Notification Handling, and MessagingDelegate
  // are commented out because they require paid Apple Developer account
}
