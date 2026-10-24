import Flutter
import LocalAuthentication
import UIKit

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
    registerLockChannel(engineBridge.pluginRegistry)
  }

  // Kunci app (99.10s): has a face / fingerprint been enrolled since face id
  // was switched on? iOS only says so through evaluatedPolicyDomainState, which
  // changes when the enrolled set does. local_auth does not expose it.
  private static let domainStateKey = "mibu.biometricDomainState"

  private func registerLockChannel(_ registry: FlutterPluginRegistry) {
    guard let registrar = registry.registrar(forPlugin: "MibuLock") else { return }
    let channel = FlutterMethodChannel(
      name: "com.mibu/lock",
      binaryMessenger: registrar.messenger()
    )
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "snapshot":
        UserDefaults.standard.set(
          AppDelegate.biometricDomainState(),
          forKey: AppDelegate.domainStateKey
        )
        result(nil)
      case "enrollmentChanged":
        guard let saved = UserDefaults.standard.data(forKey: AppDelegate.domainStateKey) else {
          result(false)  // nothing to compare with
          return
        }
        result(AppDelegate.biometricDomainState() != saved)
      case "secure":
        result(nil)  // Android only (FLAG_SECURE); iOS covers the app in Flutter
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private static func biometricDomainState() -> Data? {
    let context = LAContext()
    var error: NSError?
    guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
      return nil
    }
    return context.evaluatedPolicyDomainState
  }
}
