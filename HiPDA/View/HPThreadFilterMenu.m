
//
//  HPThreadFilterMenu.m
//  HiPDA
//
//  Created by Jiangfan on 16/6/9.
//  Copyright © 2016年 wujichao. All rights reserved.
//

#import "HPThreadFilterMenu.h"
#import "HPForum.h"
#import "HPThreadFilterMenuItemView.h"
#import "HPSetting.h"

#define HP_FILTER_SETTING_KEY (@"HP_FILTER_SETTING_KEY")

@interface HPThreadFilterMenu()

@property (nonatomic, strong) HPThreadFilterMenuItemView *typeSelectView;
@property (nonatomic, strong) HPThreadFilterMenuItemView *filterSelectView;
@property (nonatomic, strong) HPThreadFilterMenuItemView *scopeSelectView;
@property (nonatomic, strong) HPThreadFilterMenuItemView *orderSelectView;

@property (nonatomic, strong) NSMutableDictionary *draftFilter;
@property (nonatomic, assign) NSInteger fid;

@end

@implementation HPThreadFilterMenu

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        self.backgroundColor = [UIColor colorWithRed:248/255.f green:248/255.f blue:248/255.f alpha:1];
        
        _currentFilter = @{};
        _draftFilter = [@{} mutableCopy];
        
        _typeSelectView = [HPThreadFilterMenuItemView new];
        _typeSelectView.segmentedControl.apportionsSegmentWidthsByContent = YES;
        _filterSelectView = [HPThreadFilterMenuItemView new];
        _scopeSelectView = [HPThreadFilterMenuItemView new];
        _orderSelectView = [HPThreadFilterMenuItemView new];

        NSArray *views = @[self.typeSelectView, self.filterSelectView, self.scopeSelectView, self.orderSelectView];
        NSArray *titles = @[@"分类", @"过滤", @"范围", @"排序"];
        [views enumerateObjectsUsingBlock:^(HPThreadFilterMenuItemView *v, NSUInteger idx, BOOL *stop) {
            [self addSubview:v];
            v.title = titles[idx];
        }];
        
        self.filterSelectView.items = @[@"全部", @"精华"];
        self.filterSelectView.values = @[@"", @"digest"];
        
        self.scopeSelectView.items = @[@"一天", @"两天", @"周", @"月", @"季"];
        self.scopeSelectView.values = @[@"86400", @"172800", @"604800", @"2592000", @"7948800"];
        
        self.orderSelectView.items = @[@"热门", @"发帖🕝", @"回复数", @"查看数", @"回帖🕝"];
        self.orderSelectView.values = @[@"heats", @"dateline", @"replies", @"views", @"lastpost"];
        
        NSArray *filterViews = @[self.typeSelectView, self.filterSelectView, self.scopeSelectView];
        @weakify(self);
        void (^didSelectFilter)(HPThreadFilterMenuItemView *view, NSString *value) =
        ^(HPThreadFilterMenuItemView *view, NSString *value) {
            @strongify(self);
            for (HPThreadFilterMenuItemView *v in filterViews) {
                if (v != view) {
                    [v deselect];
                }
            }
            self.draftFilter[@"filter"] = value;
        };
        for (HPThreadFilterMenuItemView *v in filterViews) {
            v.didSelect = didSelectFilter;
        }
        
        void (^didSelectOrder)(HPThreadFilterMenuItemView *view, NSString *value) =
        ^(HPThreadFilterMenuItemView *view, NSString *value) {
            self.draftFilter[@"orderby"] = value;
        };
        self.orderSelectView.didSelect = didSelectOrder;
        
        UIButton *resetButton = [UIButton new];
        resetButton.layer.cornerRadius = 5;
        resetButton.layer.borderWidth = 1;
        resetButton.layer.borderColor = [UIColor blackColor].CGColor;
        [resetButton setTitle:@"重置" forState:UIControlStateNormal];
        [resetButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        resetButton.titleLabel.font = [UIFont systemFontOfSize:15];
        [resetButton addTarget:self action:@selector(didTapResetButton:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:resetButton];
        
        UIButton *submitButton = [UIButton new];
        submitButton.layer.cornerRadius = 5;
        submitButton.layer.borderWidth = 1;
        submitButton.layer.borderColor = [UIColor blackColor].CGColor;
        [submitButton setTitle:@"确定" forState:UIControlStateNormal];
        [submitButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        submitButton.titleLabel.font = [UIFont systemFontOfSize:15];
        [submitButton addTarget:self action:@selector(didTapSubmitButton:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:submitButton];
        
        // layout
        //
        CGFloat margin = 15.f;
        [self.typeSelectView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self).offset(15.f);
            make.left.equalTo(self).offset(margin);
            make.right.equalTo(self).offset(-margin);
        }];
        [self.filterSelectView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.typeSelectView.mas_bottom).offset(10.f);
            make.left.equalTo(self).offset(margin);
            make.right.equalTo(self).offset(-margin);
        }];
        [self.scopeSelectView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.filterSelectView.mas_bottom).offset(10.f);
            make.left.equalTo(self).offset(margin);
            make.right.equalTo(self).offset(-margin);
        }];
        
        UIView *separator = [UIView new];
        separator.backgroundColor = [UIColor lightGrayColor];
        [self addSubview:separator];
        [separator mas_makeConstraints:^(MASConstraintMaker *make) {
            make.height.equalTo(@HP_1PX);
            make.left.equalTo(self).offset(margin);
            make.right.equalTo(self).offset(-margin);
            make.top.equalTo(self.scopeSelectView.mas_bottom).offset(10);
        }];
        
        [self.orderSelectView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.scopeSelectView.mas_bottom).offset(20.f);
            make.left.equalTo(self).offset(margin);
            make.right.equalTo(self).offset(-margin);
        }];
        
        UIView *separator2= [UIView new];
        separator2.backgroundColor = [UIColor lightGrayColor];
        [self addSubview:separator2];
        [separator2 mas_makeConstraints:^(MASConstraintMaker *make) {
            make.height.equalTo(@HP_1PX);
            make.left.equalTo(self).offset(margin);
            make.right.equalTo(self).offset(-margin);
            make.top.equalTo(self.orderSelectView.mas_bottom).offset(10);
        }];
        
        [resetButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.orderSelectView.mas_bottom).offset(20);
            make.left.equalTo(self).offset(15);
        }];
        [submitButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(resetButton);
            make.width.equalTo(resetButton);
            make.left.equalTo(resetButton.mas_right).offset(15);
            make.right.equalTo(self).offset(-15);
        }];
    }
    return self;
}

- (void)updateWithFid:(NSInteger)fid
{
    self.fid = fid;
    
    // types
    //
    NSArray *types = [HPForum forumTypeWithFid:fid];
    
    if (types) {
        // 去掉第一个, 第一个是默认
        types = [types subarrayWithRange:NSMakeRange(1, types.count-1)];
    } else {
        types = @[@{@"key": @"无分类", @"value": @""}];
    }
    
    NSMutableArray *items = [@[] mutableCopy];
    NSMutableArray *values = [@[] mutableCopy];
    for (NSDictionary *d in types) {
        [items addObject:d[@"key"]];
        [values addObject:[NSString stringWithFormat:@"type&typeid=%@", d[@"value"]]];
    }
    
    self.typeSelectView.items = [items copy];
    self.typeSelectView.values = [values copy];
    
    // load config
    //
    [self loadConfig];
}

- (void)setCurrentFilter:(NSDictionary *)currentFilter
{
    _currentFilter = currentFilter;
    self.draftFilter = [currentFilter mutableCopy];
    
    NSString *filter = currentFilter[@"filter"];
    NSString *orderby = currentFilter[@"orderby"];
    
    NSArray *filterViews = @[self.typeSelectView, self.filterSelectView, self.scopeSelectView];
    for (HPThreadFilterMenuItemView *v in filterViews) {
        [v tryToSetSelectedValue:filter];
    }
    [self.orderSelectView tryToSetSelectedValue:orderby];
}

- (void)didTapResetButton:(UIButton *)button
{
    self.currentFilter = @{@"orderby": @"lastpost", @"filter": @""};
    [self saveConfig];
}

- (void)didTapSubmitButton:(UIButton *)button
{
    self.currentFilter = [self.draftFilter copy];
    [self saveConfig];
    self.submitBlock();
}

#pragma mark - persistence
- (void)loadConfig
{
    NSDictionary *settings = [NSStandardUserDefaults objectForKey:HP_FILTER_SETTING_KEY];
    if (!settings) {
        [NSStandardUserDefaults setObject:@{} forKey:HP_FILTER_SETTING_KEY];
    }
    NSDictionary *config = [settings objectForKey:@(self.fid).stringValue];
    if (!config) {
        config = @{@"orderby": @"lastpost", @"filter": @""};
        if (self.fid == 6 && [Setting boolForKey:HPSettingBSForumOrderByDate]) {
            config = @{@"orderby": @"dateline", @"filter": @""}; //兼容旧版
        }
    }
    
    self.currentFilter = config;
}

- (void)saveConfig
{
    NSDictionary *settings = [NSStandardUserDefaults objectForKey:HP_FILTER_SETTING_KEY];
    NSMutableDictionary *update = [settings mutableCopy];
    [update setObject:self.currentFilter forKey:@(self.fid).stringValue];
    [NSStandardUserDefaults saveObject:[update copy] forKey:HP_FILTER_SETTING_KEY];
}

@end
