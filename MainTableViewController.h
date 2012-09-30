//
//  MainTableViewController.h
//  spires
//
//  Created by Yuji on 09/02/01.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TableViewContextMenuCategory.h"

@class HidableNSTableView;
@interface MainTableViewController : NSObject<TableViewContextMenuDelegate> {
    IBOutlet HidableNSTableView* tv;
    IBOutlet NSArrayController* ac;
}

@end
