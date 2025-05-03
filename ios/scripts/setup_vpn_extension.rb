#!/usr/bin/env ruby
# 这个脚本帮助在 Flutter 应用中设置 VPN Extension Target

require 'xcodeproj'
require 'fileutils'

def setup_vpn_extension(project_path, main_target_name)
  # 打开项目
  project = Xcodeproj::Project.open(project_path)
  
  # 找到主目标
  main_target = project.targets.find { |t| t.name == main_target_name }
  raise "找不到目标: #{main_target_name}" unless main_target
  
  # 检查是否已存在 VPNExtension 目标
  if project.targets.any? { |t| t.name == "VPNExtension" }
    puts "VPNExtension 目标已存在"
    return
  end
  
  # 创建 VPNExtension 目标
  vpn_target = project.new_target(:app_extension, "VPNExtension", :ios, '12.0')
  
  # 配置构建设置
  vpn_target.build_configurations.each do |config|
    config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = "#{main_target.build_configurations.first.build_settings['PRODUCT_BUNDLE_IDENTIFIER']}.VPNExtension"
    config.build_settings['CODE_SIGN_ENTITLEMENTS'] = "VPNExtension/VPNExtension.entitlements"
    config.build_settings['DEVELOPMENT_TEAM'] = main_target.build_configurations.first.build_settings['DEVELOPMENT_TEAM']
    config.build_settings['SWIFT_VERSION'] = '5.0'
  end
  
  # 创建 VPNExtension 目录
  vpn_dir = File.dirname(project_path) + "/VPNExtension"
  FileUtils.mkdir_p(vpn_dir) unless File.directory?(vpn_dir)
  
  # 复制文件
  plugin_dir = File.expand_path("../../", __FILE__)
  source_dir = File.join(plugin_dir, "Templates")
  
  # 复制 PacketTunnelProvider.swift
  FileUtils.cp(File.join(source_dir, "PacketTunnelProvider.swift"), vpn_dir)
  
  # 复制并修改 Info.plist
  info_plist_path = File.join(vpn_dir, "Info.plist")
  FileUtils.cp(File.join(source_dir, "Info.plist"), info_plist_path)
  
  # 复制并修改 entitlements 文件
  entitlements_path = File.join(vpn_dir, "VPNExtension.entitlements")
  FileUtils.cp(File.join(source_dir, "VPNExtension.entitlements"), entitlements_path)
  
  # 添加文件引用
  vpn_group = project.main_group.find_subpath('VPNExtension', true)
  
  # 添加 PacketTunnelProvider.swift
  file_ref = vpn_group.new_file("VPNExtension/PacketTunnelProvider.swift")
  vpn_target.add_file_references([file_ref])
  
  # 添加 Info.plist
  info_ref = vpn_group.new_file("VPNExtension/Info.plist")
  
  # 添加 entitlements 文件
  entitlements_ref = vpn_group.new_file("VPNExtension/VPNExtension.entitlements")
  
  # 添加 Network Extension capability
  main_target_attributes = project.root_object.attributes['TargetAttributes'] || {}
  main_target_id = main_target.uuid
  main_target_attributes[main_target_id] = {} unless main_target_attributes[main_target_id]
  
  system_capabilities = main_target_attributes[main_target_id]['SystemCapabilities'] || {}
  system_capabilities['com.apple.NetworkExtensions.iOS'] = { 'enabled' => 1 }
  main_target_attributes[main_target_id]['SystemCapabilities'] = system_capabilities
  
  # 配置应用组
  app_group_name = "group.#{main_target.build_configurations.first.build_settings['PRODUCT_BUNDLE_IDENTIFIER']}"
  
  # 写回文件
  project.save
  
  puts "VPNExtension 目标已成功创建!"
  puts "请确保主应用的 Info.plist 中添加了 NSVPNUsageDescription 权限描述"
  puts "请配置应用组: #{app_group_name}"
end

# 使用方法
if ARGV.length < 2
  puts "用法: ruby setup_vpn_extension.rb <project_path> <main_target_name>"
  puts "例如: ruby setup_vpn_extension.rb ./ios/Runner.xcodeproj Runner"
  exit 1
end

setup_vpn_extension(ARGV[0], ARGV[1]) 