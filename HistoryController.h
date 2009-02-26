//
//  HistoryController.h
//  spires
//
//  Created by Yuji on 08/10/28.
//  Copyright 2008 Y. Tachikawa. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface HistoryController : NSObject {
    IBOutlet NSArrayController* articleListController;
    IBOutlet NSArrayController* ac;
    IBOutlet NSSegmentedControl*sc;
    NSMutableArray* array;
    int index;
}
-(IBAction)forward:(id)sender;
-(IBAction)backward:(id)sender;
-(IBAction)mark:(id)sender;
@end
