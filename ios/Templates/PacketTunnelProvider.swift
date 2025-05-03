import NetworkExtension
import Foundation

class PacketTunnelProvider: NEPacketTunnelProvider {
    
    private var leaf: LeafAdapter?
    
    override func startTunnel(options: [String: NSObject]?, completionHandler: @escaping (Error?) -> Void) {
        // 配置默认的网络设置
        let networkSettings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: "192.168.1.1")
        networkSettings.mtu = 1500
        
        // 配置IPv4路由
        let ipv4Settings = NEIPv4Settings(addresses: ["192.168.1.2"], subnetMasks: ["255.255.255.0"])
        ipv4Settings.includedRoutes = [NEIPv4Route.default()]
        networkSettings.ipv4Settings = ipv4Settings
        
        // 配置DNS
        let dnsSettings = NEDNSSettings(servers: ["8.8.8.8", "8.8.4.4"])
        networkSettings.dnsSettings = dnsSettings
        
        // 设置网络配置
        setTunnelNetworkSettings(networkSettings) { [weak self] error in
            if let error = error {
                NSLog("设置网络隧道失败: \(error.localizedDescription)")
                completionHandler(error)
                return
            }
            
            guard let configContent = options?["configContent"] as? String else {
                let error = NSError(domain: "com.lemos.flutter_leaf", code: 1, userInfo: [NSLocalizedDescriptionKey: "配置内容为空"])
                completionHandler(error)
                return
            }
            
            // 初始化并启动 Leaf
            self?.startLeaf(configContent: configContent) { error in
                completionHandler(error)
            }
        }
    }
    
    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        // 停止 Leaf
        leaf?.stop()
        leaf = nil
        
        // 完成停止
        completionHandler()
    }
    
    override func handleAppMessage(_ messageData: Data, completionHandler: ((Data?) -> Void)?) {
        guard let message = String(data: messageData, encoding: .utf8) else {
            completionHandler?(nil)
            return
        }
        
        // 处理应用消息，如配置更新
        if leaf != nil {
            // 更新 Leaf 配置
            leaf?.updateConfig(config: message)
            completionHandler?("更新成功".data(using: .utf8))
        } else {
            completionHandler?(nil)
        }
    }
    
    private func startLeaf(configContent: String, completion: @escaping (Error?) -> Void) {
        // 创建 LeafAdapter 实例
        leaf = LeafAdapter()
        
        // 启动 Leaf
        do {
            try leaf?.start(with: configContent)
            completion(nil)
        } catch {
            NSLog("启动 Leaf 失败: \(error.localizedDescription)")
            completion(error)
        }
    }
} 