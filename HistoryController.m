//
//  HistoryController.m
//  spires
//
//  Created by Yuji on 08/10/28.
//  Copyright 2008 Y. Tachikawa. All rights reserved.
//

#import "HistoryController.h"
#import "SideTableViewController.h"
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

@implementation HistoryController
- (BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)anItem
{
    SEL theAction = [anItem action];
    if(theAction==@selector(forward:)){
	return index<[array count]-1;
    }
    
    if(theAction==@selector(backward:)){
	return index!=0;
    }
    
    return NO;
}
-(void)reflect
{
    if([array count]>0){
	HistoryEntry*entry=[array objectAtIndex:index-1];
//	[articleListController setSelectedObjects:[NSArray arrayWithObject:entry.articleList]];
	[sideTableViewController selectArticleList:entry.articleList];
/*
 ArticleList*al=entry.articleList;
	[articleListController setSelectionIndexPath:[NSIndexPath indexPathWithIndex:[[al positionInView] intValue]]];
 */
//	NSLog(@"%@",entry.article);
	if(entry.article)//[ac setSelectedObjects:[NSArray arrayWithObject:entry.article]];
	    [self performSelector:@selector(setArticle:) withObject:entry.article afterDelay:0.1];
	entry.articleList.searchString=entry.searchString;
    }
    [sc setEnabled:((index>1)?YES:NO) forSegment:0];
    [sc setEnabled:((index<[array count])?YES:NO) forSegment:1];
}
-(void)setArticle:(Article*)a
{
    [ac setSelectedObjects:[NSArray arrayWithObject:a]];
}
- (void)awakeFromNib
{
    index=0;
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
    if(index<[array count]){
	index++;
	[self reflect];
    }
}
-(IBAction)backward:(id)sender
{
//    NSLog(@"b");
    if(index>0){
	index--;
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
    if(index != [array count]){
	NSMutableArray*ar=[NSMutableArray array];
	for(int i=0;i<index;i++){
	    [ar addObject:[array objectAtIndex:i]];
	}
	array=ar;
    }
    [array addObject:entry];
    index++;
    if(index>1)[sc setEnabled:YES forSegment:0];
    [sc setEnabled:NO forSegment:1];
}
- (IBAction)segControlClicked:(id)sender
{
    int clickedSegment = [sc selectedSegment];
    int clickedSegmentTag = [[sc cell] tagForSegment:clickedSegment];
    if(clickedSegmentTag==0){
	[self backward:sender];
    }else{
	[self forward:sender];
    }
}
@end
