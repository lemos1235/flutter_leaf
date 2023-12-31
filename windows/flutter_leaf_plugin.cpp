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

  //加载配置文件
  fs::path load_config_file(std::string configContent) {
    fs::path exePath = fs::current_path();
    fs::path configFilePath = exePath / config_file_name;
    std::ofstream ofs(configFilePath);
    if (ofs.is_open()) {
      ofs << configContent;
      ofs.close();
    }
    else {
      std::cerr << "failed to load file " << config_file_name << std::endl;
    }
    return configFilePath;
  }

  void start_leaf(std::string configContent) {
    auto config_path = load_config_file(configContent);
    int i = leaf_run(0, config_path.string().c_str());
    std::cout << "leaf_run return value:" << i << std::endl;
  }

  void reload_leaf(std::string configContent) {
    load_config_file(configContent);
    int i = leaf_reload(0);
    std::cout << "leaf_reload return value:" << i << std::endl;
  }

  void stop_leaf() {
    bool i = leaf_shutdown(0);
    std::cout << "leaf_shutdown return value:" << i << std::endl;
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
      //ͣ停止leaf，并等待线程结束
      stop_leaf();
      //变更状态
      stream_handler_->StateChanged(VpnState::disconnected);
      result->Success(flutter::EncodableValue(true));
    }
    else if (method_call.method_name().compare("switchProxy") == 0) {
      auto* arguments = std::get_if<flutter::EncodableMap>(method_call.arguments());
      auto configContent = std::get<std::string>(arguments->at(flutter::EncodableValue("configContent")));
      reload_leaf(configContent);
      result->Success(flutter::EncodableValue(true));
    }
    else if (method_call.method_name().compare("connect") == 0) {
      auto* arguments = std::get_if<flutter::EncodableMap>(method_call.arguments());
      auto configContent = std::get<std::string>(arguments->at(flutter::EncodableValue("configContent")));
      //变更状态
      stream_handler_->StateChanged(VpnState::connecting);
      //启动线程
      connection_handler_ = std::thread(start_leaf, configContent);
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
