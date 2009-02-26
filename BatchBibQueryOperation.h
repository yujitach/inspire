//
//  BatchBibQueryOperation.h
//  spires
//
//  Created by Yuji on 09/02/07.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DumbOperation.h"

@interface BatchBibQueryOperation : DumbOperation {
    NSArray*articles;
}
-(BatchBibQueryOperation*)initWithArray:(NSArray*)a;
@end
