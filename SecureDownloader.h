//
//  SecureDownloader.h
//  spires
//
//  Created by Yuji on 09/02/06.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class WebDownload;
@interface SecureDownloader : NSObject {
    WebDownload*downloader;
    SEL selector;
    id delegate;
    NSURL*url;
    NSString*path;
}
-(SecureDownloader*)initWithURL:(NSURL*)u didEndSelector:(SEL)s delegate:(id)t ;
-(void)download;
@end
