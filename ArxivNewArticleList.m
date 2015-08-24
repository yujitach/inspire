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
#if !TARGET_OS_IPHONE
#import "ReloadButton.h"
#endif

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
#else
-(NSImage*)icon
{
    return [NSImage imageNamed:@"arxiv"];
}
-(NSButtonCell*)button
{
    NSButtonCell* button=[[ReloadButton alloc] init];
    [button setTarget:self];
    [button setAction:@selector(reload)];
    return button;
}
#endif
-(BOOL)searchStringEnabled
{
    return NO;
}

@end
