//
//  BatchImportOperation.m
//  spires
//
//  Created by Yuji on 09/02/07.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import "BatchImportOperation.h"
#import "InspireCitationNumberRefreshOperation.h"
#import "Article.h"
#import "ArticleData.h"
#import "JournalEntry.h"
#import "AllArticleList.h"
#import "AppDelegate.h"
#import "MOC.h"
#import "NSString+magic.h"
#import "ProtoArticle.h"

@implementation BatchImportOperation
{
    NSArray*elements;
    NSString*query;
    NSManagedObjectContext*secondMOC;
    NSMutableSet*generated;
    BOOL updatesCitations;
}
@synthesize generated;
-(BatchImportOperation*)initWithProtoArticles:(NSArray *)d
                                originalQuery:(NSString*)q
                             updatesCitations:(BOOL)b
                                     usingMOC:(NSManagedObjectContext *)moc_
{
    self=[super init];
    elements=d;
    query=[q copy];
    updatesCitations=b;
/*    NSInteger cap=[[NSUserDefaults standardUserDefaults] integerForKey:@"batchImportCap"];
    if(cap<100)cap=100;
    if([elements count]>cap){
	elements=[elements objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0,cap)]];
    }*/
    secondMOC=moc_;
    generated=[NSMutableSet set];
    return self;
}
-(BOOL)isEqual:(id)obj
{
    return self==obj;
}

-(NSString*)description
{
    return @"registering";
}

#pragma mark setters from XML

#pragma mark Main Logic
-(void)treatElements:(NSMutableArray*)a withKey:(NSString*)key
{
    if([a count]==0)
        return ;
    NSMutableDictionary*dict=[NSMutableDictionary dictionary];
    for(NSObject<ProtoArticle>*e in a){
        NSObject<NSCopying>*v=[e valueForKey:key];
        dict[v] = e;
    }
    
    NSArray*values=[dict allKeys];
    values=[values sortedArrayUsingSelector:@selector(compare:)];
    NSEntityDescription*entity=[NSEntityDescription entityForName:@"ArticleData" inManagedObjectContext:secondMOC];
    NSFetchRequest*req=[[NSFetchRequest alloc]init];
    [req setEntity:entity];
    NSPredicate*pred=[NSPredicate predicateWithFormat:@"%K IN %@",key,values];
    [req setPredicate:pred];
    [req setIncludesPropertyValues:NO];
    [req setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:key ascending:YES]]];
    NSError*error=nil;
    NSArray*datas=[secondMOC executeFetchRequest:req error:&error];
    
    for(ArticleData*data in datas){
        if(!data.article){
            NSLog(@"inconsistency! stray ArticleData found and removed: %@",data);
            [secondMOC deleteObject:data];
            continue;
        }
        NSObject<NSCopying>*v=[data valueForKey:key];
        NSObject<ProtoArticle>*e=dict[v];
        [e populatePropertiesOfArticle:data.article];
        [generated addObject:data.article];
        [a removeObject:e];
    }
    NSEntityDescription*articleEntity=[NSEntityDescription entityForName:@"Article" inManagedObjectContext:secondMOC];
    for(NSObject<ProtoArticle>*e in a){
        Article*article=(Article*)[[NSManagedObject alloc] initWithEntity:articleEntity insertIntoManagedObjectContext:secondMOC];
        [e populatePropertiesOfArticle:article];
        [generated addObject:article];
    }
}
-(void)batchAddEntriesOfSPIRES:(NSArray*)a
{
    NSMutableArray*lookForEprint=[NSMutableArray array];
    NSMutableArray*lookForSpiresKey=[NSMutableArray array];
    NSMutableArray*lookForDOI=[NSMutableArray array];
    NSMutableArray*lookForTitle=[NSMutableArray array];
    for(NSObject<ProtoArticle>*element in a){
        if(element.eprint){
            [lookForEprint addObject:element];
        }else if(element.spiresKey){
            [lookForSpiresKey addObject:element];
        }else if(element.doi){
            [lookForDOI addObject:element];
        }else if(element.title){
            [lookForTitle addObject:element];
        }
    }
    
    [self treatElements:lookForEprint withKey:@"eprint"];
    [self treatElements:lookForSpiresKey withKey:@"spiresKey"];
    [self treatElements:lookForDOI withKey:@"doi"];
    [self treatElements:lookForTitle withKey:@"title"];
    
    // you shouldn't mix dispatch to the main thread and performSelectorOnMainThread,
    // they're not guaranteed to be serialized!
    // but the code that motivated this comment was gone.
    
    AllArticleList*allArticleList=[AllArticleList allArticleListInMOC:secondMOC];
    [allArticleList addArticles:generated];
    
    if([query hasPrefix:@"c "]){
        Article*citedByTarget=[Article articleForQuery:query inMOC:secondMOC];
        if(!citedByTarget){
            NSLog(@"citedBy target article not found. strange.");
        }else{
            NSLog(@"added to %@",citedByTarget.title);
            [citedByTarget addCitedBy:generated];
        }
    }
    if([query hasPrefix:@"r "]){
        Article*refersToTarget=[Article articleForQuery:query inMOC:secondMOC];
        if(!refersToTarget){
            NSLog(@"refersTo target article not found. strange.");
        }else{
            NSLog(@"added to %@",refersToTarget.title);
            [refersToTarget addRefersTo:generated];
        }
    }
    if(updatesCitations && generated.count>0){
        NSOperation* op=[[InspireCitationNumberRefreshOperation alloc] initWithArticles:generated];
        [op setQueuePriority:NSOperationQueuePriorityVeryLow];
        [[OperationQueues spiresQueue] addOperation:op];
    }
}

#pragma mark entry point
-(void)main
{
    [secondMOC performBlockAndWait:^{
            [self batchAddEntriesOfSPIRES:elements];
            [secondMOC save:NULL];
    }];
}

@end
