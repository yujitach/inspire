//
//  SPSearchFieldWithProgressIndicator.h
//  spires
//
//  Created by Yuji on 3/31/09.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface SPSearchFieldWithProgressIndicator : NSSearchField {
    SEL progressQuitAction;
    IBOutlet NSObjectController*controller;
}
-(void)startAnimation:(id)sender;
-(void)stopAnimation:(id)sender;
@property SEL progressQuitAction;
@end
