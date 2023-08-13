#ifndef FLUTTER_PLUGIN_FLUTTER_LEAF_PLUGIN_H_
#define FLUTTER_PLUGIN_FLUTTER_LEAF_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace flutter_leaf {

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
