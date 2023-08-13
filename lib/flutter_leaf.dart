import 'package:flutter_leaf/flutter_leaf_platform_interface.dart';
import 'package:flutter_leaf/state.dart';

class FlutterLeaf {
  /// Receive state change from VPN service.
  ///
  /// Can only be listened once. If have more than one subscription, only the
  /// last subscription can receive events.
  static Stream<FlutterLeafState> get onStateChanged =>
      FlutterLeafPlatform.instance.onStateChanged;

  /// Get current state.
  static Future<FlutterLeafState> get currentState =>
      FlutterLeafPlatform.instance.currentState;

  /// Prepare for vpn connection. (Android only)
  ///
  /// For first connection it will show a dialog to ask for permission.
  /// When your connection was interrupted by another VPN connection,
  /// you should prepare again before reconnect.
  static Future<bool> prepare() => FlutterLeafPlatform.instance.prepare();

  /// Check if vpn connection has been prepared. (Android only)
  static Future<bool> get prepared => FlutterLeafPlatform.instance.prepared;

  /// Disconnect and stop VPN service.
  static Future<void> disconnect() => FlutterLeafPlatform.instance.disconnect();

  /// Connect to VPN.
  ///
  /// This will create a background VPN service.
  /// MTU is only available on android.
  static Future<void> connect({
    required String proxy,
    int? mtu,
    String? allowedApps,
    String? disallowedApps,
  }) =>
      FlutterLeafPlatform.instance.connect(
        proxy: proxy,
        mtu: mtu,
        allowedApps: allowedApps,
        disallowedApps: disallowedApps,
      );

  /// Switch VPN service's proxy.
  static Future<void> switchProxy({
    required String proxy,
  }) =>
      FlutterLeafPlatform.instance.switchProxy(
        proxy: proxy,
      );
}
