//
//  HPThreadCell.m
//  HiPDA
//
//  Created by wujichao on 14-3-17.
//  Copyright (c) 2014年 wujichao. All rights reserved.
//

#import "HPThreadCell.h"
#import "HPThread.h"
#import "HPUser.h"
#import "HPCache.h"
#import "HPTheme.h"
#import "HPSetting.h"
#import <UIImageView+WebCache.h>

#define PERCENT ([Setting integerForKey:HPSettingFontSizeAdjust]/100.f)

#define CELL_CONTENT_WIDTH (___width)
#define CELL_CONTENT_MARGIN (ceilf(PERCENT*8.0f))
#define CELL_IMAGE_WIDTH (ceilf(PERCENT*44.0f))
#define CELL_IMAGE_MARGIN (ceilf(PERCENT*8.0f))

#define FONT_SIZE (ceilf(PERCENT*16.f)) //title font size

#define CELL_MIN_HEIGHT (CELL_IMAGE_WIDTH+CELL_IMAGE_MARGIN*2)

#define CELL_SUB_HEIGHT (ceilf(PERCENT*15.0f))
#define SUB_FONT_SIZE (ceilf(PERCENT*13.f)) //sub font size, cannot change

@implementation HPThreadCell {

@private
    UIImageView *_avatarView;
    UILabel *_titleLabel;
    UILabel *_usernameLabel;
    UIButton *_usernameLabelButton;
    UILabel *_dateLabel;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (!self) {
        return nil;
    }
    self.selectionStyle = UITableViewCellSelectionStyleGray;
    
    _avatarView = [UIImageView new];
    /*
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didClickAvatar:)];
    [_avatarView setUserInteractionEnabled:YES];
    [_avatarView addGestureRecognizer:tap];
    */
    CALayer *layer  = _avatarView.layer;
    [layer setMasksToBounds:YES];
    [layer setCornerRadius:3.0];

    [layer setBorderWidth:.7f];
    if ([Setting boolForKey:HPSettingNightMode]) {
        [layer setBorderColor:[rgb(100.f, 100.f, 100.f) CGColor]];
    } else {
        [layer setBorderColor:[rgb(205.f, 205.f, 205.f) CGColor]];
    }
    
    
    _titleLabel = [UILabel new];
    [_titleLabel setLineBreakMode:NSLineBreakByWordWrapping];
    [_titleLabel setNumberOfLines:0];
    
    _usernameLabel = [UILabel new];
    /*
    _usernameLabelButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_usernameLabelButton addTarget:self action:@selector(didClickAvatar:) forControlEvents:UIControlEventTouchUpInside];
    */
    _dateLabel = [UILabel new];
    
    [self.contentView addSubview:_avatarView];
    [self.contentView addSubview:_titleLabel];
    [self.contentView addSubview:_dateLabel];
    [self.contentView addSubview:_usernameLabel];
    //[self.contentView addSubview:_usernameLabelButton];
    
    return self;
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    // Configure the view for the selected state
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    [_avatarView cancelCurrentImageLoad];
    //[_avatarView setImage:[UIImage imageNamed:@"profile-image-placeholder.png"]];
    [_avatarView setImage:nil];
}


- (void)configure:(HPThread *)thread {
    _thread = thread;
    
    
    // subtitle
    //
    NSString *subtitle = [NSString stringWithFormat:@" %ld/%ld  %@",
                          _thread.replyCount,
                          _thread.openCount,
                          [thread shortDate]
                          ];
    
    NSMutableAttributedString *subAttrString =
    [[NSMutableAttributedString alloc] initWithString:subtitle];
    
    UIFont *subtitleFont = [UIFont systemFontOfSize:SUB_FONT_SIZE];
    [subAttrString setAttributes:@{
                                   NSForegroundColorAttributeName:[UIColor grayColor],
                                   NSFontAttributeName:subtitleFont}
                           range:NSMakeRange(0, [subtitle length])];
    
    // subtitle Alignment Right
    NSMutableParagraphStyle *paragrapStyle = [[NSMutableParagraphStyle alloc] init];
    paragrapStyle.alignment = NSTextAlignmentRight;
    
    [subAttrString addAttribute:NSParagraphStyleAttributeName value:paragrapStyle range:NSMakeRange(0, [subtitle length])];
    
    // replyCount red
    [subAttrString addAttribute:NSForegroundColorAttributeName value:[UIColor redColor] range:[subtitle rangeOfString:[NSString stringWithFormat:@" %ld", _thread.replyCount]]];
    
    
    // title
    //
    NSString *title = _thread.title;
    NSMutableAttributedString *attrString =
    [[NSMutableAttributedString alloc] initWithString:title];
    UIFont *baseFont = [UIFont systemFontOfSize:FONT_SIZE];
    [attrString addAttribute:NSFontAttributeName value:baseFont range:NSMakeRange(0, [title length])];
    
    

    // isRead && thread color
    if ([[HPCache sharedCache] isReadThread:thread.tid]) {
        [attrString addAttribute:NSForegroundColorAttributeName value:[HPTheme readColor] range:NSMakeRange(0, [title length])];
        
    } else {
        // thread color
        if (![_thread.titleColor isEqual:[NSNull null]]) {
            [attrString addAttribute:NSForegroundColorAttributeName value:_thread.titleColor range:NSMakeRange(0, [title length])];
        } else {
            [attrString addAttribute:NSForegroundColorAttributeName value:[HPTheme textColor] range:NSMakeRange(0, [title length])];
        }
    }
    
    
    // username
    //
    NSMutableAttributedString *userAttrString =
    [[NSMutableAttributedString alloc] initWithString:_thread.user.username];
    
    UIFont *userFont = [UIFont systemFontOfSize:SUB_FONT_SIZE];
    [userAttrString setAttributes:@{
                                    NSForegroundColorAttributeName:[UIColor grayColor],
                                    NSFontAttributeName:userFont}
                            range:NSMakeRange(0, [userAttrString length])];
    
    _titleLabel.attributedText = attrString;
    _dateLabel.attributedText = subAttrString;
    _usernameLabel.attributedText = userAttrString;
    
    if ([Setting boolForKey:HPSettingShowAvatar]) {
        [_avatarView setImageWithURL:thread.user.avatarImageURL
                    placeholderImage:/*[UIImage imageNamed:@"profile-image-placeholder.png"]*/nil
                             options:SDWebImageLowPriority];
        [_avatarView setHidden:NO];
        
    } else {
        [_avatarView setHidden:YES];
    }
    
    if ([Setting boolForKey:HPSettingNightMode]) {
        UIView *bgColorView = [[UIView alloc] init];
        bgColorView.backgroundColor = rgb(20.f, 20.f, 20.f);;
        [self setSelectedBackgroundView:bgColorView];
        
        
    } else {
        [self setSelectedBackgroundView:nil];
    }
     
    // 重新布局
    [self setNeedsLayout];
}

+ (CGFloat)titleHeight:(NSString *)title
                 width:(CGFloat)___width {
    
    // text
    //
    
    NSMutableAttributedString *attrString =
    [[NSMutableAttributedString alloc] initWithString:title];
    UIFont *baseFont = [UIFont systemFontOfSize:FONT_SIZE];
    [attrString addAttribute:NSFontAttributeName value:baseFont range:NSMakeRange(0, [title length])];
    
    
    // size
    //
    CGFloat width = 0.f;
    if ([Setting boolForKey:HPSettingShowAvatar]) {
        width = CELL_CONTENT_WIDTH - CELL_IMAGE_WIDTH - (CELL_CONTENT_MARGIN * 2) - CELL_IMAGE_MARGIN;
    } else {
        width = CELL_CONTENT_WIDTH - (CELL_CONTENT_MARGIN * 2);
    }
    
    CGSize constraint = CGSizeMake(width, 20000.0f);
    CGRect rect = [attrString boundingRectWithSize:constraint
                                           options:NSStringDrawingUsesLineFragmentOrigin
                                           context:nil];
    CGSize size = rect.size;
    
    return ceilf(size.height);
}

+ (CGFloat)heightForCellWithThread:(HPThread *)thread
                             width:(CGFloat)___width {
    
    // text
    //
    NSString *title = thread.title;
    CGFloat titleHeight = [[self class] titleHeight:title width:___width];
    
    
    CGFloat height = 0.f;
    if ([Setting boolForKey:HPSettingShowAvatar]) {
        height = MAX(titleHeight + CELL_SUB_HEIGHT + (CELL_CONTENT_MARGIN * 2.7), CELL_MIN_HEIGHT);
    } else {
        height = titleHeight + CELL_SUB_HEIGHT + (CELL_CONTENT_MARGIN * 3);
    }
    
    return ceilf(height);
}


#pragma mark - layoutSubviews

- (void)layoutSubviews {
    //NSLog(@"layoutSubviews");
    [super layoutSubviews];
    
    CGFloat ___width = self.contentView.frame.size.width;
    
    float image_width = 0.f, image_margin = 0.f;
   
    if ([Setting boolForKey:HPSettingShowAvatar]) {
        _avatarView.frame = CGRectMake(CELL_CONTENT_MARGIN, CELL_CONTENT_MARGIN, CELL_IMAGE_WIDTH, CELL_IMAGE_WIDTH);
        
        image_width = CELL_IMAGE_WIDTH;
        image_margin = CELL_IMAGE_MARGIN;
    }

    CGFloat titleHeight = [HPThreadCell titleHeight:_thread.title width:___width];
    
    CGFloat width = CELL_CONTENT_WIDTH - image_width - (CELL_CONTENT_MARGIN * 2) - image_margin;
    [_titleLabel setFrame:CGRectMake(CELL_CONTENT_MARGIN + image_width + image_margin ,  CELL_SUB_HEIGHT + CELL_CONTENT_MARGIN * 1.7 , width, titleHeight)];
    
    [_dateLabel setFrame:CGRectMake(CELL_CONTENT_MARGIN + image_width + image_margin , CELL_CONTENT_MARGIN, width, CELL_SUB_HEIGHT)];
    
    [_usernameLabel sizeToFit];
    [_usernameLabel setFrame:CGRectMake(CELL_CONTENT_MARGIN + image_width + image_margin,
                                        CELL_CONTENT_MARGIN,
                                        ceilf(fmin(_usernameLabel.frame.size.width, width/2)),
                                        CELL_SUB_HEIGHT)];
    
    //_usernameLabelButton.frame = CGRectInset(_usernameLabel.frame, -6.f, -6.f);
    
    _dateLabel.backgroundColor = self.contentView.backgroundColor;
    _titleLabel.backgroundColor = self.contentView.backgroundColor;
    _usernameLabel.backgroundColor = self.contentView.backgroundColor;
    
    // for debug 看边缘
    //_usernameLabel.backgroundColor = [UIColor yellowColor];
    //_titleLabel.backgroundColor = [UIColor yellowColor];
    //_dateLabel.backgroundColor = [UIColor cyanColor];
    //NSLog(@"_usernameLabel frame %@", NSStringFromCGRect(_usernameLabel.frame));
    //NSLog(@"_dateLabel frame %@", NSStringFromCGRect(_dateLabel.frame));
}

- (void)markRead {
    [_titleLabel setTextColor:[HPTheme readColor]];
}

- (UIView *)viewWithImageName:(NSString *)imageName {
    UIImage *image = [UIImage imageNamed:imageName];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
    imageView.contentMode = UIViewContentModeCenter;
    return imageView;
}

- (void)didClickAvatar:(id)sender {
    if (self.hp_delegate) {
        [self.hp_delegate didClickAvatar:self.thread.user];
    }
}

@end
