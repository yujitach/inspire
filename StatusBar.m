//
//  StatusBar.m
//  spires
//
//  Created by Yuji on 12/1/09.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import "StatusBar.h"
#import <QuartzCore/QuartzCore.h>
static StatusBar*_statusBar=nil;
@implementation StatusBar
+(StatusBar*)sharedStatusBar
{
    return _statusBar;
}
-(StatusBar*)init;
{
    self=[super init];
    _statusBar=self;
    return self;
}
-(void)awakeFromNib
{
    NSRect frame=[view bounds];
    frame.size.height=20;
    tf=[[NSTextField alloc] initWithFrame:frame];
    [tf setAutoresizingMask:NSViewMaxYMargin|NSViewWidthSizable];
    [tf setBezeled:NO];
    [tf setBackgroundColor:[NSColor blackColor]];
    [tf setEditable:NO];
    [tf setSelectable:NO];
//    [view addSubview:tf];
    [tf setStringValue:@"hello world!"];
//    [[view layer] addSublayer:textLayer];
}
@end
