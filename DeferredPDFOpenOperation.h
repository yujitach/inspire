//
//  DeferredPDFOpenOperation.h
//  spires
//
//  Created by Yuji on 09/02/08.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DumbOperation.h"
#import "PDFHelper.h"

@class Article;
@interface DeferredPDFOpenOperation : ConcurrentOperation {
    Article*article;
    PDFViewerType type;
}
-(DeferredPDFOpenOperation*)initWithArticle:(Article*)a usingViewer:(PDFViewerType)t;
@end
