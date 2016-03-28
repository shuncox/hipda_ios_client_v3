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
    
    self.sizeFilterSwitch = [UISwitch new];
    [self.view addSubview:self.sizeFilterSwitch];
    [self.sizeFilterSwitch handleControlEvents:UIControlEventValueChanged withBlock:^(UISwitch *weakSender) {
        [Setting saveInteger:weakSender.on forKey:HPSettingImageSizeFilterEnable];
    }];
    
    self.filterValueSlider = [UISlider new];
    [self.view addSubview:self.filterValueSlider];
    self.filterValueSlider.minimumValue = 0;
    self.filterValueSlider.maximumValue = 2000;
    self.filterValueSlider.continuous = YES;
    [self.filterValueSlider handleControlEvents:UIControlEventValueChanged withBlock:^(UISlider *weakSender) {
        [Setting saveInteger:weakSender.value forKey:HPSettingImageSizeFilterMinValue];
    }];
    
    self.CDNSwitch = [UISwitch new];
    [self.view addSubview:self.CDNSwitch];
    [self.CDNSwitch handleControlEvents:UIControlEventValueChanged withBlock:^(UISwitch *weakSender) {
        if (![UMOnlineConfig getBoolConfigWithKey:@"imageCDNEnable" defaultYES:YES]) {
            weakSender.on = NO;
            return;
        }
        [Setting saveInteger:weakSender.on forKey:HPSettingImageCDNEnable];
    }];
    
    self.CDNfilterValueSlider = [UISlider new];
    [self.view addSubview:self.CDNfilterValueSlider];
    self.CDNfilterValueSlider.minimumValue = 0;
    self.CDNfilterValueSlider.maximumValue = 2000;
    self.CDNfilterValueSlider.continuous = YES;
    [self.CDNfilterValueSlider handleControlEvents:UIControlEventValueChanged withBlock:^(UISlider *weakSender) {
        if ([UMOnlineConfig hasConfigForKey:@"imageCDNMinValue"]) {
            NSInteger minValue = [UMOnlineConfig getIntegerConfigWithKey:@"imageCDNMinValue" defaultValue:0];
            if (weakSender.value < minValue) {
                weakSender.value = minValue;
            }
            return;
        }
        [Setting saveInteger:weakSender.value forKey:HPSettingImageCDNMinValue];
    }];
    
    // constraints
    //
    [self.sizeFilterSwitch mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view).offset(100);
        make.centerX.equalTo(self.view);
    }];
    
    [self.filterValueSlider mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.sizeFilterSwitch.mas_bottom).offset(10);
        make.left.right.equalTo(self.view);
    }];
    
    [self.CDNSwitch mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.filterValueSlider.mas_bottom).offset(40);
        make.centerX.equalTo(self.view);
    }];
    
    [self.CDNfilterValueSlider mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.CDNSwitch.mas_bottom).offset(10);
        make.left.right.equalTo(self.view);
    }];
    
    // loadData
    //
    BOOL imageSizeFilterEnable = [Setting boolForKey:HPSettingImageSizeFilterEnable];
    NSInteger imageSizeFilterMinValue = [Setting integerForKey:HPSettingImageSizeFilterMinValue];
    
    BOOL imageCDNEnable = [Setting boolForKey:HPSettingImageCDNEnable];
    imageCDNEnable = [UMOnlineConfig getBoolConfigWithKey:@"imageCDNEnable" defaultYES:imageCDNEnable];
    NSInteger imageCDNMinValue = [Setting integerForKey:HPSettingImageCDNMinValue];
    imageCDNMinValue = MIN(imageCDNMinValue, [UMOnlineConfig getIntegerConfigWithKey:@"imageCDNMinValue" defaultValue:imageCDNMinValue]);
    
    self.sizeFilterSwitch.on = imageSizeFilterEnable;
    [self.filterValueSlider setValue:imageSizeFilterMinValue animated:YES];
    
    self.CDNSwitch.on = imageCDNEnable;
    [self.CDNfilterValueSlider setValue:imageCDNMinValue animated:YES];
}

@end
