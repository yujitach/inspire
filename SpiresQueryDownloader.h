//
//  SpiresQueryDownloader.h
//  spires
//
//  Created by Yuji on 7/3/09.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class Article;
@interface SpiresQueryDownloader : NSObject {
    id delegate;
    SEL sel;
    NSString*searchString;
    NSMutableData*temporaryData;
    NSURLConnection*connection;
    NSURLRequest*urlRequest;
    BOOL inspire;
    NSUInteger total;
    NSUInteger sofar;
    Article*article;
}
// note that didEndSelector can be called **multiple times**.
// It's guaranteed to be always on the main thread.
-(id)initWithQuery:(NSString*)s forArticle:(Article*)a delegate:(id)d  didEndSelector:(SEL)sel ;
@end
