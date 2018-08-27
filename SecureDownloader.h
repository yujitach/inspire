//
//  SecureDownloader.h
//  spires
//
//  Created by Yuji on 09/02/06.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface SecureDownloader : NSObject<NSURLSessionDelegate,NSURLSessionTaskDelegate,NSURLSessionDownloadDelegate>
-(SecureDownloader*)initWithURL:(NSURL*)u completionHandler:(void(^)(NSString*))h ;
-(void)download;
@property (readonly) NSURL*url;
@end
