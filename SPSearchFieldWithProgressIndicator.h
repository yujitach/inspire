//
//  SPSearchFieldWithProgressIndicator.h
//  spires
//
//  Created by Yuji on 3/31/09.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SPProgressIndicatingButtonCell.h"

@interface SPSearchFieldWithProgressIndicator : NSSearchField {
    SPProgressIndicatingButtonCell* bc;
    SEL progressQuitAction;
    IBOutlet NSObjectController*controller;
}
-(void)startAnimation:(id)sender;
-(void)stopAnimation:(id)sender;
@property SEL progressQuitAction;
@end
