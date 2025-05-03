import Foundation
import NetworkExtension

class VPNManager {
    static let shared = VPNManager()
    
    private var manager: NETunnelProviderManager?
    private var statusHandler: ((FlutterLeafState) -> Void)?
    // 需要替换为实际的 Bundle ID，现在改为动态获取
    private var leafProviderBundleIdentifier: String {
        return Bundle.main.bundleIdentifier! + ".VPNExtension"
    }
    
    private init() {
        // 监听VPN状态变化
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(vpnStatusDidChange),
            name: .NEVPNStatusDidChange,
            object: nil
        )
        
        // 初始化VPN管理器
        loadVPNManager()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // 加载VPN管理器
    private func loadVPNManager() {
        NETunnelProviderManager.loadAllFromPreferences { [weak self] managers, error in
            if let error = error {
                NSLog("加载VPN配置失败: \(error.localizedDescription)")
                return
            }
            
            if let managers = managers, !managers.isEmpty {
                // 找到与我们的 provider 相匹配的管理器
                for manager in managers {
                    if let tunnelProtocol = manager.protocolConfiguration as? NETunnelProviderProtocol,
                       tunnelProtocol.providerBundleIdentifier == self?.leafProviderBundleIdentifier {
                        self?.manager = manager
                        break
                    }
                }
                
                if self?.manager == nil {
                    // 如果没有找到匹配的，使用第一个或创建新的
                    self?.manager = managers.first ?? NETunnelProviderManager()
                }
            } else {
                // 创建新的VPN管理器
                self?.manager = NETunnelProviderManager()
            }
        }
    }
    
    // 监听VPN状态变化
    @objc private func vpnStatusDidChange(_ notification: Notification) {
        guard let connection = manager?.connection else { return }
        let state = mapVPNStatus(connection.status)
        statusHandler?(state)
    }
    
    // 将NEVPNStatus映射到FlutterLeafState
    private func mapVPNStatus(_ status: NEVPNStatus) -> FlutterLeafState {
        switch status {
        case .invalid, .disconnected:
            return .disconnected
        case .connecting:
            return .connecting
        case .connected:
            return .connected
        case .disconnecting:
            return .disconnecting
        case .reasserting:
            return .connecting
        @unknown default:
            return .error
        }
    }
    
    // 获取当前VPN状态
    func getCurrentState() -> FlutterLeafState {
        guard let connection = manager?.connection else {
            return .disconnected
        }
        return mapVPNStatus(connection.status)
    }
    
    // 设置状态变化处理器
    func setStatusChangeHandler(_ handler: @escaping (FlutterLeafState) -> Void) {
        statusHandler = handler
        
        // 立即通知当前状态
        if let connection = manager?.connection {
            let state = mapVPNStatus(connection.status)
            handler(state)
        }
    }
    
    // 连接VPN
    func connect(configContent: String) {
        // 创建Leaf配置
        let tunnelProtocol = NETunnelProviderProtocol()
        tunnelProtocol.providerBundleIdentifier = leafProviderBundleIdentifier
        tunnelProtocol.serverAddress = "Leaf VPN" // 这只是一个标识，不需要是实际的服务器地址
        
        // 存储配置内容
        tunnelProtocol.providerConfiguration = [
            "configContent": configContent
        ]
        
        manager?.protocolConfiguration = tunnelProtocol
        manager?.localizedDescription = "Leaf VPN"
        manager?.isEnabled = true
        
        manager?.saveToPreferences { [weak self] error in
            if let error = error {
                NSLog("保存VPN配置失败: \(error.localizedDescription)")
                self?.statusHandler?(.error)
                return
            }
            
            // 启动VPN连接
            do {
                try self?.manager?.connection.startVPNTunnel()
            } catch {
                NSLog("启动VPN连接失败: \(error.localizedDescription)")
                self?.statusHandler?(.error)
            }
        }
    }
    
    // 断开VPN连接
    func disconnect() {
        manager?.connection.stopVPNTunnel()
    }
    
    // 切换代理
    func switchProxy(configContent: String) {
        guard let session = manager?.connection as? NETunnelProviderSession,
              session.status == .connected else {
            NSLog("VPN未连接，无法切换代理")
            statusHandler?(.error)
            return
        }
        
        do {
            try session.sendProviderMessage(configContent.data(using: .utf8)!) { _ in
                // 处理响应
            }
        } catch {
            NSLog("发送代理切换消息失败: \(error.localizedDescription)")
            statusHandler?(.error)
        }
    }
} 