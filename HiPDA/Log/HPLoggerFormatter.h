//
//  HPLoggerFormatter.h
//  LoggerDemo
//

#import <Foundation/Foundation.h>
#import <CocoaLumberjack/CocoaLumberjack.h>

@interface HPASLLoggerFormatter : NSObject <DDLogFormatter>
@end

@interface HPFileLoggerFormatter : NSObject <DDLogFormatter>
@end
