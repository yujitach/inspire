//
//  BibTeXKeyCopyOperation.h
//  spires
//
//  Created by Yuji on 6/30/09.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DumbOperation.h"

@interface BibTeXKeyCopyOperation : ConcurrentOperation {
    NSArray*articles;
}
-(id)initWithArticles:(NSArray*)as;
@end
