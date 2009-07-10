//
//  SpiresQueryDownloader.h
//  spires
//
//  Created by Yuji on 7/3/09.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface SpiresQueryDownloader : NSObject {
    id userInfo;
    id delegate;
    SEL sel;
    NSString*searchString;
    NSMutableData*temporaryData;
    NSURLConnection*connection;
    NSURLRequest*urlRequest;
    
}
-(id)initWithQuery:(NSString*)s delegate:(id)d didEndSelector:(SEL)sel userInfo:(id)v;
@end
