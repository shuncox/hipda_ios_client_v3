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

@interface HPSetImageSizeFilterViewController ()

@property (nonatomic, strong) UISwitch *sizeFilterSwitch;
@property (nonatomic, strong) UISlider *filterValueSlider;

@property (nonatomic, strong) UISwitch *CDNSwitch;
@property (nonatomic, strong) UISlider *CDNfilterValueSlider;

@end

@implementation HPSetImageSizeFilterViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    self.title = @"大图手动加载";
    
    UILabel *filterTitleLabel = [UILabel new];
    filterTitleLabel.font = [UIFont systemFontOfSize:14.f];
    [self.view addSubview:filterTitleLabel];
    void (^updateFilterTipLabel)(float value) = ^(float value) {
        NSString *s = [@(value).stringValue imageSizeString];
        filterTitleLabel.text = [NSString stringWithFormat:@"图片尺寸超过 %@ 不自动载入", s];
    };
    
    UILabel *CDNFilterTitleLabel = [UILabel new];
    CDNFilterTitleLabel.font = [UIFont systemFontOfSize:14.f];
    [self.view addSubview:CDNFilterTitleLabel];
    void (^updateCDNFilterTipLabel)(float value) = ^(float value) {
        NSString *s = [@(value).stringValue imageSizeString];
        CDNFilterTitleLabel.text = [NSString stringWithFormat:@"图片尺寸超过 %@ 使用CDN压缩", s];
    };
    
    @weakify(self);
    void (^updateUI)(BOOL, BOOL) = ^(BOOL sizeFilterSwitchOn, BOOL CDNSwitchOn) {
        @strongify(self);
        self.filterValueSlider.hidden = !sizeFilterSwitchOn;
        self.CDNSwitch.hidden = !sizeFilterSwitchOn;
        self.CDNfilterValueSlider.hidden = !sizeFilterSwitchOn || !CDNSwitchOn;
        CDNFilterTitleLabel.hidden = !sizeFilterSwitchOn;
    };
    
    self.sizeFilterSwitch = [UISwitch new];
    [self.view addSubview:self.sizeFilterSwitch];
    [self.sizeFilterSwitch handleControlEvents:UIControlEventValueChanged withBlock:^(UISwitch *weakSender) {
        [Setting saveInteger:weakSender.on forKey:HPSettingImageSizeFilterEnable];
        @strongify(self);
        updateUI(self.sizeFilterSwitch.on, self.CDNSwitch.on);
    }];
    
    self.filterValueSlider = [UISlider new];
    [self.view addSubview:self.filterValueSlider];
    self.filterValueSlider.minimumValue = 0;
    self.filterValueSlider.maximumValue = 3000;
    self.filterValueSlider.continuous = YES;
    [self.filterValueSlider handleControlEvents:UIControlEventValueChanged withBlock:^(UISlider *weakSender) {
        [Setting saveInteger:weakSender.value forKey:HPSettingImageSizeFilterMinValue];
        updateFilterTipLabel(weakSender.value);
    }];
    
    self.CDNSwitch = [UISwitch new];
    [self.view addSubview:self.CDNSwitch];
    [self.CDNSwitch handleControlEvents:UIControlEventValueChanged withBlock:^(UISwitch *weakSender) {
        if (![UMOnlineConfig getBoolConfigWithKey:@"imageCDNEnable" defaultYES:YES]) {
            [weakSender setOn:NO animated:YES];
            return;
        }
        [Setting saveInteger:weakSender.on forKey:HPSettingImageCDNEnable];
        @strongify(self);
        updateUI(self.sizeFilterSwitch.on, self.CDNSwitch.on);
    }];
    
    self.CDNfilterValueSlider = [UISlider new];
    [self.view addSubview:self.CDNfilterValueSlider];
    self.CDNfilterValueSlider.minimumValue = 0;
    self.CDNfilterValueSlider.maximumValue = 3000;
    self.CDNfilterValueSlider.continuous = YES;
    [self.CDNfilterValueSlider handleControlEvents:UIControlEventValueChanged withBlock:^(UISlider *weakSender) {
        @strongify(self);
        NSInteger minValue = [UMOnlineConfig getIntegerConfigWithKey:@"imageCDNMinValue" defaultValue:1024];
        minValue = MAX(self.filterValueSlider.value, minValue);
        if (weakSender.value < minValue) {
            [weakSender setValue:minValue animated:YES];
            return;
        }
        [Setting saveInteger:weakSender.value forKey:HPSettingImageCDNMinValue];
        updateCDNFilterTipLabel(weakSender.value);
    }];
    
    // constraints
    //
    [filterTitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view).offset(100);
        make.left.equalTo(self.view).offset(20);
    }];
    
    [self.sizeFilterSwitch mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(filterTitleLabel);
        make.right.equalTo(self.view).offset(-20);
    }];
    
    [self.filterValueSlider mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.sizeFilterSwitch.mas_bottom).offset(10);
        make.left.equalTo(self.view).offset(20);
        make.right.equalTo(self.view).offset(-20);
    }];
    
    [CDNFilterTitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.filterValueSlider.mas_bottom).offset(40);
        make.left.equalTo(self.view).offset(20);
    }];
    
    [self.CDNSwitch mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(CDNFilterTitleLabel);
        make.right.equalTo(self.view).offset(-20);
    }];
    
    [self.CDNfilterValueSlider mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.CDNSwitch.mas_bottom).offset(10);
        make.left.equalTo(self.view).offset(20);
        make.right.equalTo(self.view).offset(-20);
    }];
    
    // loadData
    //
    BOOL imageSizeFilterEnable = [Setting boolForKey:HPSettingImageSizeFilterEnable];
    NSInteger imageSizeFilterMinValue = [Setting integerForKey:HPSettingImageSizeFilterMinValue];
    
    BOOL imageCDNEnable = [Setting boolForKey:HPSettingImageCDNEnable];
    imageCDNEnable = [UMOnlineConfig getBoolConfigWithKey:@"imageCDNEnable" defaultYES:imageCDNEnable];
    NSInteger imageCDNMinValue = [Setting integerForKey:HPSettingImageCDNMinValue];
    imageCDNMinValue = MAX(imageCDNMinValue, [UMOnlineConfig getIntegerConfigWithKey:@"imageCDNMinValue" defaultValue:imageCDNMinValue]);
    
    updateFilterTipLabel(imageSizeFilterMinValue);
    self.sizeFilterSwitch.on = imageSizeFilterEnable;
    [self.filterValueSlider setValue:imageSizeFilterMinValue animated:YES];
    
    updateCDNFilterTipLabel(imageCDNMinValue);
    self.CDNSwitch.on = imageCDNEnable;
    [self.CDNfilterValueSlider setValue:imageCDNMinValue animated:YES];
    
    updateUI(self.sizeFilterSwitch.on, self.CDNSwitch.on);
}

@end
