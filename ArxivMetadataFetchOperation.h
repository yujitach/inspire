//
//  ArxivMetadataFetchOperation.h
//  spires
//
//  Created by Yuji on 09/02/08.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

@import Foundation;
#import "DumbOperation.h"

@class Article;
@interface ArxivMetadataFetchOperation : NSOperation
-(ArxivMetadataFetchOperation*)initWithArticle:(Article*)a;
@end
