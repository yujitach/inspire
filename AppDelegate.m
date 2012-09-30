//
//  AppDelegate.m
//  spires
//
//  Created by Yuji on 12/8/09.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import "AppDelegate.h"

NSString *ArticleListDropPboardType=@"articleListDropType";
NSString *ArticleDropPboardType=@"articleDropType";


@implementation NSApplication (AppDelegate)
-(id<AppDelegate>)appDelegate
{
    return (id<AppDelegate>)[self delegate];
}
@end


