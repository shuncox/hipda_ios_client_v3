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

@interface HPSetImageSizeFilterView : UIView

@property (nonatomic, strong) UISwitch *autoLoadSwitch;

@property (nonatomic, strong) UISwitch *sizeFilterSwitch;
@property (nonatomic, strong) UISlider *filterValueSlider;

@property (nonatomic, strong) UISwitch *CDNSwitch;
@property (nonatomic, strong) UISlider *CDNfilterValueSlider;

@property (nonatomic, strong) UILabel *descLabel;

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
   
    // keys
    //
    NSString *AutoLoadEnableKey = keys[0];
    NSString *FilterEnableKey = keys[1];
    NSString *FilterMinValueKey = keys[2];
    NSString *CDNEnableKey = keys[3];
    NSString *CDNMinValueKey = keys[4];
    NSString *CDNOnlineEnableKey = keys[5];
    
    // views
    //
    UILabel *titleLabel = [UILabel new];
    titleLabel.font = [UIFont systemFontOfSize:22.f];
    titleLabel.text = [title stringByAppendingString:@"下 "];
    [self addSubview:titleLabel];
    
    UILabel *subTitleLabel = [UILabel new];
    subTitleLabel.font = [UIFont systemFontOfSize:14.f];
    [self addSubview:subTitleLabel];
    void (^updateSubTitleLabel)(BOOL on) = ^(BOOL on) {
        subTitleLabel.text = on ? @"图片自动载入" : @"图片不自动载入";
    };
    
    UILabel *filterTitleLabel = [UILabel new];
    filterTitleLabel.font = [UIFont systemFontOfSize:14.f];
    [self addSubview:filterTitleLabel];
    void (^updateFilterTipLabel)(BOOL on, float value) = ^(BOOL on, float value) {
        NSString *s = [@(value).stringValue imageSizeString];
        filterTitleLabel.text = [NSString stringWithFormat:@"图片尺寸超过 %@ 不自动载入", s];
        if (!on) filterTitleLabel.text = @"所有尺寸的图片都自动载入";
    };
    
    UILabel *CDNFilterTitleLabel = [UILabel new];
    CDNFilterTitleLabel.font = [UIFont systemFontOfSize:14.f];
    [self addSubview:CDNFilterTitleLabel];
    void (^updateCDNFilterTipLabel)(BOOL on, float value) = ^(BOOL on, float value) {
        NSString *s = [@(value).stringValue imageSizeString];
        CDNFilterTitleLabel.text = [NSString stringWithFormat:@"图片尺寸超过 %@ 使用CDN压缩", s];
        if (!on) CDNFilterTitleLabel.text = @"任何图片都不使用CDN加速";
    };
   
    @weakify(self);
    void (^updateUI)(BOOL, BOOL, BOOL) = ^(BOOL autoLoadSwitchOn, BOOL sizeFilterSwitchOn, BOOL CDNSwitchOn) {
        @strongify(self);
        if (autoLoadSwitchOn) {
            filterTitleLabel.hidden = NO;
            self.sizeFilterSwitch.hidden = NO;
            self.filterValueSlider.hidden = !sizeFilterSwitchOn;
            CDNFilterTitleLabel.hidden = !sizeFilterSwitchOn;
            self.CDNSwitch.hidden = !sizeFilterSwitchOn;
            self.CDNfilterValueSlider.hidden = !(CDNSwitchOn && sizeFilterSwitchOn);
            self.descLabel.hidden = self.CDNfilterValueSlider.hidden;
        } else {
            filterTitleLabel.hidden = YES;
            self.filterValueSlider.hidden = YES;
            self.sizeFilterSwitch.hidden = YES;
            CDNFilterTitleLabel.hidden = YES;
            self.CDNfilterValueSlider.hidden = YES;
            self.CDNSwitch.hidden = YES;
            self.descLabel.hidden = YES;
        }
        updateSubTitleLabel(autoLoadSwitchOn);
        updateFilterTipLabel(sizeFilterSwitchOn, self.filterValueSlider.value);
        updateCDNFilterTipLabel(CDNSwitchOn, self.CDNfilterValueSlider.value);
        
        if (![UMOnlineConfig getBoolConfigWithKey:CDNOnlineEnableKey defaultYES:YES]) {
            self.CDNSwitch.hidden = YES;
            self.CDNfilterValueSlider.hidden = YES;
            CDNFilterTitleLabel.hidden = YES;
            self.descLabel.hidden = YES;
        }
    };
 
    self.autoLoadSwitch = [UISwitch new];
    [self addSubview:self.autoLoadSwitch];
    [self.autoLoadSwitch handleControlEvents:UIControlEventValueChanged withBlock:^(UISwitch *weakSender) {
        [Setting saveInteger:weakSender.on forKey:AutoLoadEnableKey];
        @strongify(self);
        updateUI(self.autoLoadSwitch.on, self.sizeFilterSwitch.on, self.CDNSwitch.on);
    }];
    
    self.sizeFilterSwitch = [UISwitch new];
    [self addSubview:self.sizeFilterSwitch];
    [self.sizeFilterSwitch handleControlEvents:UIControlEventValueChanged withBlock:^(UISwitch *weakSender) {
        [Setting saveInteger:weakSender.on forKey:FilterEnableKey];
        @strongify(self);
        updateUI(self.autoLoadSwitch.on, self.sizeFilterSwitch.on, self.CDNSwitch.on);
    }];
    
    self.filterValueSlider = [UISlider new];
    [self addSubview:self.filterValueSlider];
    self.filterValueSlider.minimumValue = 0;
    self.filterValueSlider.maximumValue = 3 * 1024;
    self.filterValueSlider.continuous = YES;
    [self.filterValueSlider handleControlEvents:UIControlEventValueChanged withBlock:^(UISlider *weakSender) {
        @strongify(self);
        [Setting saveInteger:weakSender.value forKey:FilterMinValueKey];
        updateFilterTipLabel(self.sizeFilterSwitch.on, weakSender.value);
        if (self.CDNfilterValueSlider.value < weakSender.value) {
            self.CDNfilterValueSlider.value = weakSender.value;
            [self.CDNfilterValueSlider sendActionsForControlEvents:UIControlEventValueChanged];
        }
    }];
    
    self.CDNSwitch = [UISwitch new];
    [self addSubview:self.CDNSwitch];
    [self.CDNSwitch handleControlEvents:UIControlEventValueChanged withBlock:^(UISwitch *weakSender) {
        @strongify(self);
        /*
        if (![UMOnlineConfig getBoolConfigWithKey:CDNOnlineEnableKey defaultYES:YES]) {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"功能已下线" message:@"由于流量费用超标, 本功能暂时下线.\n未来可能作为收费项目, 大概1~3元一月." delegate:self cancelButtonTitle:nil otherButtonTitles:@"我愿意付费使用", @"我不愿意付费使用", @"下次再说",nil];
            [alertView showWithHandler:^(UIAlertView *alertView, NSInteger buttonIndex) {
                NSArray *list = @[@"ImageCDN_Pay_Yes", @"ImageCDN_Pay_No", @"ImageCDN_Pay_NotDecide"];
                [Flurry logEvent:list[buttonIndex % list.count]];
            }];
            [weakSender setOn:NO animated:YES];
            return;
        }*/
        [Setting saveInteger:weakSender.on forKey:CDNEnableKey];
        updateUI(self.autoLoadSwitch.on, self.sizeFilterSwitch.on, self.CDNSwitch.on);
    }];
    
    self.CDNfilterValueSlider = [UISlider new];
    [self addSubview:self.CDNfilterValueSlider];
    self.CDNfilterValueSlider.minimumValue = 0;
    self.CDNfilterValueSlider.maximumValue = 3 * 1024;
    self.CDNfilterValueSlider.continuous = YES;
    [self.CDNfilterValueSlider handleControlEvents:UIControlEventValueChanged withBlock:^(UISlider *weakSender) {
        @strongify(self);
        NSInteger minValue = [UMOnlineConfig getIntegerConfigWithKey:@"imageCDNMinValue" defaultValue:1024];
        minValue = MAX(self.filterValueSlider.value, minValue);
        if (weakSender.value < minValue) {
            [weakSender setValue:minValue animated:YES];
            return;
        }
        [Setting saveInteger:weakSender.value forKey:CDNMinValueKey];
        updateCDNFilterTipLabel(self.CDNSwitch.on, weakSender.value);
    }];
    
    UILabel *descLabel = [UILabel new];
    descLabel.text = @"通过CDN对图片进行压缩加速, 由于流量费用的缘故, 目前只对超大图片启用.\n"
    @"这个功能属于试验功能, 未来可能由于流量费用超标而下线.\n"
    @"此功能由七牛CDN强力驱动\n";
    descLabel.numberOfLines = 0;
    descLabel.font = [UIFont systemFontOfSize:12.f];
    descLabel.textColor = [UIColor grayColor];
    [self addSubview:descLabel];
    self.descLabel = descLabel;
   
    // constraints
    //
    [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self).offset(0);
        make.left.equalTo(self).offset(20);
    }];
    [subTitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(titleLabel.mas_right);
        make.bottom.equalTo(titleLabel);
    }];
    [self.autoLoadSwitch mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(subTitleLabel);
        make.right.equalTo(self).offset(-20);
    }];
    
    [filterTitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(titleLabel.mas_bottom).offset(30);
        make.left.equalTo(self).offset(20);
    }];
    
    [self.sizeFilterSwitch mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(filterTitleLabel);
        make.right.equalTo(self).offset(-20);
    }];
    
    [self.filterValueSlider mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.sizeFilterSwitch.mas_bottom).offset(10);
        make.left.equalTo(self).offset(20);
        make.right.equalTo(self).offset(-20);
    }];
    
    [CDNFilterTitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.filterValueSlider.mas_bottom).offset(20);
        make.left.equalTo(self).offset(20);
    }];
    
    [self.CDNSwitch mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(CDNFilterTitleLabel);
        make.right.equalTo(self).offset(-20);
    }];
    
    [self.CDNfilterValueSlider mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.CDNSwitch.mas_bottom).offset(10);
        make.left.equalTo(self).offset(20);
        make.right.equalTo(self).offset(-20);
    }];
    
    [descLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.CDNfilterValueSlider.mas_bottom).offset(10);
        make.left.equalTo(self).offset(20);
        make.right.equalTo(self).offset(-20);
        make.bottom.equalTo(self);
    }];
    
    // loadData
    //
    BOOL autoLoadEnable = [Setting boolForKey:AutoLoadEnableKey];
    
    BOOL imageSizeFilterEnable = [Setting boolForKey:FilterEnableKey];
    NSInteger imageSizeFilterMinValue = [Setting integerForKey:FilterMinValueKey];
    
    BOOL imageCDNEnable = [Setting boolForKey:CDNEnableKey];
    imageCDNEnable = [UMOnlineConfig getBoolConfigWithKey:CDNOnlineEnableKey defaultYES:imageCDNEnable];
    NSInteger imageCDNMinValue = [Setting integerForKey:CDNMinValueKey];
    imageCDNMinValue = MAX(imageCDNMinValue, [UMOnlineConfig getIntegerConfigWithKey:@"imageCDNMinValue" defaultValue:imageCDNMinValue]);
    
    self.autoLoadSwitch.on = autoLoadEnable;
    
    self.sizeFilterSwitch.on = imageSizeFilterEnable;
    [self.filterValueSlider setValue:imageSizeFilterMinValue animated:YES];
    
    self.CDNSwitch.on = imageCDNEnable;
    [self.CDNfilterValueSlider setValue:imageCDNMinValue animated:YES];
    
    updateUI(self.autoLoadSwitch.on, self.sizeFilterSwitch.on, self.CDNSwitch.on);
   
    
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
        HPSettingImageSizeFilterEnableWWAN,
        HPSettingImageSizeFilterMinValueWWAN,
        HPSettingImageCDNEnableWWAN,
        HPSettingImageCDNMinValueWWAN,
        HPOnlineImageCDNEnableWWAN,
    ]];
    
    self.wifiSettingView = [[HPSetImageSizeFilterView alloc] initWithTitle:@"Wifi网络" keys:@[
        HPSettingImageAutoLoadEnableWifi,
        HPSettingImageSizeFilterEnableWifi,
        HPSettingImageSizeFilterMinValueWifi,
        HPSettingImageCDNEnableWifi,
        HPSettingImageCDNMinValueWifi,
        HPOnlineImageCDNEnableWifi,
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
        @"imageSizeFilterMinValue_wwan": @(imageSizeFilterMinValue),
        @"imageCDNEnable_wwan": @(imageCDNEnable),
        @"imageCDNMinValue_wwan": @(imageCDNMinValue),
        
        @"autoLoadEnable_wifi": @(autoLoadEnable_wifi),
        @"imageSizeFilterEnable_wifi": @(imageSizeFilterEnable_wifi),
        @"imageSizeFilterMinValue_wifi": @(imageSizeFilterMinValue_wifi),
        @"imageCDNEnable_wifi": @(imageCDNEnable_wifi),
        @"imageCDNMinValue_wifi": @(imageCDNMinValue_wifi),
    };
    
    [Flurry logEvent:@"Setting_ImageLoad" withParameters:p];
}

@end
