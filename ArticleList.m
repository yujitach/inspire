// 
//  ArticleList.m
//  spires
//
//  Created by Yuji on 08/10/15.
//  Copyright 2008 Y. Tachikawa. All rights reserved.
//

#import "ArticleList.h"

#import "Article.h"

@implementation ArticleList 

@dynamic name;
@dynamic articles;
@dynamic sortDescriptors;
@dynamic searchString;
@dynamic positionInView;
@dynamic parent;
@dynamic children;

-(void)reload
{
}
-(NSImage*)icon
{
    return nil;
}
-(NSButtonCell*)button
{
    return nil;
}
-(BOOL)searchStringEnabled
{
    return YES;
}
-(NSString*)placeholderForSearchField
{
    return @"";
}
@end
