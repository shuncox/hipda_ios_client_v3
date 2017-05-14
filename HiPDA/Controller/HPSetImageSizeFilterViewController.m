//
//  HPSetImageSizeFilterViewController.m
//  HiPDA
//
//  Created by Jiangfan on 16/3/28.
//  Copyright © 2016年 wujichao. All rights reserved.
//

#import "HPSetImageSizeFilterViewController.h"
#import "HPSetting.h"
#import "UIControl+ALActionBlocks.h"
#import "NSString+HPImageSize.h"
#import "UIAlertView+Blocks.h"
#import <BlocksKit/NSObject+BKBlockObservation.h>
#import <Mantle/EXTKeyPathCoding.h>
#import <BlocksKit/UIControl+BlocksKit.h>

@interface HPSetImageSizeFilterView : UIView

@property (nonatomic, strong) UISegmentedControl *loadModeControl;
@property (nonatomic, strong) UISegmentedControl *autoLoadModeControl;
@property (nonatomic, strong) UISlider *autoLoadThresholdSlider;
@property (nonatomic, strong) UILabel *descLabel;

@property (nonatomic, assign) BOOL autoLoad;
@property (nonatomic, assign) HPImageAutoLoadMode autoLoadMode;
@property (nonatomic, assign) CGFloat autoLoadThreshold;

@end

@implementation HPSetImageSizeFilterView
- (void)dealloc
{
    
}

- (instancetype)initWithTitle:(NSString *)title
                         keys:(NSArray *)keys
{
    self = [super initWithFrame:CGRectZero];
    if (!self) return nil;
   
    @weakify(self);
    
    // keys
    //
    NSString *AutoLoadEnableKey = keys[0];
    NSString *AutoLoadModeKey = keys[1];
    NSString *AutoLoadThresholdKey = keys[2];
    
    // views
    //
    UILabel *titleLabel = [UILabel new];
    titleLabel.font = [UIFont systemFontOfSize:22.f];
    titleLabel.text = [title stringByAppendingString:@"下 "];
    [self addSubview:titleLabel];
    
    
    UISegmentedControl *loadModeControl = [[UISegmentedControl alloc] initWithItems:@[@"图片自动加载", @"图片手动加载"]];
    self.loadModeControl = loadModeControl;
    [self addSubview:loadModeControl];
    [loadModeControl bk_addEventHandler:^(UISegmentedControl *control) {
        @strongify(self);
        self.autoLoad = control.selectedSegmentIndex == 0;
    } forControlEvents:UIControlEventValueChanged];
    
    
    UISegmentedControl *autoLoadModeControl = [[UISegmentedControl alloc] initWithItems:@[@"优先加载原图", @"优先加载缩略图", @"智能模式"]];
    self.autoLoadModeControl = autoLoadModeControl;
    [self addSubview:autoLoadModeControl];
    [autoLoadModeControl bk_addEventHandler:^(UISegmentedControl *control) {
        @strongify(self);
        self.autoLoadMode = control.selectedSegmentIndex;
    } forControlEvents:UIControlEventValueChanged];
    
    
    UISlider *slider = [UISlider new];
    self.autoLoadThresholdSlider = slider;
    [self addSubview:slider];
    
    slider.minimumValue = 0;
    slider.maximumValue = 3 * 1000;
    slider.continuous = YES;
    
    [slider handleControlEvents:UIControlEventValueChanged withBlock:^(UISlider *weakSender) {
        @strongify(self);
        self.autoLoadThreshold = round(weakSender.value / 100) * 100;
    }];
    
    UILabel *descLabel = [UILabel new];
    self.descLabel = descLabel;
    [self addSubview:descLabel];
    
    descLabel.numberOfLines = 0;
    descLabel.font = [UIFont systemFontOfSize:14.f];
    descLabel.textColor = [UIColor blackColor];

    
    // constraints
    //
    [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self).offset(0);
        make.left.equalTo(self).offset(20.f);
        make.right.equalTo(self).offset(-20.f);
    }];
    [loadModeControl mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(titleLabel.mas_bottom).offset(20.f);
        make.left.right.equalTo(titleLabel);
    }];
    
    [autoLoadModeControl mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(loadModeControl.mas_bottom).offset(20.f);
        make.left.right.equalTo(titleLabel);
    }];
    
    [slider mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(autoLoadModeControl.mas_bottom).offset(20.f);
        make.left.right.equalTo(titleLabel);
    }];
    
    [descLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(slider.mas_bottom).offset(10.f);
        make.left.right.equalTo(titleLabel);
        make.bottom.equalTo(self).offset(-20);
    }];
    
    
    // bindings
    //
    [self bk_addObserverForKeyPath:@keypath(self, autoLoad) task:^(id target) {
        @strongify(self);
        [Setting saveInteger:self.autoLoad forKey:AutoLoadEnableKey];
        self.loadModeControl.selectedSegmentIndex = self.autoLoad ? 0 : 1;
    }];
    
    [self bk_addObserverForKeyPath:@keypath(self, autoLoadMode) task:^(id target) {
        @strongify(self);
        [Setting saveInteger:self.autoLoadMode forKey:AutoLoadModeKey];
        self.autoLoadModeControl.selectedSegmentIndex = self.autoLoadMode;
        self.autoLoadThresholdSlider.hidden = self.autoLoadMode != HPImageAutoLoadModePerferAuto;
    }];
    
    [self bk_addObserverForKeyPath:@keypath(self, autoLoadThreshold) task:^(id target) {
        @strongify(self);
        [Setting saveFloat:self.autoLoadThreshold forKey:AutoLoadThresholdKey];
        self.autoLoadThresholdSlider.value = self.autoLoadThreshold;
    }];
    
    [self bk_addObserverForKeyPaths:@[
        @keypath(self, autoLoad),
        @keypath(self, autoLoadMode),
        @keypath(self, autoLoadThreshold)
    ] task:^(id obj, NSString *keyPath) {
        
        NSString *text = nil;
        if (self.autoLoad) {
            text = [NSString stringWithFormat:@"%@下, 帖子中的图片会自动载入. ", title];
        } else {
            text = [NSString stringWithFormat:@"%@下, 帖子中的图片不自动载入, 手动点击后", title];
        }
        
        NSString *loadModeText = nil;
        switch (self.autoLoadMode) {
            case HPImageAutoLoadModePerferAuto:
                loadModeText = [NSString stringWithFormat:@"\n图片大小超过 %.1fMB 优先加载缩略图, 否则优先载入原图", self.autoLoadThreshold / 1000];
                break;
            case HPImageAutoLoadModePerferThumb:
                loadModeText = @"将会优先载入缩略图.";
                break;
            case HPImageAutoLoadModePerferOriginal:
                loadModeText = @"将会优先载入原图.";
                break;
        }
        
        self.descLabel.text = [NSString stringWithFormat:@"%@%@", text, loadModeText];
    }];
    
    
    // load settings
    //
    self.autoLoad = [Setting boolForKey:AutoLoadEnableKey];
    self.autoLoadMode = [Setting integerForKey:AutoLoadModeKey];
    self.autoLoadThreshold = [Setting floatForKey:AutoLoadThresholdKey];
    
    return self;
}

@end

@interface HPSetImageSizeFilterViewController ()

@property (nonatomic, strong) HPSetImageSizeFilterView *wwanSettingView;
@property (nonatomic, strong) HPSetImageSizeFilterView *wifiSettingView;

@end

@implementation HPSetImageSizeFilterViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    self.title = @"图片加载设置";
    
    self.wwanSettingView = [[HPSetImageSizeFilterView alloc] initWithTitle:@"移动网络" keys:@[
        HPSettingImageAutoLoadEnableWWAN,
        HPSettingImageAutoLoadModeWWAN,
        HPSettingImageAutoLoadModeAutoThresholdWWAN,
    ]];
    
    self.wifiSettingView = [[HPSetImageSizeFilterView alloc] initWithTitle:@"Wifi网络" keys:@[
        HPSettingImageAutoLoadEnableWifi,
        HPSettingImageAutoLoadModeWifi,
        HPSettingImageAutoLoadModeAutoThresholdWifi,
    ]];
    
    [self.view addSubview:self.wwanSettingView];
    [self.view addSubview:self.wifiSettingView];
    UIView *separator = [UIView new];
    separator.backgroundColor = [UIColor blackColor];
    [self.view addSubview:separator];
    
    [self.wwanSettingView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.view);
        make.top.equalTo(self.view).offset(64.f + 20);
    }];
    [separator mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.view);
        make.height.equalTo(@(1));
        make.top.equalTo(self.wwanSettingView.mas_bottom).offset(0);
    }];
    [self.wifiSettingView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.view);
        make.top.equalTo(separator.mas_bottom).offset(15);
    }];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    /*
    BOOL autoLoadEnable = [Setting boolForKey:HPSettingImageAutoLoadEnableWWAN];
    BOOL imageSizeFilterEnable = [Setting boolForKey:HPSettingImageSizeFilterEnableWWAN];
    NSInteger imageSizeFilterMinValue = [Setting integerForKey:HPSettingImageSizeFilterMinValueWWAN];
    BOOL imageCDNEnable = [Setting boolForKey:HPSettingImageCDNEnableWWAN];
    NSInteger imageCDNMinValue = [Setting integerForKey:HPSettingImageCDNMinValueWWAN];
   
    BOOL autoLoadEnable_wifi = [Setting boolForKey:HPSettingImageAutoLoadEnableWifi];
    BOOL imageSizeFilterEnable_wifi = [Setting boolForKey:HPSettingImageSizeFilterEnableWifi];
    NSInteger imageSizeFilterMinValue_wifi = [Setting integerForKey:HPSettingImageSizeFilterMinValueWifi];
    BOOL imageCDNEnable_wifi = [Setting boolForKey:HPSettingImageCDNEnableWifi];
    NSInteger imageCDNMinValue_wifi = [Setting integerForKey:HPSettingImageCDNMinValueWifi];
    
    NSDictionary *p = @{
        @"autoLoadEnable_wwan": @(autoLoadEnable),
        @"imageSizeFilterEnable_wwan": @(imageSizeFilterEnable),
        @"imageSizeFilterMinValue_wwan": @(imageSizeFilterMinValue/100*100),//按百分段
        @"imageCDNEnable_wwan": @(imageCDNEnable),
        @"imageCDNMinValue_wwan": @(imageCDNMinValue/100*100),
        
        @"autoLoadEnable_wifi": @(autoLoadEnable_wifi),
        @"imageSizeFilterEnable_wifi": @(imageSizeFilterEnable_wifi),
        @"imageSizeFilterMinValue_wifi": @(imageSizeFilterMinValue_wifi/100*100),
        @"imageCDNEnable_wifi": @(imageCDNEnable_wifi),
        @"imageCDNMinValue_wifi": @(imageCDNMinValue_wifi/100*100),
    };
    
    [Flurry logEvent:@"Setting_ImageLoad" withParameters:p];
    */
}

@end
