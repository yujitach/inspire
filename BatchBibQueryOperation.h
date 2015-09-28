//
//  BatchBibQueryOperation.h
//  spires
//
//  Created by Yuji on 09/02/07.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DumbOperation.h"

@interface BatchBibQueryOperation : NSOperation 
-(BatchBibQueryOperation*)initWithArray:(NSArray*)a;
@end
