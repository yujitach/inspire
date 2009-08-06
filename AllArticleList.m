// 
//  AllArticleList.m
//  spires
//
//  Created by Yuji on 08/10/15.
//  Copyright 2008 Y. Tachikawa. All rights reserved.
//

#import "AllArticleList.h"


@implementation AllArticleList 

+(AllArticleList*)allArticleListInMOC:(NSManagedObjectContext*)moc
{
    NSArray* a=nil;
    NSEntityDescription*authorEntity=[NSEntityDescription entityForName:@"AllArticleList" inManagedObjectContext:moc];
    {
	NSFetchRequest*req=[[NSFetchRequest alloc]init];
	[req setEntity:authorEntity];
	NSPredicate*pred=[NSPredicate predicateWithFormat:@"name = 'spires'"];
	[req setPredicate:pred];
	NSError*error=nil;
	a=[moc executeFetchRequest:req error:&error];
    }
    if([a count]==1){
	return [a objectAtIndex:0];
    }else if([a count]>1){
	NSLog(@"inconsistency detected ... there are more than one AllArticleLists!");
	for(int i=1;i<[a count];i++){
	    AllArticleList*al=[a objectAtIndex:i];
	    [moc deleteObject:al];
	}
	return [a objectAtIndex:0];
    }else{
	AllArticleList* mo=[[NSManagedObject alloc] initWithEntity:authorEntity 
				     insertIntoManagedObjectContext:nil];
	[mo setValue:@"spires" forKey:@"name"];
	[moc insertObject:mo];	

	NSEntityDescription*entity=[NSEntityDescription entityForName:@"Article" inManagedObjectContext:moc];
	NSFetchRequest*req=[[NSFetchRequest alloc]init];
	[req setEntity:entity];
	[req setPredicate:[NSPredicate predicateWithValue:YES]];
	NSError*error=nil;
	a=[moc executeFetchRequest:req error:&error];
	NSSet* s=[NSSet setWithArray:a];
	[mo addArticles:s];
	[moc save:nil];
	return mo;
    }
}
-(void)reload
{
}
-(NSImage*)icon
{
    return [NSImage imageNamed:@"spires-blue.ico"];
}
-(NSString*)placeholderForSearchField
{
    return @"Enter SPIRES query and hit return";
}
@end
