//
//  ArxivNewCreateSheetHelper.h
//  spires
//
//  Created by Yuji on 8/17/09.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ArxivNewCreateSheetHelper : NSObject {
    IBOutlet NSWindow*sheet;
    NSString*head;
    NSString*tail;
}
-(id)init;
-(void)run;
-(IBAction)OK:(id)sender;
-(IBAction)cancel:(id)sender;
@end
