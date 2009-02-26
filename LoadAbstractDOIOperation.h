//
//  LoadAbstractDOIOperation.h
//  spires
//
//  Created by Yuji on 09/02/08.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DumbOperation.h"

@class Article;
@interface LoadAbstractDOIOperation : DumbOperation {
    Article*article;
}
-(LoadAbstractDOIOperation*)initWithArticle:(Article*)a;
@end
