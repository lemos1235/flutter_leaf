import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_leaf/state.dart';

import 'flutter_leaf_platform_interface.dart';

/// An implementation of [FlutterLeafPlatform] that uses method channels.
class MethodChannelFlutterLeaf extends FlutterLeafPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('flutter_leaf');

  /// The method channel used to receive state change event.
  @visibleForTesting
  final eventChannel = const EventChannel('flutter_leaf_states');

  /// Receive state change from VPN service.
  ///
  /// Can only be listened once. If have more than one subscription, only the
  /// last subscription can receive events.
  @override
  Stream<FlutterLeafState> get onStateChanged =>
      eventChannel.receiveBroadcastStream().map((e) => FlutterLeafState.values[e]);

  /// Get current state.
  @override
  Future<FlutterLeafState> get currentState async {
    final state = await methodChannel.invokeMethod<int>('getCurrentState');
    assert(state != null, 'Received a null state from `getCurrentState` call.');
    return FlutterLeafState.values[state!];
  }

  /// Prepare for vpn connection. (Android only)
  ///
  /// For first connection it will show a dialog to ask for permission.
  /// When your connection was interrupted by another VPN connection,
  /// you should prepare again before reconnect.
  @override
  Future<bool> prepare() async {
    if (!Platform.isAndroid) return true;
    return (await methodChannel.invokeMethod<bool>('prepare'))!;
  }

  /// Check if vpn connection has been prepared. (Android only)
  @override
  Future<bool> get prepared async {
    if (!Platform.isAndroid) return true;
    return (await methodChannel.invokeMethod<bool>('prepared'))!;
  }

  /// Disconnect and stop VPN service.
  @override
  Future<void> disconnect() async {
    await methodChannel.invokeMethod('disconnect');
  }

  /// Connect to VPN.
  ///
  /// This will create a background VPN service.
  /// MTU is only available on android.
  @override
  Future<void> connect({
    required String proxy,
    int? mtu,
    String? allowedApps,
    String? disallowedApps,
  }) async =>
      await methodChannel.invokeMethod('connect', {
        'proxy': proxy,
        if (mtu != null) 'mtu': mtu,
        if (allowedApps != null) 'allowedApps': allowedApps,
        if (disallowedApps != null) 'disallowedApps': disallowedApps,
      });

  /// Switch VPN service's proxy.
  @override
  Future<void> switchProxy({required String proxy}) async {
    await methodChannel.invokeMethod('switchProxy', {
      'proxy': proxy,
    });
  }
}
