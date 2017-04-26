//
//  HPLoggerFormatter.m
//  LoggerDemo
//

#import "HPLoggerFormatter.h"
#import "time.h"

@interface HPASLLoggerFormatter()
@property (nonatomic) NSDateFormatter *dateFormatter;
@end

static inline NSString *logFlagToString(DDLogFlag flag)
{
    NSString *logLevel = @"Verbose";
    switch (flag) {
        case DDLogFlagError:
            logLevel = @"Error";
            break;
        case DDLogFlagWarning: {
            logLevel = @"Warning";
            break;
        }
        case DDLogFlagInfo: {
            logLevel = @"Info";
            break;
        }
        case DDLogFlagDebug: {
            logLevel = @"Debug";
            break;
        }
        case DDLogFlagVerbose: {
            logLevel = @"Verbose";
            break;
        }
    }
    return logLevel;
}

static inline NSString *logDateToString(NSDate *date)
{
    double ts = [date timeIntervalSince1970];
    time_t unixTime = (time_t)ts;
    struct tm timeStruct;
    localtime_r(&unixTime, &timeStruct);
    
    char buffer[30];
    size_t offset = strftime(buffer, 30, "%Y-%m-%d %H:%M:%S", &timeStruct);
    
    double fractpart, intpart;
    fractpart = modf(ts , &intpart);
    snprintf(buffer+offset, 30-offset, ":%d", (int)(fractpart * 1000));
    
    NSString *output = [NSString stringWithCString:buffer encoding:[NSString defaultCStringEncoding]];
    return output;
}

@implementation HPASLLoggerFormatter

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.dateFormatter = [[NSDateFormatter alloc] init];
        [self.dateFormatter setDateFormat:@"HH:mm:ss:SSS"];
    }
    return self;
}

- (NSString *)formatLogMessage:(DDLogMessage *)logMessage
{
    NSString *logLevel = logFlagToString(logMessage.flag);
    NSString *dateAndTime = logDateToString(logMessage.timestamp);
    
    return [NSString stringWithFormat:@"<%@><%@> %@ %@:%ld %@ \n-> %@", logLevel, logMessage.queueLabel, dateAndTime, logMessage.fileName, (long)logMessage.line, logMessage.function, logMessage.message];
}

@end

@interface HPFileLoggerFormatter()
@property (nonatomic) NSDateFormatter *dateFormatter;
@end

@implementation HPFileLoggerFormatter

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.dateFormatter = [[NSDateFormatter alloc] init];
        [self.dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss:SSS"];
    }
    return self;
}

- (NSString *)formatLogMessage:(DDLogMessage *)logMessage
{
    NSString *logLevel = logFlagToString(logMessage.flag);
    NSString *dateAndTime = logDateToString(logMessage.timestamp);
    
    return [NSString stringWithFormat:@"<%@><%@> %@ %@:%ld %@ \n-> %@", logLevel, logMessage.queueLabel, dateAndTime, logMessage.fileName, (long)logMessage.line, logMessage.function, logMessage.message];
}

@end
