//
//  ReloadButton.h
//  spires
//
//  Created by Yuji on 12/6/09.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ReloadButton : NSButtonCell {
    NSImage*isInImg;
    NSImage*isOutImg;
    NSImage*isInSelectedImg;
    NSImage*isOutSelectedImg;
    BOOL isIn;
    BOOL isHighlighted;
}

@end
