//
//  HPUser.h
//  HiPDA
//
//  Created by wujichao on 13-11-11.
//  Copyright (c) 2013年 wujichao. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HPUser : NSObject<NSCoding>

@property (nonatomic, assign) NSInteger uid;
@property (nonatomic, strong) NSString *username;
@property (nonatomic, strong) NSURL *avatarImageURL;
//@property (nonatomic, strong) UIImage *avatar;

- (id)initWithAttributes:(NSDictionary *)attributes;


+ (NSURL *)avatarStringWithUid:(NSInteger)_uid;


+ (void)getUserSpaceDetailsWithUid:(NSInteger)uid orUsername:(NSString *)username block:(void (^)(NSDictionary* dict, NSError *error))block;


+ (void)getUserUidWithUserName:(NSString *)username
                         block:(void (^)(NSString *uid, NSError *error))block;
+ (void)getUserSignatureWithUid:(NSString *)uid
                          block:(void (^)(NSString *signature, NSError *error))block;

@end
