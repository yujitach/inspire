//
//  SPProgressIndicatingButtonCell.h
//  spires
//
//  Created by Yuji on 3/31/09.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

@import Cocoa;

@interface SPProgressIndicatingButtonCell : NSButtonCell {
//    BOOL mouseIsIn;
    BOOL isSpinning;
    NSTimer*spinTimer;
    int step;
    NSImage*stopImage;
}
-(void)startAnimation:(id)sender;
-(void)stopAnimation:(id)sender;
@property (readonly) BOOL  isSpinning;
@end
