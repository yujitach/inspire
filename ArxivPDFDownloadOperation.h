//
//  ArxivPDFDownloadOperation.h
//  spires
//
//  Created by Yuji on 09/02/07.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

@import Foundation;
#import "DumbOperation.h"
#import "PDFHelper.h"
#import "ArxivHelper.h"
@interface ArxivPDFDownloadOperation : ConcurrentOperation<ArxivHelperDelegate> {
    Article*article;
    NSNumber* reloadDelay;
    BOOL shouldAsk;
}
-(ArxivPDFDownloadOperation*)initWithArticle:(Article*)a shouldAsk:(BOOL)ask;

@end
