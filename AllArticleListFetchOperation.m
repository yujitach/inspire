//
//  AllArticleListFetchOperation.m
//  spires
//
//  Created by Yuji on 9/5/09.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import "AllArticleListFetchOperation.h"
#import "AllArticleList.h"
#import "DumbOperation.h"
#import "MOC.h"
#include <objc/objc-auto.h>

@interface AllArticleListFetchOperation : NSOperation {
    NSManagedObjectContext* moc;
}
-(id)initWithMOC:(NSManagedObjectContext*)mmoc;
@end

// Warm up the CoreData cache in a background thread.
void warmUpIfSuitable(void)
{
    //This code is called before NSApplicationMain,
    //so we need to start the garbage collector manually to avoid leaks(?)
//    objc_startCollectorThread();
    if([[MOC sharedMOCManager] migrationNeeded]){
	return;
    }
    NSManagedObjectContext*moc=[[MOC sharedMOCManager] managedObjectContext];
    if(moc){
	/* You need utmost care! 
	 The main MOC should be used only from the main thread in the usual situation,
	 but here we warm it up from the background thread, so that
	 it can be done concurrently with the loading of the GUI, etc.
	 */
	NSOperation*op=[[AllArticleListFetchOperation alloc] initWithMOC:moc];
	[[OperationQueues sharedQueue] addOperation:op];
    }
}

@implementation AllArticleListFetchOperation
-(id)initWithMOC:(NSManagedObjectContext*)mmoc;
{
    self=[super init];
    moc=mmoc;
    return self;
}
-(NSString*)description
{
    return @"Warming up the cache...";
}
/*-(void)fetchlist
{
    NSEntityDescription*entity=[NSEntityDescription entityForName:@"AllArticleList" inManagedObjectContext:moc];
    NSFetchRequest*req=[[NSFetchRequest alloc]init];
    [req setEntity:entity];
    [req setPredicate:[NSPredicate predicateWithValue:YES]];
    NSError*error=nil;
    [moc executeFetchRequest:req error:&error];
}
-(void)ad
{
    NSEntityDescription*entity=[NSEntityDescription entityForName:@"ArticleData" inManagedObjectContext:moc];
    NSFetchRequest*req=[[NSFetchRequest alloc]init];
    [req setEntity:entity];
    [req setPredicate:[NSPredicate predicateWithFormat:@"article == nil"]];
    [req setReturnsObjectsAsFaults:YES];
    [req setIncludesPropertyValues:NO];
    NSError*error=nil;
    NSArray*a=[moc executeFetchRequest:req error:&error];    
    NSLog(@"found %d orphaned ArticleData's",(int)[a count]);
    for(NSManagedObject*x in a){
	[[MOC moc] deleteObject:x];
    }
}*/
-(void)fetch:(NSUInteger)count
{
    NSEntityDescription*entity=[NSEntityDescription entityForName:@"Article" inManagedObjectContext:moc];
    NSFetchRequest*req=[[NSFetchRequest alloc]init];
    [req setEntity:entity];
    [req setPredicate:[NSPredicate predicateWithValue:YES]];
    [req setFetchLimit:count];
    [req setResultType:NSManagedObjectResultType];
    [req setReturnsObjectsAsFaults:NO];
    [req setIncludesPropertyValues:YES];
    NSError*error=nil;
    [moc executeFetchRequest:req error:&error];
}
-(void)main
{
    /* the main NIB is arranged so that no access to the main MOC
     is performed until a definite line in the code is reached, 
     rather late in the initialization process.
     There too, the access to the moc is guarded by [moc lock].
     Afterwards, no guard of the main moc is necessary because
     the main moc is used solely from the main thread from that point on.
     */
    [moc lock];
    if(![MOC sharedMOCManager].isUIready)
	[self fetch:0];
    [moc unlock];
}

@end
