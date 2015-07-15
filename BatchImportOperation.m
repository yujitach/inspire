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

@implementation BatchImportOperation
{
    NSData*xmlData;
    NSString*query;
    NSManagedObjectContext*secondMOC;
    NSMutableSet*generated;
    dispatch_group_t group;
}
@synthesize generated;
-(BatchImportOperation*)initWithXMLData:(NSData*)d
                          originalQuery:(NSString*)q;
{
    self=[super init];
    xmlData=d;
    query=[q copy];
    [xmlData writeToFile:@"/tmp/spiresTemporary.xml" atomically:YES];
/*    NSInteger cap=[[NSUserDefaults standardUserDefaults] integerForKey:@"batchImportCap"];
    if(cap<100)cap=100;
    if([elements count]>cap){
	elements=[elements objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0,cap)]];
    }*/
    secondMOC=[[MOC sharedMOCManager] createSecondaryMOC];
    generated=[NSMutableSet set];
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

#pragma mark setters from XML
-(NSString*)valueForKey:(NSString*)key inXMLElement:(NSXMLElement*)element
{
    NSArray*a=[element elementsForName:key];
    if(a==nil||[a count]==0)return nil;
    NSString*s=[a[0] stringValue];
    if(!s || [s isEqualToString:@""])
	return nil;
    return s;
}
-(void)setIntToArticle:(Article*)a forKey:(NSString*)key inXMLElement:(NSXMLElement*)e
{
    NSString* s=[self valueForKey:key inXMLElement:e];
    if(s)
	[a setValue:@([s intValue]) forKey:key];
}
-(void)setStringToArticle:(Article*)a forKey:(NSString*)key inXMLElement:(NSXMLElement*)e
{
    NSString* s=[self valueForKey:key inXMLElement:e];
    if(s){
	//	s=[s stringByExpandingAmpersandEscapes];
	[a setValue:s forKey:key];
    }
}
-(void)setStringToArticle:(Article*)a forKey:(NSString*)key inXMLElement:(NSXMLElement*)e ofKey:(NSString*)xmlKey
{
    NSString* s=[self valueForKey:xmlKey inXMLElement:e];
    if(s)
	[a setValue:s forKey:key];
}
-(void)setJournalToArticle:(Article*)a inXMLElement:(NSXMLElement*)e
{
    if(a.journal)return;
    NSArray* x=[e elementsForName:@"journal"];
    if(!x || [x count]==0) return;
    NSXMLElement* element=x[0];
    NSString *name=[self valueForKey:@"name" inXMLElement:element];
    if(!name || [name isEqualToString:@""])return;
    JournalEntry*j=[JournalEntry journalEntryWithName:name
					       Volume:[self valueForKey:@"volume"  inXMLElement:element] 
						 Year:[[self valueForKey:@"year"  inXMLElement:element] intValue] 
						 Page:[self valueForKey:@"page" inXMLElement:element] 
						inMOC:[a managedObjectContext]];
    a.journal=j;
}
-(void)setDateToArticle:(Article*)a inXMLElement:(NSXMLElement*)e
{
    NSString*dateString=[self valueForKey:@"date" inXMLElement:e];
    if(!dateString || [dateString length]!=8)return;
    NSString*year=[dateString substringToIndex:4];
    NSString*month=[dateString substringWithRange:NSMakeRange(4,2)];
    NSDate*date=[NSDate dateWithString:[NSString stringWithFormat:@"%@-%@-01 00:00:00 +0000",year,month]];
    a.date=date;
}
-(void)populatePropertiesOfArticle:(Article*)o fromXML:(NSXMLElement*)element
{
    NSString*eprint=[self valueForKey:@"eprint" inXMLElement:element];
    NSString*spiresKey=[self valueForKey:@"spires_key" inXMLElement:element];
    NSString*title=[self valueForKey:@"title" inXMLElement:element];

    o.spiresKey=@([spiresKey integerValue]);
    o.eprint=eprint;
    o.title=title;
    
    NSError*error=nil;
    NSArray*a=[element nodesForXPath:@"authaffgrp/author" error:&error];
    NSMutableArray* array=[NSMutableArray array];

    for(NSXMLElement*e in a){
	[array addObject:[e stringValue]];
    }
    
    // Here I'm cheating: -setAuthorNames: puts the collaboration name in the author list,
    // so "collaboration" needs to be set up before that
    [self setStringToArticle:o forKey:@"collaboration" inXMLElement:element];
    [o setAuthorNames:array];
    
    
    [self setStringToArticle:o forKey:@"doi" inXMLElement:element];
    [self setStringToArticle:o forKey:@"abstract" inXMLElement:element];
    [self setStringToArticle:o forKey:@"comments" inXMLElement:element];
    [self setStringToArticle:o forKey:@"memo" inXMLElement:element];
    [self setStringToArticle:o forKey:@"spicite" inXMLElement:element];
    [self setIntToArticle:o forKey:@"citecount" inXMLElement:element];
    [self setIntToArticle:o forKey:@"version" inXMLElement:element];
    [self setIntToArticle:o forKey:@"pages" inXMLElement:element];
    [self setJournalToArticle:o inXMLElement:element];
    [self setDateToArticle:o inXMLElement:element];
    
    if(o.abstract){
        NSString*abstract=o.abstract;
        abstract=[abstract stringByReplacingOccurrencesOfString:@"&" withString:@"&amp;"];
	abstract=[abstract stringByReplacingOccurrencesOfString:@"<" withString:@"&lt;"];
	abstract=[abstract stringByReplacingOccurrencesOfString:@">" withString:@"&gt;"];
        o.abstract=abstract;
    }
    
    NSString*inspireKey=[self valueForKey:@"inspire_key" inXMLElement:element];
    if(inspireKey){
	o.inspireKey=@([inspireKey integerValue]);
    }
    
}

#pragma mark Main Logic
-(void)treatElements:(NSMutableArray*)a withXMLKey:(NSString*)xmlKey andKey:(NSString*)key
{
    if([a count]==0)
        return ;
    NSMutableDictionary*dict=[NSMutableDictionary dictionary];
    for(NSXMLElement*e in a){
        NSString*v=[self valueForKey:xmlKey inXMLElement:e];
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
        NSXMLElement*e=dict[v];
        [self populatePropertiesOfArticle:data.article fromXML:e];
        [generated addObject:data.article];
        [a removeObject:e];
        i++;
    }
    NSEntityDescription*articleEntity=[NSEntityDescription entityForName:@"Article" inManagedObjectContext:[MOC moc]];
    for(NSXMLElement*e in a){
        Article*article=(Article*)[[NSManagedObject alloc] initWithEntity:articleEntity insertIntoManagedObjectContext:secondMOC];
        [self populatePropertiesOfArticle:article fromXML:e];
        [generated addObject:article];
        j++;
    }
}
-(void)batchAddEntriesOfSPIRES:(NSArray*)a
{
    NSMutableArray*lookForEprint=[NSMutableArray array];
    NSMutableArray*lookForSpiresKey=[NSMutableArray array];
    NSMutableArray*lookForDOI=[NSMutableArray array];
    NSMutableArray*lookForTitle=[NSMutableArray array];
    for(NSXMLElement*element in a){
        NSString*eprint=[self valueForKey:@"eprint" inXMLElement:element];
        NSString*spiresKey=[self valueForKey:@"spires_key" inXMLElement:element];
        NSString*doi=[self valueForKey:@"doi" inXMLElement:element];
        NSString*title=[self valueForKey:@"title" inXMLElement:element];
        if(eprint){
            [lookForEprint addObject:element];
        }else if(spiresKey){
            [lookForSpiresKey addObject:element];
        }else if(doi){
            [lookForDOI addObject:element];
        }else if(title){
            [lookForTitle addObject:element];
        }
    }
    
    [self treatElements:lookForEprint withXMLKey:@"eprint" andKey:@"eprint"];
    [self treatElements:lookForSpiresKey withXMLKey:@"spires_key" andKey:@"spiresKey"];
    [self treatElements:lookForTitle withXMLKey:@"title" andKey:@"title"];
    
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
    if(generated.count>0){
        NSOperation* op=[[InspireCitationNumberRefreshOperation alloc] initWithArticles:generated];
        [op setQueuePriority:NSOperationQueuePriorityVeryLow];
        [[OperationQueues spiresQueue] addOperation:op];
    }
}

#pragma mark entry point
-(void)main
{
    NSXMLDocument*doc=[[NSXMLDocument alloc] initWithData:xmlData options:NSXMLNodeOptionsNone error:NULL];
    NSXMLElement* root=[doc rootElement];
    NSArray*elements=[root elementsForName:@"document"];
    NSLog(@"spires returned %d entries",(int)[elements count]);
    
    [secondMOC performBlockAndWait:^{
            [self batchAddEntriesOfSPIRES:elements];
            [secondMOC save:NULL];
    }];
    dispatch_group_async(group,dispatch_get_main_queue(),^{
        [[MOC moc] save:NULL];
        [[NSApp appDelegate] clearingUpAfterRegistration:nil];
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
