//
//  ActivityMonitorController.h
//  spires
//
//  Created by Yuji on 09/02/08.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ActivityMonitorController : NSWindowController {
    IBOutlet NSArrayController*activityController;
    NSMutableArray*array;
}
-(void)showhide:(id)sender;
@end
