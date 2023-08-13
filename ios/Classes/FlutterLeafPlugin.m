#import "FlutterLeafPlugin.h"
#if __has_include(<flutter_leaf/flutter_leaf-Swift.h>)
#import <flutter_leaf/flutter_leaf-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "flutter_leaf-Swift.h"
#endif

@implementation FlutterLeafPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftFlutterLeafPlugin registerWithRegistrar:registrar];
}
@end
