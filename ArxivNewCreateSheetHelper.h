//
//  ArxivNewCreateSheetHelper.h
//  spires
//
//  Created by Yuji on 8/17/09.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class spires_AppDelegate;
@interface ArxivNewCreateSheetHelper : NSObject {
    NSWindow*windowToAttach;
    spires_AppDelegate*delegate;
    IBOutlet NSWindow*sheet;
    NSString*head;
    NSString*tail;
}
-(id)initWithWindow:(NSWindow*)w delegate:(spires_AppDelegate*)d;
-(void)run;
-(IBAction)OK:(id)sender;
-(IBAction)cancel:(id)sender;
- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo;
@end
