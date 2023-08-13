import 'package:flutter_leaf/state.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'flutter_leaf_method_channel.dart';

abstract class FlutterLeafPlatform extends PlatformInterface {
  /// Constructs a FlutterLeafPlatform.
  FlutterLeafPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterLeafPlatform _instance = MethodChannelFlutterLeaf();

  /// The default instance of [FlutterLeafPlatform] to use.
  ///
  /// Defaults to [MethodChannelFlutterLeaf].
  static FlutterLeafPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FlutterLeafPlatform] when
  /// they register themselves.
  static set instance(FlutterLeafPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }


  /// Receive state change from VPN service.
  ///
  /// Can only be listened once. If have more than one subscription, only the
  /// last subscription can receive events.
  Stream<FlutterLeafState> get onStateChanged => throw UnimplementedError();

  /// Get current state.
  Future<FlutterLeafState> get currentState async => throw UnimplementedError();

  /// Prepare for vpn connection. (Android only)
  ///
  /// For first connection it will show a dialog to ask for permission.
  /// When your connection was interrupted by another VPN connection,
  /// you should prepare again before reconnect.
  Future<bool> prepare() async => throw UnimplementedError();

  /// Check if vpn connection has been prepared. (Android only)
  Future<bool> get prepared async => throw UnimplementedError();

  /// Disconnect and stop VPN service.
  Future<void> disconnect() async => throw UnimplementedError();

  /// Connect to VPN.
  ///
  /// This will create a background VPN service.
  /// MTU is only available on android.
  Future<void> connect({
    required String proxy,
    int? mtu,
    String? allowedApps,
    String? disallowedApps,
  }) async =>
      throw UnimplementedError();

  /// Switch VPN service's proxy.
  Future<void> switchProxy({
    required String proxy,
  }) async =>
      throw UnimplementedError();
}
