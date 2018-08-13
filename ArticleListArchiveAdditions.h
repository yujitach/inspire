//
//  ArticleListDictionaryRepresentation.h
//  inspire
//
//  Created by Yuji on 2015/08/11.
//
//

#import "ArticleList.h"
@class ArticleFolder;
@interface ArticleList (ArticleListArchiveAdditions)
+(NSArray*)notFoundArticleListsAfterMergingChildren:(NSArray*)children toArticleFolder:(ArticleFolder*)af usingMOC:(NSManagedObjectContext*)secondMOC;
+(void)populateFlaggedArticlesFrom:(NSArray*)a usingMOC:(NSManagedObjectContext*)secondMOC;
@end
@interface PrepareSnapshotOperation:NSOperation
@property NSDictionary*snapShot;
@end

