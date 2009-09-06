//
//  AllArticleListFetchOperation.m
//  spires
//
//  Created by Yuji on 9/5/09.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import "AllArticleListFetchOperation.h"
#import "AllArticleList.h"
#import "MOC.h"

@implementation AllArticleListFetchOperation
-(id)init
{
    self=[super init];
    secondMOC=[MOC createSecondaryMOC];
    return self;
}
-(void)fetchlist
{
    NSEntityDescription*entity=[NSEntityDescription entityForName:@"AllArticleList" inManagedObjectContext:secondMOC];
    NSFetchRequest*req=[[NSFetchRequest alloc]init];
    [req setEntity:entity];
    [req setPredicate:[NSPredicate predicateWithValue:YES]];
    NSError*error=nil;
    NSArray*a=[secondMOC executeFetchRequest:req error:&error];
}
-(void)fetch:(NSUInteger)count
{
    NSEntityDescription*entity=[NSEntityDescription entityForName:@"Article" inManagedObjectContext:secondMOC];
    NSFetchRequest*req=[[NSFetchRequest alloc]init];
    [req setEntity:entity];
    [req setPredicate:[NSPredicate predicateWithValue:YES]];
    [req setFetchLimit:count];
    [req setResultType:NSManagedObjectIDResultType];
    NSError*error=nil;
    NSArray*a=[secondMOC executeFetchRequest:req error:&error];
/*    dispatch_async(dispatch_get_main_queue(),^{
	NSMutableSet*x=[NSMutableSet set];
	for(NSManagedObjectID* objectID in a){
	    [x addObject:[mainMOC objectWithID:objectID]];
	}
	[list addArticles:x];	
    });*/
}
-(void)main
{
    [self fetch:0];
    [self fetchlist];
}

@end
