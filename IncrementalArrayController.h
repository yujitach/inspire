//
//  IncrementalArrayController.h
//  spires
//
//  Created by Yuji on 09/02/25.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface IncrementalArrayController : NSArrayController {
    NSString*markedString;
    NSArray*previousArray;
    IBOutlet NSTextField*tf;
    BOOL refuseFiltering;
}
@property BOOL refuseFiltering;
@end
