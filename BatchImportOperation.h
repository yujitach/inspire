//
//  BatchImportOperation.h
//  spires
//
//  Created by Yuji on 09/02/07.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <CoreData/CoreData.h>
#import "DumbOperation.h"

@class Article;
@class ArticleList;
@interface BatchImportOperation : NSOperation
-(BatchImportOperation*)initWithProtoArticles:(NSArray*)d
                          originalQuery:(NSString*)q
                             updatesCitations:(BOOL)b;
@property(readonly) NSMutableSet*generated;
@end
