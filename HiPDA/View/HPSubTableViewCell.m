//
//  HPSubTableViewCell.m
//  HiPDA
//
//  Created by Jiangfan on 2018/9/15.
//  Copyright © 2018年 wujichao. All rights reserved.
//

#import "HPSubTableViewCell.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "NSString+Additions.h"

@interface HPSubTableViewCell()

@property (nonatomic, strong) UIImageView *avatarView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *dateLabel;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIView *tagView;
@property (nonatomic, strong) UILabel *tagLabel;

@end

@implementation HPSubTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:reuseIdentifier];
    if (!self) {
        return nil;
    }
    
    _avatarView = [UIImageView new];
    _avatarView.backgroundColor = [@"#bdc3c7" colorFromHexString];
    _avatarView.layer.cornerRadius = 2.f;
    [self.contentView addSubview:_avatarView];
    
    _nameLabel = [UILabel new];
    _nameLabel.font = [UIFont systemFontOfSize:12.f];
    _nameLabel.textColor = [UIColor blackColor];
    [self.contentView addSubview:_nameLabel];
    
    _dateLabel = [UILabel new];
    _dateLabel.font = [UIFont systemFontOfSize:12.f];
    _dateLabel.textColor = [UIColor blackColor];
    [self.contentView addSubview:_dateLabel];
    
    _titleLabel = [UILabel new];
    _titleLabel.font = [UIFont systemFontOfSize:20.f];
    _titleLabel.textColor = [UIColor blackColor];
    [self.contentView addSubview:_titleLabel];
    
    _tagView = [UIView new];
    _tagView.layer.cornerRadius = 3.f;
    [self.contentView addSubview:_tagView];
    
    _tagLabel = [UILabel new];
    _tagLabel.font = [UIFont systemFontOfSize:13.f];
    _tagLabel.textColor = [UIColor whiteColor];
    [self.contentView addSubview:_tagLabel];
    
    [_avatarView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.contentView).offset(15.f);
        make.top.equalTo(self.contentView).offset(10.f);
        make.width.height.equalTo(@20);
    }];
    
    [_nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(_avatarView.mas_right).offset(5.f);
        make.centerY.equalTo(_avatarView);
    }];
    
    [_dateLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.contentView).offset(-15.f);
        make.centerY.equalTo(_avatarView);
    }];
    
    [_titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.contentView).offset(15.f);
        make.right.equalTo(self.contentView).offset(-15.f);
        make.top.equalTo(_avatarView.mas_bottom).offset(7.f);
    }];
    
    [_tagView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.greaterThanOrEqualTo(self.contentView).offset(15.f);
        make.right.equalTo(self.contentView).offset(-15.f);
        make.top.equalTo(_titleLabel.mas_bottom).offset(5.f);
    }];
    
    [_tagLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(_tagView).insets(UIEdgeInsetsMake(2, 3, 2, 3));
    }];
    
    return self;
}

- (void)setFeed:(HPApiSubFeed *)feed
{
    self.nameLabel.text = feed.threadInfo.userName;
    [self.avatarView sd_setImageWithURL:[NSURL URLWithString:feed.threadInfo.avatar] placeholderImage:nil options:SDWebImageLowPriority];
    self.titleLabel.text = feed.threadInfo.title;
    self.dateLabel.text = [@(feed.threadInfo.created) stringValue];
    
    if (feed.subByUser) {
        self.tagLabel.text = [NSString stringWithFormat:@"用户: %@", feed.threadInfo.userName];
        self.tagView.backgroundColor = [@"#d35400" colorFromHexString];
    } else if (feed.subByKeyword) {
        self.tagLabel.text = [NSString stringWithFormat:@"关键词: %@", feed.subByKeyword.keyword];
        self.tagView.backgroundColor = [@"#27ae60" colorFromHexString];
    } else {
        self.tagLabel.text = nil;
        self.tagView.backgroundColor = [UIColor clearColor];
    }
}

@end
