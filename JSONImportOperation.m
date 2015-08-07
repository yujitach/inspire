//
//  JSONImportOperation.m
//  inspire
//
//  Created by Yuji on 2015/08/07.
//
//

#import "JSONImportOperation.h"
#import "Article.h"
#import "ArticleData.h"
#import "JournalEntry.h"
#import "AllArticleList.h"
#import "AppDelegate.h"
#import "MOC.h"
#import "NSString+magic.h"
#import "DumbOperation.h"
#import "JSONArticle.h"

@implementation JSONImportOperation

{
    NSArray*jsonArray;
    NSString*query;
    NSManagedObjectContext*secondMOC;
    NSMutableSet*generated;
    dispatch_group_t group;
    NSDateFormatter*df;
}
@synthesize generated;
-(instancetype)initWithJSONArray:(NSArray*)a originalQuery:(NSString*)search
{
    self=[super init];
    jsonArray=a;
    query=[search copy];
    [jsonArray writeToFile:@"/tmp/spiresTemporary.xml" atomically:YES];
    secondMOC=[[MOC sharedMOCManager] createSecondaryMOC];
    generated=[NSMutableSet set];
    df=[[NSDateFormatter alloc] init];
    [df setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSS"];
    group=dispatch_group_create();
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

#pragma mark setters from JSON
-(void)setJournalToArticle:(Article*)o fromJSON:(JSONArticle*)a
{
    if(o.journal)return;
    NSDictionary*pub=a.publicationInfo;
    JournalEntry*j=[JournalEntry journalEntryWithName:pub[@"title"]
                                               Volume:pub[@"volume"]
                                                 Year:@([pub[@"year"] integerValue])
                                                 Page:pub[@"pagenation"]
                                                inMOC:[o managedObjectContext]];
    o.journal=j;
}
-(void)populatePropertiesOfArticle:(Article*)o fromJSON:(JSONArticle*)element
{
    
    o.inspireKey=@([element.recid integerValue]);
    o.eprint=element.eprint;
    o.title=element.title;
    // Here I'm cheating: -setAuthorNames: puts the collaboration name in the author list,
    // so "collaboration" needs to be set up before that
    o.collaboration=element.collaboration;
    
    [o setAuthorNames:element.authors];
    
    o.abstract=element.abstract;
    o.pages=element.pages;
    o.citecount=element.citecount;
    o.doi=element.doi;
    o.comments=element.comment;
    
    [self setJournalToArticle:o fromJSON:element];
    o.date=[df dateFromString:element.dateString];
    
    if(o.abstract){
        NSString*abstract=o.abstract;
        abstract=[abstract stringByReplacingOccurrencesOfString:@"&" withString:@"&amp;"];
        abstract=[abstract stringByReplacingOccurrencesOfString:@"<" withString:@"&lt;"];
        abstract=[abstract stringByReplacingOccurrencesOfString:@">" withString:@"&gt;"];
        o.abstract=abstract;
    }

    
}

#pragma mark Main Logic
-(void)treatElements:(NSMutableArray*)a withJSONKey:(NSString*)jsonKey andKey:(NSString*)key
{
    if([a count]==0)
        return ;
    NSMutableDictionary*dict=[NSMutableDictionary dictionary];
    for(JSONArticle*e in a){
        NSString*v=[e valueForKey:jsonKey];
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
    
    int i=0,j=0;
    for(ArticleData*data in datas){
        if(!data.article){
            NSLog(@"inconsistency! stray ArticleData found and removed: %@",data);
            [secondMOC deleteObject:data];
            continue;
        }
        NSString*v=[data valueForKey:key];
        if([v isKindOfClass:[NSNumber class]]){
            v=[(NSNumber*)v stringValue];
        }
        JSONArticle*e=dict[v];
        [self populatePropertiesOfArticle:data.article fromJSON:e];
        [generated addObject:data.article];
        [a removeObject:e];
        i++;
    }
    NSEntityDescription*articleEntity=[NSEntityDescription entityForName:@"Article" inManagedObjectContext:secondMOC];
    for(JSONArticle*e in a){
        Article*article=(Article*)[[NSManagedObject alloc] initWithEntity:articleEntity insertIntoManagedObjectContext:secondMOC];
        [self populatePropertiesOfArticle:article fromJSON:e];
        [generated addObject:article];
        j++;
    }
}

-(void)batchAddEntriesOfSPIRES:(NSArray*)a
{
    NSMutableArray*lookForEprint=[NSMutableArray array];
    NSMutableArray*lookForInspireKey=[NSMutableArray array];
    NSMutableArray*lookForTitle=[NSMutableArray array];
    for(NSDictionary*dic in a){
        JSONArticle*element=[[JSONArticle alloc] initWithDictionary:dic];
        NSString*eprint=element.eprint;
        NSString*inspireKey=element.recid;
        NSString*title=element.title;
        if(eprint){
            [lookForEprint addObject:element];
        }else if(inspireKey){
            [lookForInspireKey addObject:element];
        }else if(title){
            [lookForTitle addObject:element];
        }
    }
    
    [self treatElements:lookForEprint withJSONKey:@"eprint" andKey:@"eprint"];
    [self treatElements:lookForInspireKey withJSONKey:@"recid" andKey:@"inspireKey"];
    [self treatElements:lookForTitle withJSONKey:@"title" andKey:@"title"];
    
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
}

#pragma mark entry point
-(void)main
{
    
    [secondMOC performBlockAndWait:^{
        NSLog(@"spires returned %d entries",(int)[jsonArray count]);
        [self batchAddEntriesOfSPIRES:jsonArray];
        [secondMOC save:NULL];
    }];
    dispatch_group_async(group,dispatch_get_main_queue(),^{
        [[MOC moc] save:NULL];
        //        [[NSApp appDelegate] clearingUpAfterRegistration:nil];
    });
    
    // need to delay running of the completion handler after all of the async calls!
    void (^handler)(void)=[self completionBlock];
    if(handler){
        [self setCompletionBlock:nil];
        dispatch_group_async(group,dispatch_get_main_queue(),^{
            handler();
        });
    }
    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
    dispatch_release(group);
}

@end
