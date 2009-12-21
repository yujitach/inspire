//
//  HistoryController.m
//  spires
//
//  Created by Yuji on 08/10/28.
//  Copyright 2008 Y. Tachikawa. All rights reserved.
//

#import "HistoryController.h"
//#import "SideTableViewController.h"
#import "SideOutlineViewController.h"
#import "ArticleList.h"
@interface HistoryEntry: NSObject
{
    NSString*searchString;
    ArticleList* articleList;
    Article* article;
}
@property(copy)     NSString*searchString;
@property ArticleList* articleList;
@property Article* article;
@end

@implementation HistoryEntry
@synthesize searchString;
@synthesize articleList;
@synthesize article;
@end

@interface HistoryController ()
-(IBAction)segControlClicked:(id)sender;
@end

@implementation HistoryController
- (BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)anItem
{
    SEL theAction = [anItem action];
    if(theAction==@selector(forward:)){
	return idx<[array count]-1;
    }
    
    if(theAction==@selector(backward:)){
	return idx!=0;
    }
    
    return NO;
}
-(void)reflect
{
    if([array count]>0){
	HistoryEntry*entry=[array objectAtIndex:idx-1];
//	[articleListController setSelectedObjects:[NSArray arrayWithObject:entry.articleList]];
	[sideTableViewController selectArticleList:entry.articleList];
/*
 ArticleList*al=entry.articleList;
	[articleListController setSelectionIndexPath:[NSIndexPath idxPathWithIndex:[[al positionInView] intValue]]];
 */
//	NSLog(@"%@",entry.article);
	if(entry.article)//[ac setSelectedObjects:[NSArray arrayWithObject:entry.article]];
	    [self performSelector:@selector(setArticle:) withObject:entry.article afterDelay:0.1];
	entry.articleList.searchString=entry.searchString;
    }
    [sc setEnabled:((idx>1)?YES:NO) forSegment:0];
    [sc setEnabled:((idx<[array count])?YES:NO) forSegment:1];
}
-(void)setArticle:(Article*)a
{
    [ac setSelectedObjects:[NSArray arrayWithObject:a]];
}
- (void)awakeFromNib
{
    idx=0;
    array=[NSMutableArray array];
    [[sc cell] setTag:0 forSegment:0];
    [[sc cell] setTag:1 forSegment:1];
    [sc setTarget:self];
    [sc setAction:@selector(segControlClicked:)];
    [self reflect];
}
-(IBAction)forward:(id)sender
{
//    NSLog(@"f");
    if(idx<[array count]){
	idx++;
	[self reflect];
    }
}
-(IBAction)backward:(id)sender
{
//    NSLog(@"b");
    if(idx>0){
	idx--;
	[self reflect];
    }
}
-(IBAction)mark:(id)sender
{
    ArticleList*al=[sideTableViewController currentArticleList];
    //[[articleListController selectedObjects] objectAtIndex:0];
    Article*a=nil;
    if([[ac selectedObjects] count]>0){
	a=[[ac selectedObjects] objectAtIndex:0];
    }
    HistoryEntry*entry=[[HistoryEntry alloc]init];
    entry.searchString=al.searchString;
    entry.articleList=al;
    entry.article=a;
    if(idx != [array count]){
	NSMutableArray*ar=[NSMutableArray array];
	for(int i=0;i<idx;i++){
	    [ar addObject:[array objectAtIndex:i]];
	}
	array=ar;
    }
    HistoryEntry*p=[array lastObject];
    if(p.articleList == entry.articleList && [p.searchString isEqualToString:entry.searchString]){
	// do nothing
    }else{
	[array addObject:entry];
	idx++;	    
    }
    if(idx>1)[sc setEnabled:YES forSegment:0];
    [sc setEnabled:NO forSegment:1];
}
- (IBAction)segControlClicked:(id)sender
{
    NSInteger clickedSegment = [sc selectedSegment];
    NSInteger clickedSegmentTag = [[sc cell] tagForSegment:clickedSegment];
    if(clickedSegmentTag==0){
	[self backward:sender];
    }else{
	[self forward:sender];
    }
}
@end
