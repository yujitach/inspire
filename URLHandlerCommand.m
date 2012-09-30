//
//  URLHandlerCommand.m
//  URLHandler
//
//  Created by Kimbro  Staken on Tue Dec 16 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "URLHandlerCommand.h"
#import "AppDelegate.h"
@implementation URLHandlerCommand

- (id)performDefaultImplementation {
    NSString *urlString = [self directParameter];
//    NSLog(@"handles:%@",urlString);
    if([urlString hasPrefix:@"spires"]){
	[[NSApp appDelegate] handleURL:[NSURL URLWithString:urlString]];
    }
    return nil;
}

@end
