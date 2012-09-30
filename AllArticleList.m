// 
//  AllArticleList.m
//  spires
//
//  Created by Yuji on 08/10/15.
//  Copyright 2008 Y. Tachikawa. All rights reserved.
//

#import "AllArticleList.h"
#import "MOC.h"
#import "SpiresHelper.h"
#import "ArticleFetchOperation.h"

static AllArticleList*_allArticleList=nil;
@implementation AllArticleList
{
    ArticleFetchOperation*currentFetchOperation;
}
+(AllArticleList*)allArticleListInMOC:(NSManagedObjectContext*)moc
{
    NSArray* a=nil;
    NSEntityDescription*authorEntity=[NSEntityDescription entityForName:@"AllArticleList" inManagedObjectContext:moc];
    {
	NSFetchRequest*req=[[NSFetchRequest alloc]init];
	[req setEntity:authorEntity];
	NSError*error=nil;
	a=[moc executeFetchRequest:req error:&error];
    }
    if([a count]==1){
	return [a objectAtIndex:0];
    }else if([a count]>1){
	NSLog(@"inconsistency detected ... there are more than one AllArticleLists!");
        AllArticleList*max=[a objectAtIndex:0];
	for(NSUInteger i=1;i<[a count];i++){
	    AllArticleList*al=[a objectAtIndex:i];
            if([al.articles count]>[max.articles count]){
                max=al;
            }
	}
        for(AllArticleList*al in a){
            if(al!=max){
                [moc deleteObject:al];
            }
        }
	return max;
    }else{
	return nil;
    }
}
+(AllArticleList*)createAllArticleListInMOC:(NSManagedObjectContext*)moc
{
    NSEntityDescription*entity=[NSEntityDescription entityForName:@"AllArticleList" inManagedObjectContext:moc];

    AllArticleList* mo=(AllArticleList*)[[NSManagedObject alloc] initWithEntity:entity
				insertIntoManagedObjectContext:nil];
    [mo setValue:@"inspire" forKey:@"name"];
    [mo setValue:[NSNumber numberWithInt:0] forKey:@"positionInView"];
    mo.sortDescriptors=[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"eprintForSorting" ascending:NO]];
    [moc insertObject:mo];	
    
    NSEntityDescription*articleEntity=[NSEntityDescription entityForName:@"Article" inManagedObjectContext:moc];
    NSFetchRequest*req=[[NSFetchRequest alloc]init];
    [req setEntity:articleEntity];
    [req setPredicate:[NSPredicate predicateWithValue:YES]];
    [req setFetchLimit:LOADED_ENTRIES_MAX];
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
-(void)awakeFromFetch
{
    self.articles=nil;
    [self reload];
}
-(NSString*)searchString
{
    return [self primitiveValueForKey:@"searchString"];
}
-(void)setSearchString:(NSString *)newSearchString
{
    [self willChangeValueForKey:@"searchString"];
    [self setPrimitiveValue:newSearchString forKey:@"searchString"];
    [self reload];
    [self didChangeValueForKey:@"searchString"];
}
/*
 
 if(!mark || [s isEqualToString:mark] || [mark hasSuffix:@" "] || ![s hasPrefix:mark]){
 //	NSLog(@"refiltering: %@:",s);
 //	NSLog(@"desc:%@",[self sortDescriptors]);
 previousArray=[super arrangeObjects:objects];
 return previousArray;
 }else{ // shares the same prefix
 NSRange r=[s rangeOfString:mark];
 NSString*t=[s substringFromIndex:r.location+r.length];
 if(t && [t rangeOfString:@" "].location!=NSNotFound ){
 //	    NSLog(@"refiltering!: %@:",s);
 previousArray=[super arrangeObjects:objects];
 }else{
 //	NSLog(@"shortcutting: %@:",s);
 previousArray=[super arrangeObjects:previousArray];
 }
 return previousArray;
 }

 
 */
-(void)reload
{
//    NSLog(@"reloading internally:%@",self.searchString);
    if(currentFetchOperation) {
        [currentFetchOperation cancel];
    }
    currentFetchOperation=[[ArticleFetchOperation alloc] initWithQuery:self.searchString forArticleList:self];
    [[OperationQueues sharedQueue] addOperation:currentFetchOperation];
}
-(NSImage*)icon
{
    return [NSImage imageNamed:@"spires-blue.png"];
}
-(NSString*)placeholderForSearchField
{
    return @"Enter SPIRES query and hit return";
}
@end
