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
    IBOutlet NSTextField*tf;
    IBOutlet NSScrollView*sv;
    DirWatcher*dw;
    NSMutableDictionary*parents;
    NSPipe*pipe;
}
-(IBAction)setFolderToWatch:(id)sender;
-(IBAction)clearFolderToWatch:(id)sender;
+(TeXWatcherController*)sharedController;
-(void)addToLog:(NSString*)s;
@property (copy) NSString*pathToWatch;  // for some stupid reason it's kept with /Users/user abbreviated by ~.
@end
