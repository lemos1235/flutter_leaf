#include "include/flutter_leaf/flutter_leaf_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "flutter_leaf_plugin.h"

void FlutterLeafPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  flutter_leaf::FlutterLeafPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
