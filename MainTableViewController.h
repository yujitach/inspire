//
//  MainTableViewController.h
//  spires
//
//  Created by Yuji on 09/02/01.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class HidableNSTableView;
@interface MainTableViewController : NSObject {
    IBOutlet HidableNSTableView* tv;
    IBOutlet NSArrayController* ac;
}

@end
