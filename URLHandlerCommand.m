//
//  URLHandlerCommand.m
//  URLHandler
//
//  Created by Kimbro  Staken on Tue Dec 16 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "URLHandlerCommand.h"
#import "AppDelegate.h"
//static BOOL firsttime=YES;
@implementation URLHandlerCommand

- (id)performDefaultImplementation {
    NSString *urlString = [self directParameter];
//    NSLog(@"handles:%@",urlString);
    if([urlString hasPrefix:@"spires"]){
	[[NSApp appDelegate] handleURL:[NSURL URLWithString:urlString]];
    }
    return nil;
/*    iXDelegate* d=[NSApp delegate];
    NSRange r;
   if((-[[d lastInvocation] timeIntervalSinceNow]<2)){
	urlString=[urlString stringByReplacingOccurrencesOfString:@"iXHook" withString:@"http"];
       NSLog(@"rapid firing...");
	[d openInBrowserWithoutTweaking:urlString];
	return nil;
    }
  //  firsttime=FALSE;
    [d markLastInvocation];
    if([urlString hasPrefix:@"iXHook"]){
	if([urlString hasPrefix:@"iXHook://PreviewHook/"]){
	    urlString=[urlString stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	    urlString=[urlString substringFromIndex:[@"iXHook://PreviewHook/" length]];
	}else{
	    urlString=[urlString stringByReplacingOccurrencesOfString:@"iXHook" withString:@"http"];
	}
	[d doLookUp:urlString andOpenAfterwards:YES];
	return nil;
    }
    
    
    r=[urlString rangeOfString:@"arxiv.org"];
    if(r.location==NSNotFound){
	r=[urlString rangeOfString:@"xxx.lanl.gov"];
	if(r.location==NSNotFound){
	    [d openInBrowserWithoutTweaking:urlString];
	    return nil;
	}
    }
						  
    [d doLookUp:urlString andOpenAfterwards:YES];
    return nil;*/
}
    
/*
#pragma mark Services
- (void)handleService:(NSPasteboard *)pboard
	     userData:(NSString *)userData
		error:(NSString **)error
{
    NSLog(@"handles service:");
    NSString *pboardString;
    NSArray *types;
    
    types = [pboard types];
    if (![types containsObject:NSStringPboardType]) {
        return;
    }
    pboardString = [pboard stringForType:NSStringPboardType];
    iXDelegate* d=[NSApp delegate];
    [d doLookUp:[pboardString stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding] andOpenAfterwards:YES];
}*/

@end
