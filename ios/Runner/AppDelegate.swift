import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    registerStorageChannel()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // Downloaded recitation can always be fetched again, so it is kept out of
  // iCloud backups as Apple's storage guidelines require.
  private func registerStorageChannel() {
    guard let registrar = self.registrar(forPlugin: "IqraStorage") else { return }
    let channel = FlutterMethodChannel(
      name: "iqra/storage", binaryMessenger: registrar.messenger())
    channel.setMethodCallHandler { call, result in
      guard call.method == "excludeFromBackup", let path = call.arguments as? String else {
        result(FlutterMethodNotImplemented)
        return
      }
      var url = URL(fileURLWithPath: path, isDirectory: true)
      var values = URLResourceValues()
      values.isExcludedFromBackup = true
      do {
        try url.setResourceValues(values)
        result(nil)
      } catch {
        result(FlutterError(code: "exclude_failed", message: error.localizedDescription, details: nil))
      }
    }
  }
}
