//
//  ArxivNewArticleListReloadOperation.h
//  spires
//
//  Created by Yuji on 8/26/09.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class ArxivNewArticleList;
@interface ArxivNewArticleListReloadOperation : NSOperation
-(NSOperation*)initWithArxivNewArticleList:(ArxivNewArticleList*)a;
@end
