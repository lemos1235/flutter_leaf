# Flutter Leaf VPN Extension 模板

这个目录包含了实现 VPN 功能所需的模板文件。使用本插件的 Flutter 应用需要添加 Network Extension Target 到他们的应用中，并使用这些模板文件。

## 文件说明

- **PacketTunnelProvider.swift**: VPN 扩展的主类，负责处理 VPN 连接和 Leaf 代理
- **Info.plist**: 包含 VPN 扩展所需的配置
- **VPNExtension.entitlements**: 包含 VPN 扩展所需的权限配置

## 与插件的集成

当您使用此插件时，核心功能是通过 CocoaPods 自动集成的。您无需手动导入 Leaf 库，因为插件的 podspec 已经配置了：
```
s.vendored_libraries = 'Classes/libleaf/libleaf.a'
```

PacketTunnelProvider.swift 已被设计为与插件的核心功能无缝协作。

## 集成步骤

1. 在 Xcode 中打开你的 Flutter 应用的 iOS 项目
2. 添加 Network Extension Capability:
   - 选择主应用 Target
   - 切换到 "Signing & Capabilities" 选项卡
   - 点击 "+ Capability"
   - 选择 "Network Extensions"

3. 创建 VPN Extension Target:
   - 在 Xcode 中选择 "File" > "New" > "Target"
   - 选择 "Network Extension"
   - 命名为 "VPNExtension" (也可以使用其他名称)
   - 配置与主应用相同的开发团队

4. 配置应用组:
   - 在主应用和 VPNExtension Target 中添加相同的应用组
   - 应用组 ID 应该是 `group.你的应用Bundle标识符`

5. 复制模板文件到你的 VPNExtension Target:
   - 从这个目录复制 `PacketTunnelProvider.swift` 到你的 VPNExtension Target
   - 确保 VPNExtension Target 有正确的 Info.plist 和 Entitlements 配置

6. 自动配置（可选）：
   ```bash
   cd your_flutter_project
   ruby ios/.symlinks/plugins/flutter_leaf/ios/scripts/setup_vpn_extension.rb ios/Runner.xcodeproj Runner
   ```

7. 其他必要权限:
   - 确保主应用的 Info.plist 包含 NSVPNUsageDescription 键值
   - 添加必要的网络和隐私权限

## 自定义

如果需要，你可以根据你的应用需求修改 PacketTunnelProvider.swift 文件中的网络设置。文件中的注释将帮助您理解每个部分的作用。

## 注意事项

- VPN Extension 运行在它自己的沙盒环境中，与主应用隔离
- 使用应用组来共享数据
- 需要正确配置签名和权限才能成功提交到 App Store 