//
//  BatchImportOperation.m
//  spires
//
//  Created by Yuji on 09/02/07.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import "BatchImportOperation.h"
#import "BatchBibQueryOperation.h"
#import "Article.h"
#import "ArticleData.h"
#import "JournalEntry.h"
#import "AllArticleList.h"
#import "NSManagedObjectContext+TrivialAddition.h"
#import "AppDelegate.h"
#import "MOC.h"
#import "ProgressIndicatorController.h"
#import "NSString+magic.h"

@implementation BatchImportOperation
-(BatchImportOperation*)initWithElements:(NSArray*)e // andMOC:(NSManagedObjectContext*)m 
				 citedBy:(Article*)c refersTo:(Article*)r registerToArticleList:(ArticleList*)
l{
    [super init];
    elements=[e copy];
    NSInteger cap=[[NSUserDefaults standardUserDefaults] integerForKey:@"batchImportCap"];
    if(cap<100)cap=100;
    if([elements count]>cap){
	elements=[elements objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0,cap)]];
    }
    secondMOC=[MOC createSecondaryMOC];
    citedByTarget=c;
    if(citedByTarget){
	NSLog(@"citedByTarget:%@",citedByTarget.title);
    }
    refersToTarget=r;
    list=l;
    generated=[NSMutableSet set];
    return self;
}
-(void)setParent:(NSOperation*)p
{
    parent=p;
    if(parent){
	[parent addDependency:self];
    }    
}
-(BOOL)isEqual:(id)obj
{
    return self==obj;
}

-(NSString*)description
{
    return [NSString stringWithFormat:@"registering to database %d elements",[elements count]];
}

#pragma mark setters from XML
-(NSString*)valueForKey:(NSString*)key inXMLElement:(NSXMLElement*)element
{
    NSArray*a=[element elementsForName:key];
    if(a==nil||[a count]==0)return nil;
    NSString*s=[[a objectAtIndex:0] stringValue];
    if(!s || [s isEqualToString:@""])
	return nil;
    return s;
}
-(void)setIntToArticle:(Article*)a forKey:(NSString*)key inXMLElement:(NSXMLElement*)e
{
    NSString* s=[self valueForKey:key inXMLElement:e];
    if(s)
	[a setValue:[NSNumber numberWithInt:[s intValue]] forKey:key];
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
    NSXMLElement* element=[x objectAtIndex:0];
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

    o.spiresKey=[NSNumber numberWithInteger:[spiresKey integerValue]];
    o.eprint=eprint;
    o.title=title;
    
    NSError*error=nil;
    NSArray*a=[element nodesForXPath:@"authaffgrp/author" error:&error];
    NSMutableArray* array=[NSMutableArray array];

    for(NSXMLElement*e in a){
	[array addObject:[e stringValue]];
    }
    [o setAuthorNames:array];
/*    int u=[a count];
    if(u>30)u=30; // why on earth I put this line in the first place?? (March/4/2009)
    // now I understand... it just takes too much time to register many authors. (March6/2009)
    for(int i=0;i<u;i++){
	NSXMLElement* e=[a objectAtIndex:i];
	[array addObject:[e stringValue]];
    }
    [o setAuthorNames:a];*/
    
    
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
}

#pragma mark Main Logic
-(void)treatElements:(NSMutableArray*)a withXMLKey:(NSString*)xmlKey andKey:(NSString*)key
{
    if([a count]==0)
	return ;
    NSMutableDictionary*dict=[NSMutableDictionary dictionary];
    for(NSXMLElement*e in a){
	NSString*v=[self valueForKey:xmlKey inXMLElement:e];
	[dict setObject:e forKey:v];
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
    [req setSortDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:key
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
	    NSXMLElement*e=[dict objectForKey:v];
	    [self populatePropertiesOfArticle:data.article fromXML:e];
	    [generated addObject:data.article];
	    [a removeObject:e];
	    i++;
    	}
	NSEntityDescription*articleEntity=[NSEntityDescription entityForName:@"Article" inManagedObjectContext:[MOC moc]];
	for(NSXMLElement*e in a){
	    //	NSLog(@"%@=%@ not found, %@",key,[self valueForKey:xmlKey inXMLElement:e],e);
	    Article*article=[[NSManagedObject alloc] initWithEntity:articleEntity insertIntoManagedObjectContext:[MOC moc]];
	    [self populatePropertiesOfArticle:article fromXML:e];
	    [generated addObject:article];
	    j++;
	}
	[[MOC moc] enableUndo];
	NSLog(@"%d new, %d updated, based on %@",j,i,key);
    });
}
-(void)batchAddEntriesOfSPIRES:(NSArray*)a
{
    NSMutableArray*lookForEprint=[NSMutableArray array];
    NSMutableArray*lookForSpiresKey=[NSMutableArray array];
    NSMutableArray*lookForTitle=[NSMutableArray array];
    for(NSXMLElement*element in a){
	NSString*eprint=[self valueForKey:@"eprint" inXMLElement:element];
	NSString*spiresKey=[self valueForKey:@"spires_key" inXMLElement:element];
	NSString*title=[self valueForKey:@"title" inXMLElement:element];
	if(eprint){
	    [lookForEprint addObject:element];
	}else if(spiresKey){
	    [lookForSpiresKey addObject:element];
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
	NSLog(@"total: %d",(int)[generated count]);

	AllArticleList*allArticleList=[AllArticleList allArticleList];
	[allArticleList addArticles:generated];
	
	if(citedByTarget){
	    [citedByTarget addCitedBy:generated];
	}
	if(refersToTarget){
	    [refersToTarget addRefersTo:generated];
	}
	//    NSLog(@"add entry:%@",o);
	if(list){
	    [list addArticles:generated];
	}
	if([generated count]==1){
	    Article*article=[generated anyObject];
	    NSOperation*op=[[BatchBibQueryOperation alloc] initWithArray:[NSArray arrayWithObject:article]];
	    if(parent){
		[parent addDependency:op];
	    }
	    [[OperationQueues spiresQueue] addOperation:op];
	}
    });
}

#pragma mark entry point
-(void)main
{
    dispatch_async(dispatch_get_main_queue(),^{
	[[ProgressIndicatorController sharedController] startAnimation:self];	
	[(id<AppDelegate>)[NSApp delegate] postMessage:@"Registering entries..."];
    });
    NSLog(@"registers %d entries",(int)[elements count]);
    [self batchAddEntriesOfSPIRES:elements];
    dispatch_async(dispatch_get_main_queue(),^{
	[(id<AppDelegate>)[NSApp delegate] postMessage:nil];
	[(id<AppDelegate>)[NSApp delegate] clearingUpAfterRegistration:nil];	
	NSError*error=nil;
	BOOL success=[[MOC moc] save:&error];
	if(!success){
	    [[MOC sharedMOCManager] presentMOCSaveError:error];
	}
	[[ProgressIndicatorController sharedController] stopAnimation:self];	
    });
}

@end
