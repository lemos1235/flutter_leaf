#ifndef LeafBridge_h
#define LeafBridge_h

#include <stdbool.h>
#include <stdint.h>

// 导入 Leaf 的 C 头文件
#include "../libleaf/leaf.h"

// 定义错误代码
#define ERR_OK 0

// 启动 Leaf 代理，使用配置字符串
bool leaf_start(const char *config);

// 停止 Leaf 代理
void leaf_stop(void);

// 更新 Leaf 配置
bool leaf_update_config(const char *config);

#endif /* LeafBridge_h */ 