//
// Created by Jiangfan on 2018/12/30.
// Copyright (c) 2018 wujichao. All rights reserved.
//

#import "HPQMUIImagePickerViewController.h"

@implementation HPQMUIImagePickerViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.sendButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self.previewButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self.sendButton setTitle:@"确认" forState:UIControlStateNormal];

    [self addCompressSizeSelector];
}

- (void)addCompressSizeSelector
{
    UIView *container = [UIView new];
//    container.qmui_shouldShowDebugColor = YES;
    [self.operationToolBarView addSubview:container];
    [container mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.operationToolBarView);
    }];

    UILabel *label = [UILabel new];
    label.text = @"大小:";
    label.font = [UIFont systemFontOfSize:14.f];
    label.textColor = [UIColor blackColor];
    [container addSubview:label];
    [label mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(container);
        make.centerY.equalTo(container);
    }];

    UISegmentedControl *segmentControl = [[UISegmentedControl alloc]initWithItems:@[@"~200kb",@"~400kb", @"~600kb"]];
    [segmentControl addTarget:self action:@selector(segmentedControlValueDidChange:) forControlEvents:UIControlEventValueChanged];
    [segmentControl setSelectedSegmentIndex:1];
    [container addSubview:segmentControl];
    [segmentControl mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(label.mas_right).offset(4);
        make.top.right.bottom.equalTo(container);
    }];

    [self segmentedControlValueDidChange:segmentControl];
}

- (void)handleSendButtonClick:(id)sender
{
    if (self.imagePickerViewControllerDelegate && [self.imagePickerViewControllerDelegate respondsToSelector:@selector(imagePickerViewController:didFinishPickingImageWithImagesAssetArray:)]) {
        [self.imagePickerViewControllerDelegate imagePickerViewController:self didFinishPickingImageWithImagesAssetArray:self.selectedImageAssetArray];
    }
}


-(void)segmentedControlValueDidChange:(UISegmentedControl *)segment
{
    NSLog(@"segment.selectedSegmentIndex %d", segment.selectedSegmentIndex);
    switch (segment.selectedSegmentIndex) {
        case 0:
        {
            _targetSize = 600.f;
            break;
        }
        case 1:
        {
            _targetSize = 800.f;
            break;
        }
        case 2:
        {
            _targetSize = 1000.f;
            break;
        }
        default:
        {
            _targetSize = 600.f;
            break;
        }
    }
}

@end