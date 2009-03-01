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
#import "JournalEntry.h"
#import "Author.h"
#import "AllArticleList.h"
#import "NSManagedObjectContext+TrivialAddition.h"
#import "spires_AppDelegate.h"
#import "MOC.h"

@interface BatchImportOperation (internal)
-(void)batchAddEntriesOfSPIRES:(NSArray*)a;
@end
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
    moc=[MOC secondaryManagedObjectContext];
    citedByTarget=c;
    refersToTarget=r;
    list=l;
    if(citedByTarget||refersToTarget||list){
	[[MOC moc] save:nil];
    }
    if(citedByTarget){
	citedByTarget=(Article*)[moc objectWithID:[citedByTarget objectID]];
    }
    if(refersToTarget){
	refersToTarget=(Article*)[moc objectWithID:[refersToTarget objectID]];
    }
    if(list){
	list=(ArticleList*)[moc objectWithID:[list objectID]];
    }
    delegate=[NSApp delegate];
    return self;
}
-(NSString*)description
{
    return [NSString stringWithFormat:@"registering to database %d elements",[elements count]];
}
-(BOOL)wantToRunOnMainThread
{
    return NO;
}
-(void)main
{
//	NSMutableArray*a=[NSMutableArray array];
    [delegate performSelectorOnMainThread:@selector(stopUpdatingMainView:) withObject:nil waitUntilDone:YES];
/*	for(NSXMLElement* element in elements){
	    [a addObject:element];
	    if([a count]>10){
		[self performSelectorOnMainThread:@selector(batchAddEntriesOfSPIRES:) withObject:a waitUntilDone:YES];
		[a removeAllObjects];
		usleep(50*1000); // sleep .05sec to improve responsiveness while adding...
	    }
	}
	if([a count]>0)
	    [self performSelectorOnMainThread:@selector(batchAddEntriesOfSPIRES:) withObject:a waitUntilDone:YES];*/
    [self batchAddEntriesOfSPIRES:elements];
    [delegate performSelectorOnMainThread:@selector(startUpdatingMainView:) withObject:nil waitUntilDone:YES];
	
    [delegate performSelectorOnMainThread:@selector(clearingUp:) withObject:nil waitUntilDone:NO];
    [self finish];
}

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
						inMOC:moc];
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
-(Article*)addOneEntryOfSPIRES:(NSXMLElement*)element
{
    Article* o=nil;
    NSString*eprint=[self valueForKey:@"eprint" inXMLElement:element];
    NSString*spicite=[self valueForKey:@"spicite" inXMLElement:element];
    NSString*title=[self valueForKey:@"title" inXMLElement:element];
    if(eprint){
	o=[Article articleWith:eprint forKey:@"eprint" inMOC:moc];
    }else if(spicite){
	o=[Article articleWith:spicite forKey:@"spicite" inMOC:moc];
    }else if(title){
	o=[Article articleWith:title forKey:@"title" inMOC:moc];	
    }else{
	NSLog(@"entry %@ with neither eprint id nor spicite nor title",element);
	return nil;
    }
    if(!o){
	//	o=[Article newArticleInMOC:[self managedObjectContext]];
	NSEntityDescription*articleEntity=[NSEntityDescription entityForName:@"Article" inManagedObjectContext:moc];
	o=[[NSManagedObject alloc] initWithEntity:articleEntity insertIntoManagedObjectContext:moc];
    }
    o.spicite=spicite;
    o.eprint=eprint;
    o.title=title;
    
    NSError*error;
    NSArray*a=[element nodesForXPath:@"authaffgrp/author" error:&error];
    [o setAuthors:nil];
    NSMutableSet* set=[NSMutableSet set];
    int u=[a count];
    if(u>10)u=10;
    for(int i=0;i<u;i++){
	NSXMLElement* e=[a objectAtIndex:i];
	[set addObject:[Author authorWithName:[e stringValue] inMOC:moc]];
    }
    [o addAuthors:set];
    
    //  date not dealt with yet. but who cares? -- well it's done
    
    //    [self setStringToArticle:o forKey:@"title" inXMLElement:element];
    [self setStringToArticle:o forKey:@"doi" inXMLElement:element];
    [self setStringToArticle:o forKey:@"abstract" inXMLElement:element];
    [self setStringToArticle:o forKey:@"comments" inXMLElement:element];
    [self setStringToArticle:o forKey:@"memo" inXMLElement:element];
    [self setStringToArticle:o forKey:@"spiresKey" inXMLElement:element ofKey:@"spires_key"];
    [self setIntToArticle:o forKey:@"citecount" inXMLElement:element];
    [self setIntToArticle:o forKey:@"version" inXMLElement:element];
    [self setIntToArticle:o forKey:@"pages" inXMLElement:element];
    [self setJournalToArticle:o inXMLElement:element];
    [self setDateToArticle:o inXMLElement:element];
    return o;
}
-(void)batchAddEntriesOfSPIRES:(NSArray*)a
{
 //   [moc disableUndo];
    NSMutableSet*x=[NSMutableSet set];
    for(NSXMLElement*element in a){
	Article*c=[self addOneEntryOfSPIRES:element];
	if(c){
	    [x addObject:c];
	}
    }
    
    AllArticleList*allArticleList=[AllArticleList allArticleListInMOC:moc];
    [allArticleList addArticles:x];
    
    if(citedByTarget){
	[citedByTarget addCitedBy:x];
	//	NSLog(@"%@ cited by %@",citedByTarget.eprint,o.eprint);	
    }
    if(refersToTarget){
	[refersToTarget addRefersTo:x];
    }
    //    NSLog(@"add entry:%@",o);
    if(list){
	[list addArticles:x];
    }
    
    [moc save:nil];
    NSMutableArray*objectIDsToBeRefreshed=[NSMutableArray array];
    [objectIDsToBeRefreshed addObject:[allArticleList objectID]];
    for(Article* z in x){
	[objectIDsToBeRefreshed addObject:[z objectID]];
    }
    if(citedByTarget){
	[objectIDsToBeRefreshed addObject:[citedByTarget objectID]];	
    }
    if(refersToTarget){
	[objectIDsToBeRefreshed addObject:[refersToTarget objectID]];
    }
    if(list){
	[objectIDsToBeRefreshed addObject:[list objectID]];
    }
    [self performSelectorOnMainThread:@selector(refreshManagedObjectsOnMainMoc:) withObject:objectIDsToBeRefreshed waitUntilDone:YES];
    if([x count]==1){
	Article*a=[x anyObject];
	a=(Article*)[[MOC moc] objectWithID:[a objectID]];
	[[DumbOperationQueue spiresQueue] addOperation:[[BatchBibQueryOperation alloc] initWithArray:[NSArray arrayWithObject:a]]];
    }
//    [moc enableUndo];
}

-(void)refreshManagedObjectsOnMainMoc:(NSArray*)y
{
    for(NSManagedObjectID* objectID in y){
	[[MOC moc] refreshObject:[[MOC moc] objectWithID:objectID] mergeChanges:YES];
    }
}


@end
