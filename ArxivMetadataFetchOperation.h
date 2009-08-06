//
//  ArxivMetadataFetchOperation.h
//  spires
//
//  Created by Yuji on 09/02/08.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DumbOperation.h"

@class Article;
@interface ArxivMetadataFetchOperation : ConcurrentOperation {
    Article*article;
}
-(ArxivMetadataFetchOperation*)initWithArticle:(Article*)a;
@end
