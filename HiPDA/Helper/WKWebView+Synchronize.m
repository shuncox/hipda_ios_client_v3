//
//  WKWebView+Synchronize.m
//  HiPDA
//
//  Created by Jiangfan on 2017/4/17.
//  Copyright © 2017年 wujichao. All rights reserved.
//

#import "WKWebView+Synchronize.h"

@implementation WKWebView (Synchronize)

- (id)stringByEvaluatingJavaScriptFromString:(NSString *)script
{
    __block id result = nil;
    __block NSError *error = nil;
    __block BOOL done = NO;
    NSTimeInterval timeout = 3.f;
    
    if ([NSThread isMainThread]) {
        [self evaluateJavaScript:script completionHandler:^(id r, NSError *e) {
            result = r;
            error = e;
            done = YES;
        }];
        while (!done) {
            CFRunLoopRunResult reason = CFRunLoopRunInMode(kCFRunLoopDefaultMode, timeout, true);
            if (reason != kCFRunLoopRunHandledSource) {
                break;
            }
        }
    } else {
        NSAssert(0, @"todo");
    }
    
    return result ?: error;
    
    //https://github.com/XWebView/XWebView
    /*
    var result: Any?
    var error: Error?
    var done = false
    let timeout = 3.0
    if Thread.isMainThread {
        evaluateJavaScript(script) {
            (obj: Any?, err: Error?)->Void in
            result = obj
            error = err
            done = true
        }
        while !done {
            let reason = CFRunLoopRunInMode(CFRunLoopMode.defaultMode, timeout, true)
            if reason != CFRunLoopRunResult.handledSource {
                break
            }
        }
    } else {
        let condition: NSCondition = NSCondition()
        DispatchQueue.main.async() {
            [weak self] in
            self?.evaluateJavaScript(script) {
                (obj: Any?, err: Error?)->Void in
                condition.lock()
                result = obj
                error = err
                done = true
                condition.signal()
                condition.unlock()
            }
        }
        condition.lock()
        while !done {
            if !condition.wait(until: Date(timeIntervalSinceNow: timeout) as Date) {
                break
            }
        }
        condition.unlock()
    }
    if error != nil { throw error! }
    if !done {
        log("!Timeout to evaluate script: \(script)")
    }
    return result ?? WKWebView.undefined
    */
}

@end
