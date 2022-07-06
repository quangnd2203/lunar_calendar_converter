import Flutter
import UIKit

public class SwiftLunaCalendarConverterPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "luna_calendar_converter", binaryMessenger: registrar.messenger())
    let instance = SwiftLunaCalendarConverterPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    result("iOS " + UIDevice.current.systemVersion)
  }
}
