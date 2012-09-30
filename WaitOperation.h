//
//  WaitOperation.h
//  spires
//
//  Created by Yuji on 6/30/09.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DumbOperation.h"

@interface WaitOperation : ConcurrentOperation {
    NSTimeInterval delay;
}
-(id)initWithTimeInterval:(NSTimeInterval)mm;
@end
