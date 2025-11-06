#import "QuicUICodePushPlugin.h"

@implementation QuicUICodePushPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftQuicUICodePushPlugin registerWithRegistrar:registrar];
}
@end
