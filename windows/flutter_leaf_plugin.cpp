#include "flutter_leaf_plugin.h"

// This must be included before many other Windows headers.
#include <windows.h>

// For getPlatformVersion; remove unless needed for your plugin implementation.
#include <VersionHelpers.h>

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <memory>
#include <sstream>

extern "C" {
#include "include/leaf.h"
}

#include <iostream>
#include <fstream>
#include <string>
#include <filesystem>

namespace fs = std::filesystem;

namespace flutter_leaf {

  //配置文件名称
  const char* config_file_name = "config.conf";

  //配置模板内容
  std::string config_file_template = "[General]\n" \
    "dns-server = 223.5.5.5\n" \
    "tun = auto\n" \
    "loglevel = debug\n" \
    "[Proxy]\n" \
    "Direct = direct\n" \
    "SOCKS5 = socks,192.168.1.9,7890\n" \
    "[Rule]\n" \
    "FINAL, SOCKS5\n";

  //加载配置文件
  fs::path create_config_file(const char* file_name) {
    fs::path exePath = fs::current_path();
    fs::path configFilePath = exePath / config_file_name;
    if (!fs::exists(configFilePath)) {
      std::ofstream configFile(configFilePath);
      if (configFile.is_open()) {
        configFile << config_file_template;
        configFile.close();
        std::cout << "Created and wrote default configuration to: " << configFilePath << std::endl;
      }
      else {
        std::cerr << "Error: Unable to create config file." << std::endl;
      }
    }
    else {
      std::cout << "Config file already exists: " << configFilePath << std::endl;
    }
    return configFilePath;
  }

  // static
  void FlutterLeafPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows* registrar) {
    auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
        registrar->messenger(), "flutter_leaf",
        &flutter::StandardMethodCodec::GetInstance());

    auto plugin = std::make_unique<FlutterLeafPlugin>();

    channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto& call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

    auto eventChannel = std::make_unique<flutter::EventChannel<flutter::EncodableValue>>(
      registrar->messenger(), "flutter_leaf_states",
      &flutter::StandardMethodCodec::GetInstance());

    eventChannel->SetStreamHandler(
      std::make_unique<LeafStateStreamHandler>());

    registrar->AddPlugin(std::move(plugin));
  }

  FlutterLeafPlugin::FlutterLeafPlugin() {}

  FlutterLeafPlugin::~FlutterLeafPlugin() {}

  //处理插件方法
  void FlutterLeafPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue>& method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
    if (method_call.method_name().compare("prepare") == 0) {
      //LeafStateStreamHandler::vpnState = VpnState::disconnected;
      result->Success(flutter::EncodableValue(true));
    }
    else if (method_call.method_name().compare("prepared") == 0) {
      result->Success(flutter::EncodableValue(true));
    }
    else if (method_call.method_name().compare("getCurrentState") == 0) {
      //int s = static_cast<int>(LeafStateStreamHandler::vpnState);
      result->Success(flutter::EncodableValue(0));
    }
    else if (method_call.method_name().compare("disconnect") == 0) {
      result->Success(flutter::EncodableValue(true));
    }
    else if (method_call.method_name().compare("switchProxy") == 0) {
      result->Success(flutter::EncodableValue(true));
    }
    else if (method_call.method_name().compare("connect") == 0) {
      fs::path config_path = create_config_file(config_file_name);
      //变更状态
      //LeafStateStreamHandler::StateChanged(VpnState::connecting);
      int i = leaf_run(0, config_path.string().c_str());
      std::cout << "leaf_run return value:" << i << std::endl;
      result->Success(flutter::EncodableValue(true));
    }
    else {
      result->NotImplemented();
    }
  }

  //处理状态事件
  void LeafStateStreamHandler::StateChanged(VpnState v) {
    vpnState = v;
    std::cout << "hello";
  }

  std::unique_ptr<flutter::StreamHandlerError<flutter::EncodableValue>> LeafStateStreamHandler::OnListenInternal(
    const flutter::EncodableValue* arguments,
    std::unique_ptr<flutter::EventSink<flutter::EncodableValue>>&& events) {
    event_sink_ = std::move(events);
    return nullptr;
  }

  std::unique_ptr<flutter::StreamHandlerError<flutter::EncodableValue>> LeafStateStreamHandler::OnCancelInternal(
    const flutter::EncodableValue* arguments) {
    event_sink_ = nullptr;
    return nullptr;
  }

}  // namespace flutter_leaf
