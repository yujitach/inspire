//
//  SecureDownloader.m
//  spires
//
//  Created by Yuji on 09/02/06.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import "SecureDownloader.h"
#import "AppDelegate.h"

@implementation SecureDownloader
{
    NSURLSession*session;
    NSURLSessionDownloadTask*downloadTask;
    void (^handler)(NSString*);
    NSURL*url;
}
@synthesize url;

-(SecureDownloader*)initWithURL:(NSURL*)u completionHandler:(void(^)(NSString*))h ;
{
    self=[super init];
    url=u;
    handler=[h copy];
    return self;
}
-(void)download;
{
    NSURLRequest* urlRequest=[NSURLRequest requestWithURL:url
					      cachePolicy:NSURLRequestUseProtocolCachePolicy
					  timeoutInterval:30];
    NSURLSessionConfiguration*config=[NSURLSessionConfiguration defaultSessionConfiguration];
    session=[NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    downloadTask=[session downloadTaskWithRequest:urlRequest];
    [downloadTask resume];
}
	      
#pragma mark Delegates
/*
- (NSWindow *)downloadWindowForAuthenticationSheet:(WebDownload *)sender
{
    return [[NSApp appDelegate] mainWindow];
}
 */
-(void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    if(error){
        handler(nil);
        // silently fails for now...
/*
        NSAlert*alert=[[NSAlert alloc] init];
        alert.messageText=@"I'm sorry...";
        [alert addButtonWithTitle:@"OK"];
        alert.informativeText=@"Couldn't autodownload journal pdf.";
        //[NSString stringWithFormat:@"Error: %@",[error localizedDescription]];
        //[alert setAlertStyle:NSCriticalAlertStyle];
        [alert beginSheetModalForWindow:[[NSApp appDelegate] mainWindow]
                      completionHandler:nil];
 */
    }
}
-(void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task willPerformHTTPRedirection:(NSHTTPURLResponse *)response newRequest:(NSURLRequest *)request completionHandler:(void (^)(NSURLRequest * _Nullable))completionHandler
{
    completionHandler(request);
}
-(void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location
{
    handler([NSString stringWithUTF8String:location.fileSystemRepresentation]);
}

@end
