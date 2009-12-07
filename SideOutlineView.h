//
//  SideOutlineView.h
//  spires
//
//  Created by Yuji on 09/03/18.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface SideOutlineView : NSOutlineView {
@private
    NSInteger iMouseRow, iMouseCol;
    NSCell *iMouseCell;    
}

@end
