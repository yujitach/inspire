//
//  DropAcceptingImageView.m
//  spires
//
//  Created by Yuji on 12/20/09.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import "DropAcceptingImageView.h"


@implementation DropAcceptingImageView
@synthesize delegate;
-(void)awakeFromNib
{
    [self registerForDraggedTypes:[(id<DropAcceptingDelegate>)[self delegate] draggedTypesToRegister]];
}
- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender {
    return [(id<DropAcceptingDelegate>)[self delegate] draggingEntered:sender];
}
- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender {
    return [(id<DropAcceptingDelegate>)[self delegate] performDragOperation:sender];
}
@end
