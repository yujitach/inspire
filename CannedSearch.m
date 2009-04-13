//
//  CannedSearch.m
//  spires
//
//  Created by Yuji on 4/12/09.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import "CannedSearch.h"
#import "SpiresHelper.h"
#import "NSManagedObjectContext+TrivialAddition.h"
#import "DumbOperation.h"
#import "SpiresQueryOperation.h"
#import "ArticleListReloadOperation.h"
@implementation CannedSearch
+(CannedSearch*)cannedSearchWithName:(NSString*)s inMOC:(NSManagedObjectContext*)moc
{
    NSEntityDescription*entity=[NSEntityDescription entityForName:@"CannedSearch" inManagedObjectContext:moc];
    NSFetchRequest*req=[[NSFetchRequest alloc]init];
    [req setEntity:entity];
    NSPredicate*pred=[NSPredicate predicateWithFormat:@"name = %@",s];
    [req setPredicate:pred];
    NSError*error=nil;
    NSArray*a=[moc executeFetchRequest:req error:&error];
    if([a count]>0){
	return [a objectAtIndex:0];
    }else{
	CannedSearch* mo=[[NSManagedObject alloc] initWithEntity:entity 
				       insertIntoManagedObjectContext:moc];
	[mo setValue:s forKey:@"name"];
	return mo;
    }    
}
-(void)reloadLocal
{
//    NSLog(@"locally reloading canned search %@", self.name);
    if(![self searchString] || [[self searchString] isEqualToString:@""]){
	return;
    }
    NSPredicate*predicate=[[SpiresHelper sharedHelper] predicateFromSPIRESsearchString:[self searchString]];
    
    NSEntityDescription*articleEntity=[NSEntityDescription entityForName:@"Article" inManagedObjectContext:[self managedObjectContext]];
    NSFetchRequest*req=[[NSFetchRequest alloc]init];
    [req setEntity:articleEntity];
    [req setPredicate:predicate];
    NSError*error=nil;
    NSArray*a=[[self managedObjectContext] executeFetchRequest:req error:&error];
    NSSet*set=[NSSet setWithArray:a];
    modifying=YES;
    [[self managedObjectContext] disableUndo];
    [self willChangeValueForKey:@"articles"];
    [self setPrimitiveValue:set forKey:@"articles"];
    [self didChangeValueForKey:@"articles"];
    [[self managedObjectContext] enableUndo];
    modifying=NO;
}
-(void)reload
{
    if(state==0){
	state=1;
	[[DumbOperationQueue spiresQueue] addOperation:[[SpiresQueryOperation alloc] initWithQuery:[self searchString]
											    andMOC:[self managedObjectContext]]];
	[[DumbOperationQueue spiresQueue] addOperation:[[ArticleListReloadOperation alloc] initWithArticleList:self]];
    }else if(state==1){
	state=2;
	[[DumbOperationQueue spiresQueue] addOperation:[[ArticleListReloadOperation alloc] initWithArticleList:self]];
    }else if(state==2){
	[self reloadLocal];
	state=0;
    }
}
-(NSSet*)articles
{
    if(!modifying){
	[self reloadLocal];
    }
    return [self primitiveValueForKey:@"articles"];
}
-(void)setSearchString:(NSString*)s
{
    if(!modifying){
	[self reloadLocal];
    }
    [self setPrimitiveValue:s forKey:@"searchString"];
}
-(NSImage*)icon
{
    return [NSImage imageNamed:@"canned-search.png"];
}
-(NSString*)placeholderForSearchField
{
    return @"Enter SPIRES query and hit return";
}

@end
