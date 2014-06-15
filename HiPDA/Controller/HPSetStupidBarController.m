//
//  HPSetStupidBarController.m
//  HiPDA
//
//  Created by wujichao on 14-6-14.
//  Copyright (c) 2014年 wujichao. All rights reserved.
//

#import "HPSetStupidBarController.h"
#import "HPSetting.h"

@interface HPSetStupidBarController () <UITableViewDataSource, UITableViewDelegate, UIActionSheetDelegate>

@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic, strong) NSArray *data;

@property (nonatomic, strong) UITableViewCell *cell0;
@property (nonatomic, strong) UITableViewCell *cell1;
@property (nonatomic, strong) UITableViewCell *cell2;

@property (nonatomic, strong) NSArray *actions;

@end

@implementation HPSetStupidBarController

- (void)loadView {
    [super loadView];
    
    _tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    [self.view addSubview:_tableView];
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _tableView.dataSource = self;
    _tableView.delegate = self;
    
    [_tableView registerClass:[UITableViewHeaderFooterView class] forHeaderFooterViewReuseIdentifier:@"TableViewSectionHeaderViewIdentifier"];
    
    self.title = @"StupidBar 设定";
    
    _data = @[@{},
              @{@"key":@"屏幕下边沿左边", @"value":HPSettingStupidBarLeftAction},
              @{@"key":@"屏幕下边沿中间", @"value":HPSettingStupidBarCenterAction},
              @{@"key":@"屏幕下边沿右边", @"value":HPSettingStupidBarRightAction}];
    
    _actions = @[@"收藏", @"加关注", @"跳页", @"上一页", @"下一页", @"回复", @"只看楼主", @"刷新", @"滚动至页面底部", @"GoogleReader - J", @"GoogleReader - K"];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [Setting boolForKey:HPSettingStupidBarDisable]? 1 : 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case 0:
            return 1;
            break;
        case 1:
            return 4;
            break;
        default:
            return 0;
            break;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    if (indexPath.section == 0 && indexPath.row == 0) {
        
        if (!_cell0) {
            _cell0 = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"stupidbar_cell0"];
            
            UISwitch *switchCtl = [[UISwitch alloc] initWithFrame:CGRectZero];
            CGFloat x = CGRectGetWidth(_cell0.contentView.frame) - CGRectGetWidth(switchCtl.frame)/2 - 10.0;
            CGFloat y = CGRectGetHeight(_cell0.contentView.frame)/2;        switchCtl.center = CGPointMake(x, y);
            [switchCtl addTarget:self action:@selector(switchAction:) forControlEvents:UIControlEventValueChanged];
            switchCtl.backgroundColor = [UIColor clearColor];
            switchCtl.tag = 1313;
            
            //dirty fix for ios6 & ui7kit
            _cell0.textLabel.backgroundColor = [UIColor clearColor];
        
            [_cell0.contentView addSubview:switchCtl];
        }
        
        _cell0.textLabel.text = @"开启 StupidBar";
        UISwitch *switchCtl = (UISwitch *)[_cell0.contentView viewWithTag:1313];
        [switchCtl setOn:![Setting boolForKey:HPSettingStupidBarDisable]];
        
        _cell0.selectionStyle = UITableViewCellSelectionStyleNone;
        
        return _cell0;
        
    } else if (indexPath.section == 1 && indexPath.row == 0) {
        
        if (!_cell1) {
            _cell1 = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"stupidbar_cell1"];
            
            UISwitch *switchCtl = [[UISwitch alloc] initWithFrame:CGRectZero];
            CGFloat x = CGRectGetWidth(_cell1.contentView.frame) - CGRectGetWidth(switchCtl.frame)/2 - 10.0;
            CGFloat y = CGRectGetHeight(_cell1.contentView.frame)/2;        switchCtl.center = CGPointMake(x, y);
            [switchCtl addTarget:self action:@selector(switchAction:) forControlEvents:UIControlEventValueChanged];
            switchCtl.backgroundColor = [UIColor clearColor];
            switchCtl.tag = 1414;
            
            //dirty fix for ios6 & ui7kit
            _cell1.textLabel.backgroundColor = [UIColor clearColor];
            
            [_cell1.contentView addSubview:switchCtl];
        }
        
        _cell1.textLabel.text = @"隐藏 StupidBar";
        UISwitch *switchCtl = (UISwitch *)[_cell1.contentView viewWithTag:1414];
        [switchCtl setOn:[Setting boolForKey:HPSettingStupidBarHide]];
        
        _cell1.selectionStyle = UITableViewCellSelectionStyleNone;
        
        return _cell1;
    }
    
    static NSString *CellIdentifier = @"HPStupidBarSettingCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
    }
    
    cell.textLabel.text = [[_data objectAtIndex:indexPath.row] objectForKey:@"key"];
    NSString *value = [[_data objectAtIndex:indexPath.row] objectForKey:@"value"];
    NSLog(@"%@ %d", value, [Setting integerForKey:value]);
    cell.detailTextLabel.text = _actions[[Setting integerForKey:value]];
    
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    if (indexPath.row == 0) return;
    
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil, nil];
    for( NSString *title in _actions)  {
        [actionSheet addButtonWithTitle:title];
    }
    actionSheet.cancelButtonIndex = [actionSheet addButtonWithTitle:@"取消"];
    
    actionSheet.tag = indexPath.row - 1;
    [actionSheet showInView:self.view];
}


#pragma mark - switchAction

- (void)switchAction:(UISwitch *)sender
{
	// NSLog(@"switchAction: value = %d", [sender isOn]);
    if (sender.tag == 1313) {
        
        [Setting saveBool:![sender isOn] forKey:HPSettingStupidBarDisable];
        [self.tableView reloadData];
        
    } else if (sender.tag == 1414) {
        
        [Setting saveBool:[sender isOn] forKey:HPSettingStupidBarHide];

    }
}


#pragma mark - select action
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    if (buttonIndex == actionSheet.cancelButtonIndex) return;
    
    int tag = actionSheet.tag;
    int index = buttonIndex;
    
    NSString *key = nil;
    if (tag == 0) key = HPSettingStupidBarLeftAction;
    else if (tag == 1) key = HPSettingStupidBarCenterAction;
    else if (tag == 2) key = HPSettingStupidBarRightAction;
    
    [Setting saveInteger:index forKey:key];
    
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:tag+1 inSection:1]] withRowAnimation:UITableViewRowAnimationAutomatic];
}




@end
