//
//  SpiresQueryDownloader.h
//  spires
//
//  Created by Yuji on 7/3/09.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import <Cocoa/Cocoa.h>


#define MAXPERQUERY 50
@class Article;
typedef void (^WhenDoneClosure)(NSData*xmlData,BOOL last);
@interface SpiresQueryDownloader : NSObject {
    WhenDoneClosure whenDone;
    NSString*searchString;
    NSMutableData*temporaryData;
    NSURLConnection*connection;
    NSURLRequest*urlRequest;
    NSUInteger total;
    NSUInteger sofar;
    NSUInteger startIndex;
}
// note that didEndSelector can be called **multiple times**.
// It's guaranteed to be always on the main thread.
-(id)initWithQuery:(NSString*)s startAt:(NSUInteger)start whenDone:(WhenDoneClosure)wd ;
@end
