//
//  BibTeXIDsLookUpOperation.h
//  spires
//
//  Created by Yuji on 7/5/09.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DumbOperation.h"

@interface BibTeXIDsLookUpOperation : ConcurrentOperation {
    NSArray*keys;
    NSOperation*parent;
}
-(id)initWithKeys:(NSArray*)a parent:(NSOperation*)p;
@end
