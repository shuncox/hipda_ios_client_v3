//
//  HPOnceRunService.h
//

#import <Foundation/Foundation.h>

@interface HPOnceRunService : NSObject

+ (void)onceName:(NSString *)name runBlcok:(void(^)(void))block skipBlock:(void (^)(void))skipBlock;
+ (BOOL)isOnceName:(NSString *)name;

@end
