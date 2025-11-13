import UIKit
import Flutter

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var voicePlatformPlugin: VoicePlatformPlugin?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    }
    GeneratedPluginRegistrant.register(with: self)

    if let controller = window?.rootViewController as? FlutterViewController {
      voicePlatformPlugin = VoicePlatformPlugin(controller: controller)
      voicePlatformPlugin?.start()
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func applicationDidBecomeActive(_ application: UIApplication) {
    application.applicationIconBadgeNumber = 0;
  }

  override func applicationWillTerminate(_ application: UIApplication) {
    voicePlatformPlugin?.stop()
    voicePlatformPlugin = nil
    super.applicationWillTerminate(application)
  }
}

