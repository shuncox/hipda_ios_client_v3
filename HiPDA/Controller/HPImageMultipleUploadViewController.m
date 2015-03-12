//
//  HPImageMultipleUploadViewController.m
//  HiPDA
//
//  Created by Jichao Wu on 15-1-5.
//  Copyright (c) 2015年 wujichao. All rights reserved.
//

#import "HPImageMultipleUploadViewController.h"

#import <CTAssetsPickerController.h>
#import <CTAssetsPageViewController.h>

#import "HPAccount.h"
#import <QuartzCore/QuartzCore.h>
#import <SVProgressHUD.h>
#import "HPSendPost.h"
#import "HPTheme.h"
#import "HPSetting.h"

#import "UIImage+Resize.h"
#import "UIImage+fixOrientation.h"

@interface HPImageMultipleUploadViewController () <UINavigationControllerDelegate, UIImagePickerControllerDelegate, UIPopoverControllerDelegate, UITableViewDataSource, UITableViewDelegate, CTAssetsPickerControllerDelegate, UIPopoverControllerDelegate>

@property (nonatomic, strong)NSMutableArray *assets;
@property (nonatomic, strong)UIPopoverController *popover;
@property (nonatomic, strong)UITableView *tableView;

@property (nonatomic, assign)CGFloat targetSize;

@end

@implementation HPImageMultipleUploadViewController

- (id)init {
    
    self = [super init];
    if (self) {
        _targetSize = 600.f;
        _assets = [[NSMutableArray alloc] init];
    }
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"上传图片";
    
    CGRect f = self.view.bounds;
    if (IOS7_OR_LATER) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
        f.size.height -= 64.f;
    } else {
        f.size.height -= 44.f;
    }
    
    self.view.backgroundColor = [HPTheme backgroundColor];
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(5.f, 5.f, f.size.width-10.f, f.size.height - 74.f - 12.f)];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.rowHeight = 74.f;
    self.tableView.backgroundColor = self.view.backgroundColor;
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"Cell"];
    [self.view addSubview:self.tableView];
    
    UIView *container = [UIView new];
    container.frame = CGRectMake(0, f.size.height - 44, f.size.width, 44.f);
    container.backgroundColor = rgb(245.f, 245.f, 245.f);
    [self.view addSubview:container];
    
    UIView *line = [UIView new];
    line.backgroundColor = rgb(205.f, 205.f, 205.f);
    line.frame = CGRectMake(0, 0, container.frame.size.width, .5);
    [container addSubview:line];
    
    UISegmentedControl *segmentControl = [[UISegmentedControl alloc]initWithItems:@[@"~100kb",@"~200kb",@"~400kb", @"~600kb"]];
    [segmentControl setSegmentedControlStyle:UISegmentedControlStyleBar];
    [segmentControl sizeToFit];
    segmentControl.center = CGPointMake(container.frame.size.width - segmentControl.frame.size.width/2 - 5.f, container.frame.size.height /2 );
    [segmentControl addTarget:self action:@selector(segmentedControlValueDidChange:) forControlEvents:UIControlEventValueChanged];
    [segmentControl setSelectedSegmentIndex:1];
    [container addSubview:segmentControl];
    
    UILabel *label = [UILabel new];
    [container addSubview:label];
    label.text = @"大小";
    [label sizeToFit];
    label.backgroundColor = [UIColor clearColor];
    label.center = CGPointMake((container.frame.size.width - segmentControl.frame.size.width)/2.f, container.frame.size.height/2);
    
    
    UIView *container2 = [UIView new];
    [self.view addSubview:container2];
    container2.frame = CGRectMake(0, f.size.height - 78.f, f.size.width, 34.f);
    container2.backgroundColor = rgb(245.f, 245.f, 245.f);
    UIView *line2 = [UIView new];
    line2.backgroundColor = rgb(205.f, 205.f, 205.f);
    line2.frame = CGRectMake(0, 0, f.size.width, .5);
    [container2 addSubview:line2];
    
    UIView *line3 = [UIView new];
    line3.backgroundColor = rgb(205.f, 205.f, 205.f);
    line3.frame = CGRectMake(container2.frame.size.width/2, 2.f, .5, container2.frame.size.height - 4.f);
    [container2 addSubview:line3];
    
    UIButton *selectBtnA = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [container2 addSubview:selectBtnA];
    selectBtnA.tag = 0;
    [selectBtnA setTitle:@"拍照" forState:UIControlStateNormal];
    selectBtnA.titleLabel.font = [UIFont systemFontOfSize:18.f];
    [selectBtnA addTarget:self action:@selector(selectPic:) forControlEvents:UIControlEventTouchUpInside];
    [selectBtnA sizeToFit];
    selectBtnA.center = CGPointMake(container2.frame.size.width/4.f, container2.frame.size.height/2.f);
    
    UIButton *selectBtnB = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [container2 addSubview:selectBtnB];
    selectBtnB.tag = 1;
    [selectBtnB setTitle:@"从图库选取" forState:UIControlStateNormal];
    selectBtnB.titleLabel.font = [UIFont systemFontOfSize:18.f];
    [selectBtnB addTarget:self action:@selector(selectPic:) forControlEvents:UIControlEventTouchUpInside];
    [selectBtnB sizeToFit];
    selectBtnB.center = CGPointMake(container2.frame.size.width/4.f*3.f, container2.frame.size.height/2.f);
    
    if ([Setting boolForKey:HPSettingNightMode]) {
        container.backgroundColor = [HPTheme backgroundColor];
        container2.backgroundColor = [HPTheme backgroundColor];
        label.textColor = [HPTheme textColor];
    }
    
    
    UIBarButtonItem *sendBtn = [[UIBarButtonItem alloc]initWithTitle:@"上传" style:UIBarButtonItemStylePlain target:self action:@selector(upload)];
    
    UIBarButtonItem *cancelBtn = [[UIBarButtonItem alloc]
                                  initWithTitle:@"取消"
                                  style:UIBarButtonItemStylePlain target:self action:@selector(cancelUpload:)];
    
    [self.navigationItem setRightBarButtonItem:sendBtn];
    [self.navigationItem setLeftBarButtonItem:cancelBtn];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
}

#pragma mark -
+ (ALAssetsLibrary *)defaultAssetsLibrary
{
    static dispatch_once_t pred = 0;
    static ALAssetsLibrary *library = nil;
    dispatch_once(&pred,^
                  {
                      library = [[ALAssetsLibrary alloc] init];
                  });
    return library;
}

#pragma mark -

- (void)clearAssets:(id)sender
{
    if (self.assets)
    {
        self.assets = [@[] mutableCopy];
        [self.tableView reloadData];
    }
}

- (void)pickAssets:(id)sender
{
    
    
    CTAssetsPickerController *picker = [[CTAssetsPickerController alloc] init];
    picker.assetsLibrary = [self.class defaultAssetsLibrary];
    picker.assetsFilter         = [ALAssetsFilter allPhotos];
    picker.showsCancelButton    = (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad);
    picker.delegate             = self;
    picker.selectedAssets       = [NSMutableArray arrayWithArray:self.assets];
    
    // iPad
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        self.popover = [[UIPopoverController alloc] initWithContentViewController:picker];
        self.popover.delegate = self;
        
        [self.popover presentPopoverFromRect:[sender bounds] inView:sender
                    permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    }
    else
    {
        [self presentViewController:picker animated:YES completion:nil];
    }
}


#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.assets.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    
    ALAsset *asset = [self.assets objectAtIndex:indexPath.row];
    
    //cell.textLabel.text = [self.dateFormatter stringFromDate:[asset valueForProperty:ALAssetPropertyDate]];
    //cell.detailTextLabel.text = [asset valueForProperty:ALAssetPropertyType];
    cell.imageView.image = [UIImage imageWithCGImage:asset.thumbnail];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    CTAssetsPageViewController *vc = [[CTAssetsPageViewController alloc] initWithAssets:self.assets];
    vc.pageIndex = indexPath.row;
    
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - Popover Controller Delegate

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    self.popover = nil;
}


#pragma mark - Assets Picker Delegate

- (BOOL)assetsPickerController:(CTAssetsPickerController *)picker isDefaultAssetsGroup:(ALAssetsGroup *)group
{
    return ([[group valueForProperty:ALAssetsGroupPropertyType] integerValue] == ALAssetsGroupSavedPhotos);
}

- (void)assetsPickerController:(CTAssetsPickerController *)picker didFinishPickingAssets:(NSArray *)assets
{
    if (self.popover != nil)
        [self.popover dismissPopoverAnimated:YES];
    else
        [picker.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    
    self.assets = [NSMutableArray arrayWithArray:assets];
    [self.tableView reloadData];
}

- (BOOL)assetsPickerController:(CTAssetsPickerController *)picker shouldEnableAsset:(ALAsset *)asset
{
    return YES;
}

- (BOOL)assetsPickerController:(CTAssetsPickerController *)picker shouldSelectAsset:(ALAsset *)asset
{
    return YES;
}

#pragma mark -

- (void)cancelUpload:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)selectPic:(id)sender {
    
    int tag = [sender tag];
    
    UIImagePickerController *imagePicker =
    [[UIImagePickerController alloc] init];
    
    switch (tag) {
        case 0:
            if ([UIImagePickerController
                 isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
                [imagePicker setSourceType:UIImagePickerControllerSourceTypeCamera];
                [imagePicker setDelegate:self];
                [self presentViewController:imagePicker animated:YES completion:nil];
            } else {
                [self pickAssets:sender];
            }
            break;
        case 1:
            [self pickAssets:sender];
            break;
        default:
            NSLog(@"selectPic unknown tag %d", tag);
            break;
    }
}

- (void)upload {
    
    if (self.assets.count <= 0) {
        [SVProgressHUD showErrorWithStatus:@"还没选呢"];
        return;
    }
    
    self.navigationItem.rightBarButtonItem.enabled = NO;
    [self uploadImage:0];
}

- (void)uploadDone {
    [SVProgressHUD dismiss];
    self.navigationItem.rightBarButtonItem.enabled = YES;
    [self dismissViewControllerAnimated:YES completion:^{
        ;
    }];
}

- (void)uploadImage:(NSUInteger)index {

    ALAsset *asset = self.assets[index];
    NSString *current = [NSString stringWithFormat:@"(%@/%@)", @(index+1), @(self.assets.count)];
    UIImage *image = [UIImage imageWithCGImage:asset.defaultRepresentation.fullResolutionImage
                                         scale:asset.defaultRepresentation.scale
                                   orientation:(UIImageOrientation)asset.defaultRepresentation.orientation];
    [SVProgressHUD showWithStatus:@"" maskType:SVProgressHUDMaskTypeBlack];
    
    __weak typeof(self) weakSelf = self;
    [self uploadImage:image progressBlock:^(NSString *progress) {
        [SVProgressHUD showWithStatus:S(@"%@ %@", current, progress) maskType:SVProgressHUDMaskTypeBlack];
    } block:^(NSString *attach, NSError *error) {
        if (!error) {
            [weakSelf.delegate completeWithAttachString:attach error:nil];
            if (index+1 < self.assets.count) {
                [weakSelf uploadImage:index+1];
            } else {
                [weakSelf uploadDone];
            }
        } else {
            [SVProgressHUD showErrorWithStatus:[error localizedDescription]];
        }
    }];
}

- (void)uploadImage:(UIImage *)fullResolutionImage
      progressBlock:(void (^)(NSString *progress))progressBlock
              block:(void (^)(NSString *attach, NSError *error))block {

    progressBlock(@"压缩中...");
    NSLog(@"compress...");
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        // 文件尺寸: 小于 976KB
        // 可用扩展名: jpg, jpeg, gif, png, bmp
        UIImage *image = [fullResolutionImage resizedImageWithContentMode:UIViewContentModeScaleAspectFill bounds:CGSizeMake(self.targetSize, self.targetSize) interpolationQuality:kCGInterpolationDefault];
        NSData *imageData = UIImageJPEGRepresentation(image, 0.35);
        NSInteger size = imageData.length/1024;
        NSLog(@"compress done %@", @(size));
        
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"upload....");
            progressBlock([NSString stringWithFormat:@"上传中...(0/%@kb)", @(size)]);
            [HPSendPost uploadImage:imageData
                          imageName:nil
                      progressBlock:^(CGFloat progress)
             {
                 progressBlock([NSString stringWithFormat:@"上传中...(%d/%@kb)", (int)(progress*size), @(size)]);
             }
                              block:^(NSString *attach, NSError *error)
             {
                 NSLog(@"attach %@, error %@", attach, [error localizedDescription]);
                 block(attach, error);
             }];
        });
    });
}

#pragma mark -

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
    ALAssetsLibrary *library = [self.class defaultAssetsLibrary];
    [SVProgressHUD showWithStatus:@"保存中..."];
    [library writeImageToSavedPhotosAlbum:image.CGImage
                                 metadata:[info objectForKey:UIImagePickerControllerMediaMetadata]
                          completionBlock:^(NSURL *assetURL, NSError *error) {
                              NSLog(@"assetURL %@", assetURL);
                              [library assetForURL:assetURL resultBlock:^(ALAsset *asset) {
                                  dispatch_async(dispatch_get_main_queue(), ^{
                                      [self.assets addObject:asset];
                                      [self.tableView reloadData];
                                      [SVProgressHUD dismiss];
                                  });
                              } failureBlock:^(NSError *error) {
                                  NSLog(@"%@", error);
                                  [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"%@", error]];
                              }];
                          }];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark -

-(void)segmentedControlValueDidChange:(UISegmentedControl *)segment
{
    NSLog(@"segment.selectedSegmentIndex %d", segment.selectedSegmentIndex);
    switch (segment.selectedSegmentIndex) {
        case 0:
        {
            _targetSize = 400.f;
            break;
        }
        case 1:
        {
            _targetSize = 600.f;
            break;
        }
        case 2:
        {
            _targetSize = 800.f;
            break;
        }
        case 3:
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