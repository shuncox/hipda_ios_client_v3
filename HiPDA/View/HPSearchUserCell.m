//
//  HPSearchUserCell.m
//  HiPDA
//
//  Created by Jichao Wu on 15/10/27.
//  Copyright © 2015年 wujichao. All rights reserved.
//

#import "HPSearchUserCell.h"
#import <UIImageView+WebCache.h>

@interface HPSearchUserCell()

@property (nonatomic, strong) UIImageView *avatarView;
@property (nonatomic, strong) UILabel *nameLabel;

@end

@implementation HPSearchUserCell
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:reuseIdentifier];
    if (!self) {
        return nil;
    }
    
    _avatarView = [UIImageView new];
    _avatarView.backgroundColor = [UIColor lightGrayColor];
    [self.contentView addSubview:_avatarView];
    
    _nameLabel = [UILabel new];
    _nameLabel.font = [UIFont systemFontOfSize:18.f];
    _nameLabel.textColor = [UIColor blackColor];
    [self.contentView addSubview:_nameLabel];
    
    [_avatarView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.contentView).offset(15.f);
        make.top.equalTo(self.contentView).offset(4.f);
        make.bottom.equalTo(self.contentView).offset(-4.f);
        make.width.equalTo(_avatarView.mas_height);
    }];
    
    [_nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(_avatarView.mas_right).offset(10.f);
        make.centerY.equalTo(self.contentView);
    }];
    
    
    return self;
}

- (void)setUser:(HPUser *)user
{
    _user = user;
    
    self.nameLabel.text = user.username;
    self.detailTextLabel.text = [NSString stringWithFormat:@"id: %@", @(user.uid)];
    [self.avatarView sd_setImageWithURL:[HPUser avatarStringWithUid:user.uid] placeholderImage:[UIImage imageNamed:@"clear_color"] options:SDWebImageLowPriority];
}
@end
