//
//  AbstractRefreshManager.h
//  inspire
//
//  Created by Yuji on 2015/08/31.
//
//

#import <Foundation/Foundation.h>

@class Article;
@interface AbstractRefreshManager : NSObject
+(AbstractRefreshManager*)sharedAbstractRefreshManager;
// whenDoneBlock is guaranteed to be called in the main thread
-(void)refreshAbstractOfArticle:(Article*)a whenRefreshed:(void(^)(Article*refreshedArticle))whenDoneBlock;
@end
