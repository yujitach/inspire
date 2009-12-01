// 
//  AllArticleList.m
//  spires
//
//  Created by Yuji on 08/10/15.
//  Copyright 2008 Y. Tachikawa. All rights reserved.
//

#import "AllArticleList.h"
#import "MOC.h"

static AllArticleList*_allArticleList=nil;
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
	return nil;
    }
}
+(AllArticleList*)createAllArticleListInMOC:(NSManagedObjectContext*)moc
{
    NSEntityDescription*entity=[NSEntityDescription entityForName:@"AllArticleList" inManagedObjectContext:moc];

    AllArticleList* mo=[[NSManagedObject alloc] initWithEntity:entity
				insertIntoManagedObjectContext:nil];
    [mo setValue:@"spires" forKey:@"name"];
    [mo setValue:[NSNumber numberWithInt:0] forKey:@"positionInView"];
    [moc insertObject:mo];	
    
    NSEntityDescription*articleEntity=[NSEntityDescription entityForName:@"Article" inManagedObjectContext:moc];
    NSFetchRequest*req=[[NSFetchRequest alloc]init];
    [req setEntity:articleEntity];
    [req setPredicate:[NSPredicate predicateWithValue:YES]];
    NSError*error=nil;
    NSArray*a=[moc executeFetchRequest:req error:&error];
    NSSet* s=[NSSet setWithArray:a];
    [mo addArticles:s];
    error=nil;
    [moc save:&error];
    return mo;    
}
+(AllArticleList*)allArticleList
{
    if(!_allArticleList){
	_allArticleList=[self allArticleListInMOC:[MOC moc]];
    }
    if(!_allArticleList){
	_allArticleList=[self createAllArticleListInMOC:[MOC moc]];
    }
    return _allArticleList;
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
