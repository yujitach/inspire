//
//  StatusBar.h
//  spires
//
//  Created by Yuji on 12/1/09.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class CATextLayer;
@interface StatusBar : NSObject {
    IBOutlet NSView*view;
    NSTextField*tf;
}
+(StatusBar*)sharedStatusBar;
@end
