//
//  pdfScanHelper.m
//  spires
//
//  Created by Yuji on 09/02/27.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//


#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>
int main(int argc,char**argv){
    if(argc!=3)
	return 1;
    NSString*pdfPath=[NSString stringWithUTF8String:argv[1]];
    NSString*outPath=[NSString stringWithUTF8String:argv[2]];
//    NSLog(@"scanning PDF:%@",pdfPath);
    PDFDocument* d=[[PDFDocument alloc] initWithURL:[NSURL fileURLWithPath:pdfPath]];
    PDFPage* p=[d pageAtIndex:0];
    NSString* s=[p string];
    [s writeToFile:outPath atomically:NO encoding:NSUTF8StringEncoding error:nil];
    return 0;
}
