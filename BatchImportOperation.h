//
//  BatchImportOperation.h
//  spires
//
//  Created by Yuji on 09/02/07.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

@import CoreData;
#import "DumbOperation.h"

@class Article;
@class ArticleList;
@interface BatchImportOperation : NSOperation
-(BatchImportOperation*)initWithProtoArticles:(NSArray*)d
                          originalQuery:(NSString*)q
                             updatesCitations:(BOOL)b
                                     usingMOC:(NSManagedObjectContext*)moc
                                     whenDone:(void(^)(BatchImportOperation*op))wd;
@property(readonly) NSMutableSet*generated;
@property(readonly) NSManagedObjectContext*secondMOC;
@end
