import Flutter
import UIKit
import CallKit

@main
@objc class AppDelegate: FlutterAppDelegate {

  private static let appGroupID     = "group.com.sentri.app"
  private static let blockedKey     = "sentri_blocked_numbers"
  private static let callerIdKey    = "sentri_caller_ids"
  private static let channelName    = "com.sentri.sentri/calldirectory"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: Self.channelName,
        binaryMessenger: controller.binaryMessenger
      )
      channel.setMethodCallHandler { [weak self] call, result in
        self?.handleMethodCall(call, result: result)
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func handleMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {

    case "syncBlocklist":
      guard let args = call.arguments as? [String: Any] else {
        result(FlutterError(code: "BAD_ARGS", message: "Expected map argument", details: nil))
        return
      }
      let blocked   = args["blocked"]   as? [String]        ?? []
      let callerIds = args["callerIds"] as? [[String: Any]] ?? []
      writeToAppGroup(blocked: blocked, callerIds: callerIds)
      reloadCallDirectory(result: result)

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func writeToAppGroup(blocked: [String], callerIds: [[String: Any]]) {
    let suite = UserDefaults(suiteName: Self.appGroupID)
    suite?.set(blocked,   forKey: Self.blockedKey)
    suite?.set(callerIds, forKey: Self.callerIdKey)
    suite?.synchronize()
  }

  private func reloadCallDirectory(result: @escaping FlutterResult) {
    CXCallDirectoryManager.sharedInstance.reloadExtension(
      withIdentifier: "com.sentri.app.SentriCallDirectory"
    ) { error in
      if let error = error {
        result(FlutterError(code: "RELOAD_FAILED", message: error.localizedDescription, details: nil))
      } else {
        result(nil)
      }
    }
  }
}
