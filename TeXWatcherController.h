//
//  TeXWatcherController.h
//  spires
//
//  Created by Yuji on 6/29/09.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AuxPanelController.h"
@class DirWatcher;
@interface TeXWatcherController : AuxPanelController {
    IBOutlet NSTextView* tv;
    NSImage*image;
    DirWatcher*dw;
    NSMutableDictionary*parents;
    NSPipe*pipe;
}
-(IBAction)clearFolderToWatch:(id)sender;
-(void)addToLog:(NSString*)s;
@property (copy) NSURL*pathToWatch;  
@property (retain) NSImage*image;
@end
