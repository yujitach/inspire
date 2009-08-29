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

-(SecureDownloader*)initWithURL:(NSURL*)u didEndSelector:(SEL)s delegate:(id)d 
{
    self=[super init];
    url=u;
    selector=s;
    delegate=d;
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
    return [(id<AppDelegate>)[NSApp delegate] mainWindow];
}
- (void)download:(NSURLDownload *)download decideDestinationWithSuggestedFilename:(NSString *)filename
{
    [download setDestination:path allowOverwrite:YES];
}
- (void)download:(NSURLDownload *)download didFailWithError:(NSError *)error
{
    
    [delegate performSelector:selector withObject:nil];
    NSAlert*alert=[NSAlert alertWithMessageText:@"Connection Error"
				  defaultButton:@"OK"
				alternateButton:nil
				    otherButton:nil informativeTextWithFormat:@"Error: %@",[error localizedDescription]];
    //[alert setAlertStyle:NSCriticalAlertStyle];
    [alert beginSheetModalForWindow:[(id<AppDelegate>)[NSApp delegate] mainWindow]
		      modalDelegate:nil 
		     didEndSelector:nil
			contextInfo:nil];
}
- (void)downloadDidFinish:(NSURLDownload *)download
{
    [delegate performSelector:selector withObject:path];

}

@end
