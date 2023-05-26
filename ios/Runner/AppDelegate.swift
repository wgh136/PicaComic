import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let channel = FlutterMethodChannel(name: "kokoiro.xyz.pica_comic/proxy",
                                                binaryMessenger: controller.binaryMessenger)
    channel.setMethodCallHandler({
    (call: FlutterMethodCall, result: FlutterResult) -> Void in
        result("No Proxy")
    })
    FlutterMethodChannel(name: "com.kokoiro.xyz.pica_comic/keepScreenOn",
                                                    binaryMessenger: controller.binaryMessenger).setMethodCallHandler({
       (call: FlutterMethodCall, result: FlutterResult) -> Void in
          if call.method == "set"{
            UIApplication.shared.isIdleTimerDisabled = true
          }else{
            UIApplication.shared.isIdleTimerDisabled = false
          }
       })
    })
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
