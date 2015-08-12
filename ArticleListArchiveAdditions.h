//
//  ArticleListDictionaryRepresentation.h
//  inspire
//
//  Created by Yuji on 2015/08/11.
//
//

#import "ArticleList.h"
typedef void (^SnapShotBlock)(NSDictionary*snapShot);
typedef void (^ToBeRemovedBlock)(NSArray*articleListsToBeRemoved);
@interface ArticleList(ArticleListArchiveAdditions)
+(void)prepareSnapShotAndPerform:(SnapShotBlock)block;
+(void)mergeSnapShot:(NSDictionary *)snapShot andDealWithArticleListsToBeRemoved:(ToBeRemovedBlock)block;
@end
