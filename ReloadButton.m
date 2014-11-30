//
//  ReloadButton.m
//  spires
//
//  Created by Yuji on 12/6/09.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import "ReloadButton.h"


@implementation ReloadButton
// somehow the following routine doesn't result in a crisp image! Ugh.
/*-(NSImage*)whiteVersion:(NSImage*)img;
{
    NSSize size=[img size];
    NSRect rect=NSMakeRect(0,0,size.width,size.height);
    NSImage*result=[[NSImage alloc] initWithSize:size];
    [result lockFocus];
    [[NSGraphicsContext currentContext] setShouldAntialias:NO];
    [[NSColor whiteColor] setFill];
    NSRectFill(rect);
    [img drawAtPoint:NSMakePoint(0,0) fromRect:NSZeroRect operation:NSCompositeDestinationIn fraction:1];
    [result unlockFocus];
    return result;
}*/
-(NSButtonCell*)init
{
    isInImg=[NSImage imageNamed:@"whiteIn.pdf"];//[NSImage imageNamed:NSImageNameRefreshFreestandingTemplate];
    [isInImg setSize:NSMakeSize(16,16)];
    isInSelectedImg=isInImg;
    isOutImg=[NSImage imageNamed:@"blackOut.pdf"];//[NSImage imageNamed:NSImageNameRefreshTemplate];
    [isOutImg setSize:NSMakeSize(13,14)];
    isOutSelectedImg=[NSImage imageNamed:@"whiteOut.pdf"];
    [isOutSelectedImg setSize:NSMakeSize(13,14)];
    self=[super initImageCell:isInImg];
    [self setBordered:NO];
    return self;
}
-(void)mouseEntered:(NSEvent *)event
{
    isIn=YES;
    [super mouseEntered:event];
}
-(void)mouseExited:(NSEvent *)event
{
    isIn=NO;
    [super mouseExited:event];
}
-(void)setHighlighted:(BOOL)flag
{
    isHighlighted=flag;
}
-(BOOL)isHighlighted{
    return isHighlighted;
}
-(void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    NSImage*img=nil;
    if(isIn){
	if(isHighlighted){
	    img=isInSelectedImg;
	}else{
	    img=isInImg;
	}
    }else{
       if(isHighlighted){
	   img=isOutSelectedImg;
       }else{
	   img=isOutImg;
       }
   }
    NSSize o=cellFrame.size, i=[img size];
    NSPoint pt=NSMakePoint(cellFrame.origin.x+(o.width-i.width)/2, cellFrame.origin.y+(o.height-i.height)/2);
    NSRect toRect;
    toRect.origin=pt;
    toRect.size=i;
    [img drawInRect:toRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1 respectFlipped:YES hints:nil];
}
@end
