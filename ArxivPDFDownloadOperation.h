//
//  ArxivPDFDownloadOperation.h
//  spires
//
//  Created by Yuji on 09/02/07.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DumbOperation.h"
#import "PDFHelper.h"
@interface ArxivPDFDownloadOperation : DumbOperation {
    Article*article;
    NSNumber* reloadDelay;
}
-(ArxivPDFDownloadOperation*)initWithArticle:(Article*)a;
@end
