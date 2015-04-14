//
//  SpiresQueryDownloader.h
//  spires
//
//  Created by Yuji on 7/3/09.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class Article;
typedef void (^WhenDoneClosure)(NSData*xmlData,NSUInteger count,NSUInteger total);
@interface SpiresQueryDownloader : NSObject {
    WhenDoneClosure whenDone;
    NSString*searchString;
    NSMutableData*temporaryData;
    NSURLConnection*connection;
    NSURLRequest*urlRequest;
    NSUInteger total;
    NSUInteger sofar;
    NSUInteger startIndex;
    Article*article;
}
// note that didEndSelector can be called **multiple times**.
// It's guaranteed to be always on the main thread.
-(id)initWithQuery:(NSString*)s startAt:(NSUInteger)start forArticle:(Article*)a whenDone:(WhenDoneClosure)wd ;
@end
