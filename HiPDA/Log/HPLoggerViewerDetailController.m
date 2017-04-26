//
//  HPLoggerViewerDetailController.m
//  LoggerDemo
//

#import "HPLoggerViewerDetailController.h"

#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

@interface NSString (highlight)
- (NSAttributedString *)highlightedString;
@end
@implementation NSString (highlight)

- (NSAttributedString *)highlightedString
{
    NSString *content = self;
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:content];
    
    NSDictionary *highlights = @{
        @"<Error>.*": @{NSBackgroundColorAttributeName: UIColorFromRGB(0xFC432A)},
        @"<Warning>.*": @{NSBackgroundColorAttributeName: UIColorFromRGB(0xF2D743)},
        @"<Info>.*": @{NSBackgroundColorAttributeName: UIColorFromRGB(0xA7F8B1)},
        @"<Debug>.*": @{NSBackgroundColorAttributeName: UIColorFromRGB(0xBFF2F0)},
        @"<Verbose>.*": @{NSBackgroundColorAttributeName: UIColorFromRGB(0xD3D3D3)},
    };
    [highlights enumerateKeysAndObjectsUsingBlock:^(NSString *pattern, NSDictionary *attributes, BOOL *stop) {
        NSRegularExpression *regex = [[NSRegularExpression alloc] initWithPattern:pattern options:0 error:nil];
        [regex enumerateMatchesInString:content options:0 range:NSMakeRange(0, content.length) usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
            NSRange range = result.range;
            [attributedString addAttributes:attributes range:range];
        }];
    }];
    return attributedString;
}

@end

@interface HPLoggerViewerDetailController()

@property (nonatomic, strong) UITextView *textView;

@end

@implementation HPLoggerViewerDetailController

- (void)viewDidLoad
{
    [super viewDidLoad];
    UITextView *t = [[UITextView alloc] initWithFrame:self.view.bounds];
    self.textView = t;
    t.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:t];
    
    [self loadContentWithLevel:DDLogLevelVerbose];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self scrollTextViewToBottom:t];
    });
    
    
    UISegmentedControl *segmentedControl = [[UISegmentedControl alloc] initWithItems:@[@"All", @"Debug", @"Info", @"Warning", @"Error"]];
    segmentedControl.selectedSegmentIndex = 0;
    segmentedControl.apportionsSegmentWidthsByContent = YES;
    [segmentedControl addTarget:self action:@selector(segmentedControlDidUpdate:) forControlEvents:UIControlEventValueChanged];
    self.navigationItem.titleView = segmentedControl;
    
    UIBarButtonItem *fastForward = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFastForward target:self action:@selector(fastForward)];
    self.navigationItem.rightBarButtonItem = fastForward;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}
- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
   
}

//http://stackoverflow.com/questions/16698638/scroll-uitextview-to-bottom
- (void)scrollTextViewToBottom:(UITextView *)textView {
    if (textView.text.length > 0) {
        NSRange bottom = NSMakeRange(textView.text.length - 1, 1);
        [textView scrollRangeToVisible:bottom];
    }
}

- (void)fastForward
{
    [self scrollTextViewToBottom:self.textView];
}

#pragma mark - load content

- (void)loadContentWithLevel:(DDLogLevel)level
{
    NSString *content = [NSString stringWithContentsOfFile:self.path encoding:NSUTF8StringEncoding error:nil];
    content = [self.class convertUnicode:content];
    
    if (level != DDLogLevelVerbose) {
        
        content = [@"\n" stringByAppendingString:content];
        NSArray *list = [content componentsSeparatedByString:@"\n<"];
        NSMutableArray *lines = [NSMutableArray new];
        for (NSString *line in list) {
            if (!line.length) {
                continue;
            }
            
            DDLogFlag flag;
            if ([line hasPrefix:@"Verbose>"]) {
                flag = DDLogFlagVerbose;
            } else if ([line hasPrefix:@"Debug>"]) {
                flag = DDLogFlagDebug;
            } else if ([line hasPrefix:@"Info>"]) {
                flag = DDLogFlagInfo;
            } else if ([line hasPrefix:@"Warning>"]) {
                flag = DDLogFlagWarning;
            } else if ([line hasPrefix:@"Error>"]) {
                flag = DDLogFlagError;
            } else {
                flag = DDLogFlagVerbose;
            }
            
            if (flag & level) {
                [lines addObject:line];
            }
        }
        content = [@"<" stringByAppendingString:[lines componentsJoinedByString:@"\n<"]];
    }
    
    self.textView.attributedText = [content highlightedString];
}

- (void)segmentedControlDidUpdate:(UISegmentedControl *)control
{
    DDLogLevel levels[] = {DDLogLevelVerbose, DDLogLevelDebug, DDLogLevelInfo, DDLogLevelWarning, DDLogLevelError, DDLogLevelOff};
    [self loadContentWithLevel:levels[control.selectedSegmentIndex]];
}

//https://github.com/dhcdht/DXXcodeConsoleUnicodePlugin/
+ (NSString*)convertUnicode:(NSString*)string
{
    NSRegularExpression *e = [[NSRegularExpression alloc] initWithPattern:@"\\\\?\\\\[uU]\\w{4}" options:0 error:nil];
    NSMutableString* result = [string mutableCopy];
    
    NSArray* matches = [e matchesInString:string options:0 range:NSMakeRange(0, string.length)];
    for (int i=(int)matches.count-1; i>=0; i--) {
        NSTextCheckingResult* match = matches[i];
        NSString* matchStr = [string substringWithRange:match.range];
        NSString* replacement = [NSString stringWithCString:[matchStr cStringUsingEncoding:NSUTF8StringEncoding]
                                           encoding:NSNonLossyASCIIStringEncoding];
        [result replaceCharactersInRange:match.range withString:replacement ?: matchStr];
    }
    
    return result;
}

@end

