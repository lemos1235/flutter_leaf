#ifndef FLUTTER_PLUGIN_FLUTTER_LEAF_PLUGIN_H_
#define FLUTTER_PLUGIN_FLUTTER_LEAF_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

#include <flutter/event_channel.h>
#include <flutter/event_sink.h>
#include <flutter/event_stream_handler_functions.h>

namespace flutter_leaf {

enum class VpnState {
  disconnected,
  connecting,
  connected,
  disconnecting, 
  error
};

class LeafStateStreamHandler : public flutter::StreamHandler<flutter::EncodableValue> {
public:
  void StateChanged(VpnState v);
  VpnState vpnState;
protected:
  std::unique_ptr<flutter::StreamHandlerError<flutter::EncodableValue>> OnListenInternal(
    const flutter::EncodableValue* arguments,
    std::unique_ptr<flutter::EventSink<flutter::EncodableValue>>&& events) override;

  virtual std::unique_ptr<flutter::StreamHandlerError<flutter::EncodableValue>> OnCancelInternal(
    const flutter::EncodableValue* arguments) override;
private:
  std::unique_ptr<flutter::EventSink<>> event_sink_;
};

class FlutterLeafPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  FlutterLeafPlugin();

  virtual ~FlutterLeafPlugin();

  // Disallow copy and assign.
  FlutterLeafPlugin(const FlutterLeafPlugin&) = delete;
  FlutterLeafPlugin& operator=(const FlutterLeafPlugin&) = delete;

 private:
  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace flutter_leaf

#endif  // FLUTTER_PLUGIN_FLUTTER_LEAF_PLUGIN_H_
