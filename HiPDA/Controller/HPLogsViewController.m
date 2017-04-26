//
//  HPLogsViewController.m
//
//  Created by Jichao Wu on 15/10/31.
//

#import "HPLogsViewController.h"

@interface HPLogViewController: UIViewController
@property (nonatomic, strong) NSString *path;
@end
@implementation HPLogViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    UITextView *t = [[UITextView alloc] initWithFrame:self.view.bounds];
    t.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:t];
    
    NSString *content = [NSString stringWithContentsOfFile:self.path encoding:NSUTF8StringEncoding error:nil];
    t.text = content;
}

@end

@interface HPLogsViewController ()<UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray *files;

@end

@implementation HPLogsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.view addSubview:self.tableView];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"xxx"];
    
    [self refresh];
    
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refresh)];
}

- (void)refresh
{
    [DDLog flushLog];
    __block DDFileLogger *fileLogger = nil;
    [[DDLog allLoggers] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([obj isKindOfClass:DDFileLogger.class]) {
            fileLogger = obj;
            *stop = YES;
        }
    }];
    NSArray *files = [fileLogger.logFileManager sortedLogFilePaths];
    self.files = files;
    
    [self.tableView reloadData];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.files.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"xxx" forIndexPath:indexPath];
    
    NSString *text = [[self.files[indexPath.row] componentsSeparatedByString:@"/"] lastObject];
   
    text = [text stringByReplacingCharactersInRange:NSMakeRange(0, [text rangeOfString:@" "].location) withString:@""];
    cell.textLabel.text = text;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSString *path = self.files[indexPath.row];
    HPLogViewController *vc = [HPLogViewController new];
    vc.path = path;
    [self.navigationController pushViewController:vc animated:YES];
}

@end

