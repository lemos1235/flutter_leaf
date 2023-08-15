#include "flutter_leaf_plugin.h"

// This must be included before many other Windows headers.
#include <windows.h>

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
    "SOCKS5 = socks,192.168.1.14,1080\n" \
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

  void start_leaf() {
    auto config_path = create_config_file(config_file_name);
    int i = leaf_run(1, config_path.string().c_str());
    std::cout << "leaf_run return value:" << i << std::endl;
  }

  void stop_leaf() {
    leaf_shutdown(1);
  }
  // static
  void FlutterLeafPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows* registrar) {

    auto event_channel = std::make_unique<flutter::EventChannel<flutter::EncodableValue>>(
      registrar->messenger(), "flutter_leaf_states",
      &flutter::StandardMethodCodec::GetInstance());

    auto stream_handler = std::make_unique<LeafStateStreamHandler>();

    auto* stream_handler_pointer = stream_handler.get();

    event_channel->SetStreamHandler(std::move(stream_handler));

    auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
        registrar->messenger(), "flutter_leaf",
        &flutter::StandardMethodCodec::GetInstance());

    auto* channel_pointer = channel.get();

    auto plugin = std::make_unique<FlutterLeafPlugin>(registrar, stream_handler_pointer, std::move(channel));

    channel_pointer->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto& call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

    registrar->AddPlugin(std::move(plugin));
  }

  FlutterLeafPlugin::FlutterLeafPlugin(
    flutter::PluginRegistrarWindows* registrar,
    LeafStateStreamHandler* stream_handler,
    std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel
  ) : registrar_(registrar), stream_handler_(stream_handler), channel_(std::move(channel))
  {
  }

  FlutterLeafPlugin::~FlutterLeafPlugin() {}

  //处理插件方法
  void FlutterLeafPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue>& method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
    if (method_call.method_name().compare("prepare") == 0) {
      result->Success(flutter::EncodableValue(true));
    }
    else if (method_call.method_name().compare("prepared") == 0) {
      result->Success(flutter::EncodableValue(true));
    }
    else if (method_call.method_name().compare("getCurrentState") == 0) {
      int s = static_cast<int>(stream_handler_->vpnState);
      result->Success(flutter::EncodableValue(s));
    }
    else if (method_call.method_name().compare("disconnect") == 0) {
      //变更状态
      stream_handler_->StateChanged(VpnState::disconnecting);
      //停止leaf，并等待线程结束
      stop_leaf();
      connection_handler_.join();
      //变更状态
      stream_handler_->StateChanged(VpnState::disconnected);
      result->Success(flutter::EncodableValue(true));
    }
    else if (method_call.method_name().compare("switchProxy") == 0) {
      result->Success(flutter::EncodableValue(true));
    }
    else if (method_call.method_name().compare("connect") == 0) {
      //变更状态
      stream_handler_->StateChanged(VpnState::connecting);
      //启动线程
      connection_handler_ = std::thread(start_leaf);
      connection_handler_.detach();
      //变更状态
      stream_handler_->StateChanged(VpnState::connected);
      result->Success(flutter::EncodableValue(true));
    }
    else {
      result->NotImplemented();
    }
  }

  //处理状态事件
  void LeafStateStreamHandler::StateChanged(VpnState v) {
    vpnState = v;
    int s = static_cast<int>(v);
    event_sink_->Success(flutter::EncodableValue(s));
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
