#import <Foundation/Foundation.h>
#import "LeafBridge.h"

// 这里应该包含 Leaf 的实际头文件
// #import "libleaf/leaf.h"

// 默认的运行时 ID
static uint16_t defaultRuntimeId = 1;
static bool isRunning = false;

bool leaf_start(const char *config) {
    if (isRunning) {
        NSLog(@"Leaf 已经在运行中");
        return false;
    }
    
    // 创建配置文件
    NSString *configDir = [NSTemporaryDirectory() stringByAppendingPathComponent:@"leaf"];
    NSString *configPath = [configDir stringByAppendingPathComponent:@"config.json"];
    
    // 确保目录存在
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:configDir]) {
        [fileManager createDirectoryAtPath:configDir withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    // 写入配置文件
    NSString *configString = [NSString stringWithUTF8String:config];
    [configString writeToFile:configPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    
    // 在后台线程启动 Leaf
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // 使用配置文件启动 Leaf
        int32_t result = leaf_run(defaultRuntimeId, [configPath UTF8String]);
        
        // 也可以直接使用配置字符串启动
        // int32_t result = leaf_run_with_config_string(defaultRuntimeId, config);
        
        if (result != ERR_OK) {
            NSLog(@"启动 Leaf 失败，错误码: %d", result);
            isRunning = false;
        } else {
            NSLog(@"Leaf 已停止运行");
            isRunning = false;
        }
    });
    
    isRunning = true;
    return true;
}

void leaf_stop(void) {
    if (!isRunning) {
        NSLog(@"Leaf 未运行");
        return;
    }
    
    bool result = leaf_shutdown(defaultRuntimeId);
    if (!result) {
        NSLog(@"停止 Leaf 失败");
    }
    
    isRunning = false;
}

bool leaf_update_config(const char *config) {
    if (!isRunning) {
        NSLog(@"Leaf 未运行，无法更新配置");
        return false;
    }
    
    // 写入新的配置
    NSString *configDir = [NSTemporaryDirectory() stringByAppendingPathComponent:@"leaf"];
    NSString *configPath = [configDir stringByAppendingPathComponent:@"config.json"];
    
    NSString *configString = [NSString stringWithUTF8String:config];
    [configString writeToFile:configPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    
    // 重新加载配置
    int32_t result = leaf_reload(defaultRuntimeId);
    
    return result == ERR_OK;
} 