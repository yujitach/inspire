// 
//  ArxivNewArticleList.m
//  spires
//
//  Created by Yuji on 08/10/15.
//  Copyright 2008 Y. Tachikawa. All rights reserved.
//

#import "ArxivNewArticleList.h"
#import "Article.h"
#import "DumbOperation.h"
#import "ArxivNewArticleListReloadOperation.h"

@implementation ArxivNewArticleList 
+(ArxivNewArticleList*)createArXivNewArticleListWithName:(NSString*)s inMOC:(NSManagedObjectContext*)moc
{
    NSEntityDescription*entity=[NSEntityDescription entityForName:@"ArxivNewArticleList" inManagedObjectContext:moc];
    ArxivNewArticleList* mo=(ArxivNewArticleList*)[[NSManagedObject alloc] initWithEntity:entity 
				     insertIntoManagedObjectContext:moc];
    mo.name=s;
    NSSortDescriptor *sd=[[NSSortDescriptor  alloc] initWithKey:@"eprintForSorting" ascending:YES];
    [mo setSortDescriptors:@[sd]];	
    return mo;
}
-(void)reload
{
    [[OperationQueues arxivQueue] addOperation:[[ArxivNewArticleListReloadOperation alloc] initWithArxivNewArticleList:self]];
}
#if TARGET_OS_IPHONE
-(UIImage*)icon
{
    return [UIImage imageNamed:@"arxiv"];
}
-(UIBarButtonItem*)barButtonItem
{
    UIBarButtonItem* bbi=[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(reload)];
    return bbi;
}
#else
-(NSImage*)icon
{
    return [NSImage imageNamed:@"arxiv"];
}
-(BOOL)hasButton
{
    return YES;
}
#endif
-(BOOL)searchStringEnabled
{
    return NO;
}

@end
