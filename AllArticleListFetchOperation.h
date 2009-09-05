//
//  AllArticleListFetchOperation.h
//  spires
//
//  Created by Yuji on 9/5/09.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AllArticleListFetchOperation : NSOperation {
    NSManagedObjectContext* secondMOC;
}

@end
