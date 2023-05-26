import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController

    //用于获取系统代理配置的MethodChannel
    let methodChannel = FlutterMethodChannel(name: METHOD_CHANNEL, binaryMessenger: controller.binaryMessenger)
    methodChannel.setMethodCallHandler({
      [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      let proxySettings = CFNetworkCopySystemProxySettings()?.takeUnretainedValue()
      let dict = proxySettings?[kCFNetworkProxiesHTTPSEnable as String.lowercased() as CFString] as? NSDictionary
      let host = dict?[kCFNetworkProxiesHTTPProxy as String.lowercased() as CFString] as? String ?? ""
      let port = dict?[kCFNetworkProxiesHTTPPort as String.lowercased() as CFString] as? Int ?? 0
      let proxyConfig = "\(host):\(port)"
      result(proxyConfig)
    })

    //用于设置屏幕常亮的MethodChannel
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

    //用于监听音量键的MethodChannel
    volumeChannel = FlutterEventChannel(name: "com.kokoiro.xyz.pica_comic/volume", binaryMessenger: controller.binaryMessenger)
    volumeChannel?.setStreamHandler(VolumeStreamHandler())

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