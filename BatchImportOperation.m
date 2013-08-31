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
@synthesize generated;
-(BatchImportOperation*)initWithElements:(NSArray*)e // andMOC:(NSManagedObjectContext*)m 
				 citedBy:(Article*)c 
				refersTo:(Article*)r 
		   registerToArticleList:(ArticleList*)l
{
    self=[super init];
    elements=[e copy];
/*    NSInteger cap=[[NSUserDefaults standardUserDefaults] integerForKey:@"batchImportCap"];
    if(cap<100)cap=100;
    if([elements count]>cap){
	elements=[elements objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0,cap)]];
    }*/
    secondMOC=[[MOC sharedMOCManager] createSecondaryMOC];
    citedByTarget=c;
    refersToTarget=r;
    list=l;
    generated=[NSMutableSet set];
    return self;
}
-(BOOL)isEqual:(id)obj
{
    return self==obj;
}

-(NSString*)description
{
    return [NSString stringWithFormat:@"registering to database %d elements",(int)[elements count]];
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
    [req setResultType:NSManagedObjectIDResultType];
    //    [req setRelationshipKeyPathsForPrefetching:[NSArray arrayWithObject:@"article"]];
    //    [req setReturnsObjectsAsFaults:YES];
    [req setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:key
										   ascending:YES]]];
    NSError*error=nil;
    NSArray*datas=[secondMOC executeFetchRequest:req error:&error];

    dispatch_async(dispatch_get_main_queue(),^{
	int i=0,j=0;
	[[MOC moc] disableUndo];
	for(NSManagedObjectID*objID in datas){
	    ArticleData* data=(ArticleData*)[[MOC moc] objectWithID:objID];
	    if(!data.article){
		NSLog(@"inconsistency! stray ArticleData found and removed: %@",data);
		[[MOC moc] deleteObject:data];
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
	    //	NSLog(@"%@=%@ not found, %@",key,[self valueForKey:xmlKey inXMLElement:e],e);
	    Article*article=(Article*)[[NSManagedObject alloc] initWithEntity:articleEntity insertIntoManagedObjectContext:[MOC moc]];
	    [self populatePropertiesOfArticle:article fromXML:e];
	    [generated addObject:article];
	    j++;
	}
	[[MOC moc] enableUndo];
//	NSLog(@"%d new, %d updated, based on %@",j,i,key);
    });
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
    dispatch_async(dispatch_get_main_queue(),^{
//	NSLog(@"total: %d",(int)[generated count]);

	AllArticleList*allArticleList=[AllArticleList allArticleList];
	[allArticleList addArticles:generated];
	
	if(citedByTarget){
	    NSLog(@"added to %@",citedByTarget.title);
	    [citedByTarget addCitedBy:generated];
	}
	if(refersToTarget){
	    NSLog(@"added to %@",refersToTarget.title);
	    [refersToTarget addRefersTo:generated];
	}
	//    NSLog(@"add entry:%@",o);
	if(list){
	    [list addArticles:generated];
	}
	    NSOperation* op=[[InspireCitationNumberRefreshOperation alloc] initWithArticles:generated];
            [op setQueuePriority:NSOperationQueuePriorityVeryLow];
	    [[OperationQueues spiresQueue] addOperation:op];
    });
}

#pragma mark entry point
-(void)main
{
    dispatch_async(dispatch_get_main_queue(),^{
//	[[NSApp appDelegate] startProgressIndicator];
//	[[NSApp appDelegate] postMessage:@"Registering entries..."];
    });
//    NSLog(@"registers %d entries",(int)[elements count]);
    [self batchAddEntriesOfSPIRES:elements];
    dispatch_async(dispatch_get_main_queue(),^{
//	[[NSApp appDelegate] postMessage:nil];
	[[NSApp appDelegate] clearingUpAfterRegistration:nil];
//	[[NSApp appDelegate] stopProgressIndicator];
    });
    
    // need to delay running of the completion handler after all of the async calls!
    void (^handler)(void)=[self completionBlock];
    if(handler){
	[self setCompletionBlock:nil];
	dispatch_async(dispatch_get_main_queue(),^{
	    handler();
	});
    }
}

@end
