import UIKit
import Flutter
import flutter_local_notifications

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller: FlutterViewController = window?.rootViewController as! FlutterViewController

    FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { (registry) in
      GeneratedPluginRegistrant.register(with: registry)
    }

    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
    }

    // 用于获取系统代理配置的 MethodChannel
    let methodChannel = FlutterMethodChannel(name: "kokoiro.xyz.pica_comic/proxy", binaryMessenger: controller.binaryMessenger)
    methodChannel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
        if let proxySettings = CFNetworkCopySystemProxySettings()?.takeUnretainedValue() as NSDictionary?,
           let dict = proxySettings.object(forKey: kCFNetworkProxiesHTTPProxy) as? NSDictionary,
           let host = dict.object(forKey: kCFNetworkProxiesHTTPProxy) as? String,
           let port = dict.object(forKey: kCFNetworkProxiesHTTPPort) as? Int {
            let proxyConfig = "\(host):\(port)"
            result(proxyConfig)
        } else {
            result("")
        }
    }

    // 用于设置屏幕常亮的 MethodChannel
    let channel2 = FlutterMethodChannel(name: "com.kokoiro.xyz.pica_comic/keepScreenOn", binaryMessenger: controller.binaryMessenger)
    channel2.setMethodCallHandler { (call: FlutterMethodCall, result: FlutterResult) in
      if call.method == "set" {
        let screenOn = true // 设置屏幕常亮
        UIApplication.shared.isIdleTimerDisabled = screenOn
      } else {
        let screenOn = false // 设置屏幕不常亮
        UIApplication.shared.isIdleTimerDisabled = screenOn
      }
      result(nil)
    }

    // 用于监听音量键的 MethodChannel
    let volumeChannel = FlutterEventChannel(name: "com.kokoiro.xyz.pica_comic/volume", binaryMessenger: controller.binaryMessenger)
    volumeChannel.setStreamHandler(VolumeStreamHandler())

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

class VolumeStreamHandler: NSObject, FlutterStreamHandler {
  private var eventSink: FlutterEventSink?

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    eventSink = events
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
    return nil
  }
}