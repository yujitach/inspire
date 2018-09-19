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
    NSMutableAttributedString*x=[[NSMutableAttributedString alloc] initWithPath:pathToRTF documentAttributes:nil];
    [x addAttribute:NSForegroundColorAttributeName value:[NSColor textColor] range:NSMakeRange(0, x.length)];
    [tv.textStorage appendAttributedString:x];
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
