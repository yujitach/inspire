//
//  SecureDownloader.m
//  spires
//
//  Created by Yuji on 09/02/06.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import "SecureDownloader.h"
#import "NSFileManager+TemporaryFileName.h"
#import "AppDelegate.h"
#import <WebKit/WebKit.h>

@implementation SecureDownloader
@synthesize url;

-(SecureDownloader*)initWithURL:(NSURL*)u completionHandler:(void(^)(NSString*))h ;
{
    self=[super init];
    url=u;
    handler=[h copy];
    path=[[NSFileManager defaultManager] temporaryFileName];
//    NSLog(@"%@",path);
    return self;
}
-(void)download;
{
    NSURLRequest* urlRequest=[NSURLRequest requestWithURL:url
					      cachePolicy:NSURLRequestUseProtocolCachePolicy
					  timeoutInterval:30];
    downloader=[[WebDownload alloc] initWithRequest:urlRequest delegate:self];
}
	      
#pragma mark Delegates
- (NSWindow *)downloadWindowForAuthenticationSheet:(WebDownload *)sender
{
    return [[NSApp appDelegate] mainWindow];
}
- (void)download:(NSURLDownload *)download decideDestinationWithSuggestedFilename:(NSString *)filename
{
    [download setDestination:path allowOverwrite:YES];
}
- (void)download:(NSURLDownload *)download didFailWithError:(NSError *)error
{
    
    handler(nil);
    NSAlert*alert=[NSAlert alertWithMessageText:@"Connection Error"
				  defaultButton:@"OK"
				alternateButton:nil
				    otherButton:nil informativeTextWithFormat:@"Error: %@",[error localizedDescription]];
    //[alert setAlertStyle:NSCriticalAlertStyle];
    [alert beginSheetModalForWindow:[[NSApp appDelegate] mainWindow]
		      modalDelegate:nil 
		     didEndSelector:nil
			contextInfo:nil];
}
- (NSURLRequest *)download:(NSURLDownload *)download willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse
{
    url = [request URL];
    return request;
}
- (void)downloadDidFinish:(NSURLDownload *)download
{
    handler(path);
}

@end
