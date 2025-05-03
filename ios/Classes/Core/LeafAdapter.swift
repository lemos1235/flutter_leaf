import Foundation

// 导入桥接头文件
// 需要在 Bridging-Header.h 中添加 #import "LeafBridge.h"

class LeafAdapter {
    private var running = false
    
    func start(with config: String) throws {
        guard !running else {
            NSLog("Leaf 已经在运行")
            return
        }
        
        guard let configCString = config.cString(using: .utf8) else {
            throw NSError(domain: "com.lemos.flutter_leaf", code: 2, userInfo: [NSLocalizedDescriptionKey: "配置字符串编码失败"])
        }
        
        let result = leaf_start(configCString)
        if !result {
            throw NSError(domain: "com.lemos.flutter_leaf", code: 3, userInfo: [NSLocalizedDescriptionKey: "启动 Leaf 失败"])
        }
        
        running = true
    }
    
    func stop() {
        guard running else {
            return
        }
        
        leaf_stop()
        running = false
    }
    
    func updateConfig(config: String) -> Bool {
        guard running else {
            NSLog("Leaf 未运行，无法更新配置")
            return false
        }
        
        guard let configCString = config.cString(using: .utf8) else {
            NSLog("配置字符串编码失败")
            return false
        }
        
        return leaf_update_config(configCString)
    }
    
    deinit {
        if running {
            stop()
        }
    }
} 