//
//  ArticleFetchOperation.h
//  inspire
//
//  Created by Yuji on 2012/09/30.
//
//

#import <Foundation/Foundation.h>
#import "DumbOperation.h"

@class ArticleList;
@interface ArticleFetchOperation : NSOperation
-(ArticleFetchOperation*)initWithQuery:(NSString*)search forArticleList:(ArticleList*)al;
@end
