//
//  MessageViewerController.m
//  spires
//
//  Created by Yuji on 8/16/09.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import "MessageViewerController.h"


@implementation MessageViewerController
-(id)initWithRTF:(NSString*)path;
{
    self=[super initWithWindowNibName:@"MessageViewer"];
    pathToRTF=path;
    [self showWindow:self];
    return self;
}
-(void)show:(NSTimer*)timer
{
    [[self window] makeKeyAndOrderFront:self];
}
-(void)awakeFromNib
{
    [tv readRTFDFromFile:pathToRTF];
    annoyingTimer=[NSTimer scheduledTimerWithTimeInterval:2
						   target:self 
						 selector:@selector(show:) 
						 userInfo:nil 
						  repeats:YES];
}
-(void)windowWillClose:(id)sender
{
    [annoyingTimer invalidate];
}
@end
