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
@interface BatchImportOperation : NSOperation {
    NSArray*elements;
    NSManagedObjectContext*secondMOC;
    Article*citedByTarget;
    Article*refersToTarget;
    ArticleList*list;
    NSMutableSet*generated;
}
-(BatchImportOperation*)initWithElements:(NSArray*)e 
				//  andMOC:(NSManagedObjectContext*)m 
				 citedBy:(Article*)c refersTo:(Article*)r registerToArticleList:(ArticleList*)l;
@property(readonly) NSMutableSet*generated;
@end
