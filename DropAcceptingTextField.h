//
//  FolderDropAcceptingTextField.h
//  spires
//
//  Created by Yuji on 6/30/09.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol DropAcceptingTextFieldDelegate
-(NSArray*)draggedTypesToRegister;
- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender;
- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender;
@end

@interface DropAcceptingTextField : NSTextField {

}

@end
