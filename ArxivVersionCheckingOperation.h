//
//  ArxivVersionCheckingOperation.h
//  spires
//
//  Created by Yuji on 09/02/07.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DumbOperation.h"
#import "PDFHelper.h"
@class Article;
@interface ArxivVersionCheckingOperation : DumbOperation {
    Article* article;
    PDFViewerType type;
}
-(ArxivVersionCheckingOperation*)initWithArticle:(Article*)a usingViewer:(PDFViewerType)t;
@end
