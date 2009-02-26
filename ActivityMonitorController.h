//
//  ActivityMonitorController.h
//  spires
//
//  Created by Yuji on 09/02/08.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ActivityMonitorController : NSObject {
    IBOutlet NSArrayController*activityController;
    IBOutlet NSWindow*activityWindow;
    IBOutlet NSTableView*activityTable;
    NSMutableArray*array;
}
@end
