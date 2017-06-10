//
//  HPPDFPrintPageRenderer.m
//  HiPDA
//
//  Created by Jiangfan on 2017/6/10.
//  Copyright © 2017年 wujichao. All rights reserved.
//

//https://github.com/gleue/PDFPrintPageRenderer/blob/master/PDFPrintPageRenderer.m
//http://blog.moritzhaarmann.de/daily/2016/02/26/webview-pdf.html

#import "HPPDFPrintPageRenderer.h"

@implementation HPPDFPrintPageRenderer

- (CGRect)paperRect
{
    CGRect rect = UIGraphicsGetPDFContextBounds();
    return rect;
}

- (CGRect)printableRect
{
    return self.paperRect;
}

- (NSData*)printToPDF
{
    NSMutableData *pdfData = [NSMutableData data];
    
    UIGraphicsBeginPDFContextToData(pdfData, self.paperRect, nil);
    
    [self prepareForDrawingPages:NSMakeRange(0, self.numberOfPages)];
    
    CGRect bounds = UIGraphicsGetPDFContextBounds();
    
    for (NSInteger i = 0 ; i < self.numberOfPages; i++) {
        
        UIGraphicsBeginPDFPage();
        
        [self drawPageAtIndex:i inRect:bounds];
    }
    
    UIGraphicsEndPDFContext();
    
    return pdfData;
}

@end
