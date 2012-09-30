//
//  ImporterController.h
//  spires
//
//  Created by Yuji on 08/11/04.
//  Copyright 2008 Y. Tachikawa. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ImporterController : NSWindowController {
//    spires_AppDelegate* appDelegate;
    IBOutlet NSTextField*tf;
    IBOutlet NSProgressIndicator*pi;
    int current;
    NSString*currentFile;
    int total;
    NSArray*elements;
}
-(ImporterController*)init; //WithAppDelegate:(spires_AppDelegate*)delegate;
-(void)import:(NSArray*)files;
@end
