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
#import "ReloadButton.h"

@implementation ArxivNewArticleList 
+(ArxivNewArticleList*)arXivNewArticleListWithName:(NSString*)s inMOC:(NSManagedObjectContext*)moc
{
    NSEntityDescription*authorEntity=[NSEntityDescription entityForName:@"ArxivNewArticleList" inManagedObjectContext:moc];
    NSFetchRequest*req=[[NSFetchRequest alloc]init];
    [req setEntity:authorEntity];
    NSPredicate*pred=[NSPredicate predicateWithFormat:@"name = %@",s];
    [req setPredicate:pred];
    NSError*error=nil;
    NSArray*a=[moc executeFetchRequest:req error:&error];
    if([a count]>0){
	return [a objectAtIndex:0];
    }else{
	ArxivNewArticleList* mo=[[NSManagedObject alloc] initWithEntity:authorEntity 
				    insertIntoManagedObjectContext:moc];
	[mo setValue:s forKey:@"name"];
	NSSortDescriptor *sd=[[NSSortDescriptor  alloc] initWithKey:@"eprintForSorting" ascending:YES];
	[mo setSortDescriptors:[NSArray arrayWithObjects:sd,nil]];	
	return mo;
    }
}
-(void)reload
{
    [[OperationQueues arxivQueue] addOperation:[[ArxivNewArticleListReloadOperation alloc] initWithArxivNewArticleList:self]];
}
-(NSImage*)icon
{
    return [NSImage imageNamed:@"arxiv.png"];
}
-(NSButtonCell*)button
{
    NSButtonCell* button=[[ReloadButton alloc] init];
    [button setTarget:self];
    [button setAction:@selector(reload)];
    return button;
}
-(BOOL)searchStringEnabled
{
    return NO;
}

@end
