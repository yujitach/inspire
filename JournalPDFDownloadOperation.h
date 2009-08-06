//
//  JournalPDFDownloadOperation.h
//  spires
//
//  Created by Yuji on 09/02/07.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DumbOperation.h"
@class Article;
@class SecureDownloader;
@interface JournalPDFDownloadOperation : ConcurrentOperation {
    Article*article;
    SecureDownloader*downloader;

}
-(JournalPDFDownloadOperation*)initWithArticle:(Article*)a;
@end
