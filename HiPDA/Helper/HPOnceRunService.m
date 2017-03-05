//
//  HPOnceRunService.m
//

#import "HPOnceRunService.h"

@implementation HPOnceRunService

static NSArray *__nameArray = nil;

+ (NSString *)namesPath
{
    return [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES)[0] stringByAppendingPathComponent:@"OnceNames.plist"];
}

+ (NSArray *)nameArray
{
    if (!__nameArray) {
        __nameArray = [NSArray arrayWithContentsOfFile:self.namesPath];
        __nameArray = __nameArray? : [NSArray array];
    }
    return __nameArray;
}

+ (void)saveNameArray:(NSArray *)array
{
    __nameArray = array;
    [array writeToFile:self.namesPath
            atomically:YES];
}

+ (void)onceName:(NSString *)name runBlcok:(void (^)(void))block skipBlock:(void (^)(void))skipBlock
{
    if ([self.nameArray indexOfObject:name] == NSNotFound) {
        NSMutableArray *newArray = [NSMutableArray arrayWithArray:self.nameArray];
        [newArray addObject:name];
        [self saveNameArray:newArray];
        
        if (block)
            block();
    }
    else {
        if (skipBlock) {
            skipBlock();
        }
    }
}

+ (BOOL)isOnceName:(NSString *)name
{
    if ([self.nameArray indexOfObject:name] == NSNotFound) {
        return YES;
    }
    return NO;
}
@end
