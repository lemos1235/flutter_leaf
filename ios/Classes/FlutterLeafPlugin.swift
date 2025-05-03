import Flutter
import UIKit
import NetworkExtension

public class FlutterLeafPlugin: NSObject, FlutterPlugin {
  private var eventSink: FlutterEventSink?
  private let vpnManager = VPNManager.shared
  
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "flutter_leaf", binaryMessenger: registrar.messenger())
    let eventChannel = FlutterEventChannel(name: "flutter_leaf_states", binaryMessenger: registrar.messenger())
    
    let instance = FlutterLeafPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
    eventChannel.setStreamHandler(instance)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getCurrentState":
      let state = vpnManager.getCurrentState()
      result(state.rawValue)
      
    case "prepare", "prepared":
      // 在iOS上不需要准备，直接返回true
      result(true)
      
    case "disconnect":
      vpnManager.disconnect()
      result(nil)
      
    case "connect":
      guard let args = call.arguments as? [String: Any],
            let configContent = args["configContent"] as? String else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing or invalid configContent", details: nil))
        return
      }
      
      // 检查是否有网络扩展权限
      checkVPNPermission { [weak self] hasPermission in
        if hasPermission {
          self?.vpnManager.connect(configContent: configContent)
          result(nil)
        } else {
          result(FlutterError(code: "NO_PERMISSION", message: "VPN permission not granted", details: nil))
        }
      }
      
    case "switchProxy":
      guard let args = call.arguments as? [String: Any],
            let configContent = args["configContent"] as? String else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing or invalid configContent", details: nil))
        return
      }
      vpnManager.switchProxy(configContent: configContent)
      result(nil)
      
    default:
      result(FlutterMethodNotImplemented)
    }
  }
  
  // 检查 VPN 权限
  private func checkVPNPermission(completion: @escaping (Bool) -> Void) {
    let manager = NETunnelProviderManager()
    manager.loadFromPreferences { error in
      if let error = error {
        NSLog("加载VPN权限失败: \(error.localizedDescription)")
        completion(false)
        return
      }
      
      manager.isEnabled = true
      manager.saveToPreferences { error in
        if let error = error {
          NSLog("保存VPN权限失败: \(error.localizedDescription)")
          completion(false)
          return
        }
        
        // 权限检查通过
        completion(true)
      }
    }
  }
}

// MARK: - FlutterStreamHandler
extension FlutterLeafPlugin: FlutterStreamHandler {
  public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    eventSink = events
    
    // 设置VPN状态监听
    vpnManager.setStatusChangeHandler { [weak self] state in
      self?.eventSink?(state.rawValue)
    }
    
    return nil
  }
  
  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
    return nil
  }
}
