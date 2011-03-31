//
//  DeferredPDFOpenOperation.m
//  spires
//
//  Created by Yuji on 09/02/08.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import "DeferredPDFOpenOperation.h"
#import "Article.h"

@implementation DeferredPDFOpenOperation
-(DeferredPDFOpenOperation*)initWithArticle:(Article*)a usingViewer:(PDFViewerType)t;
{
    [super init];
    article=a;
    type=t;
    return self;
}
-(NSString*)description
{
    return [NSString stringWithFormat:@"open PDF for %@",article.title];
}
-(void)run
{
    self.isExecuting=YES;
    if(article.hasPDFLocally){
	[[PDFHelper sharedHelper] openPDFFile:article.pdfPath  usingViewer:type];
    }
    [self finish];
}
@end
