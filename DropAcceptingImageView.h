//
//  DropAcceptingImageView.h
//  spires
//
//  Created by Yuji on 12/20/09.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@protocol DropAcceptingDelegate
-(NSArray*)draggedTypesToRegister;
- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender;
- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender;
@end

@interface DropAcceptingImageView : NSImageView {
    id delegate;
}
@property(retain) id delegate;
@end
