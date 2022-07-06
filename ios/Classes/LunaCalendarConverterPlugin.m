#import "LunaCalendarConverterPlugin.h"
#if __has_include(<luna_calendar_converter/luna_calendar_converter-Swift.h>)
#import <luna_calendar_converter/luna_calendar_converter-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "luna_calendar_converter-Swift.h"
#endif

@implementation LunaCalendarConverterPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftLunaCalendarConverterPlugin registerWithRegistrar:registrar];
}
@end
