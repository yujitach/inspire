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
#import "spires_AppDelegate.h"
#import "MOC.h"
#import "ProgressIndicatorController.h"
#import "NSString+magic.h"

@interface BatchImportOperation (internal)
-(void)batchAddEntriesOfSPIRES:(NSArray*)a;
@end
/*@interface ImportPair:NSObject
{
    Article*a;
    NSXMLElement*e;
}
@property(retain) Article*a;
@property(retain) NSXMLElement*e;
-(ImportPair*)initWithArticle:(Article*)o andXML:(NSXMLElement*)x;
@end
@implementation ImportPair
@synthesize a,e;
-(ImportPair*)initWithArticle:(Article *)o andXML:(NSXMLElement *)x
{
    self=[super init];
    a=o;e=x;
    return self;
}
@end*/


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
    moc=[MOC createSecondaryMOC];
    citedByTarget=c;
    refersToTarget=r;
    list=l;
/*    if(citedByTarget||refersToTarget||list){
	NSError*error=nil;
	BOOL success=[[MOC moc] save:&error];
	if(!success){
	    [[MOC sharedMOCManager] presentMOCSaveError:error];
	}
    }*/
    delegate=[NSApp delegate];
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

-(void)main
{
    [[ProgressIndicatorController sharedController] performSelectorOnMainThread:@selector(startAnimation:)
								     withObject:self 
								  waitUntilDone:NO];
    [self batchAddEntriesOfSPIRES:elements];
	
    [delegate performSelectorOnMainThread:@selector(clearingUp:) withObject:nil waitUntilDone:NO];
    [[ProgressIndicatorController sharedController] performSelectorOnMainThread:@selector(stopAnimation:)
								     withObject:self 
								  waitUntilDone:NO];
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
//-(Article*)addOneEntryOfSPIRES:(NSXMLElement*)element
-(Article*)preExistingArticleForXML:(NSXMLElement*)element
{
    Article* o=nil;
    NSString*eprint=[self valueForKey:@"eprint" inXMLElement:element];
    NSString*spiresKey=[self valueForKey:@"spires_key" inXMLElement:element];
    NSString*title=[self valueForKey:@"title" inXMLElement:element];
    if(eprint){
	o=[Article articleWithEprint:eprint inMOC:moc];
    }else if(spiresKey){
	o=[Article articleWith:spiresKey inDataForKey:@"spiresKey" inMOC:moc];
    }else if(title){
	o=[Article articleWith:title inDataForKey:@"title" inMOC:moc];	
    }else{
	NSLog(@"entry %@ with neither eprint id nor spiresKey nor title",element);
	return nil;
    }
    return o;
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
    int u=[a count];
    if(u>10)u=10; // why on earth I put this line in the first place?? (March/4/2009)
// now I understand... it just takes too much time to register many authors. (March6/2009)
    for(int i=0;i<u;i++){
	NSXMLElement* e=[a objectAtIndex:i];
	[array addObject:[e stringValue]];
    }
//    NSLog(@"%@",o.title);
    [o setAuthorNames:array];
    
    //  date not dealt with yet. but who cares? -- well it's done
    
    //    [self setStringToArticle:o forKey:@"title" inXMLElement:element];
    [self setStringToArticle:o forKey:@"doi" inXMLElement:element];
    [self setStringToArticle:o forKey:@"abstract" inXMLElement:element];
    [self setStringToArticle:o forKey:@"comments" inXMLElement:element];
    [self setStringToArticle:o forKey:@"memo" inXMLElement:element];
    [self setStringToArticle:o forKey:@"spicite" inXMLElement:element ofKey:@"spicite"];
    [self setIntToArticle:o forKey:@"citecount" inXMLElement:element];
    [self setIntToArticle:o forKey:@"version" inXMLElement:element];
    [self setIntToArticle:o forKey:@"pages" inXMLElement:element];
    [self setJournalToArticle:o inXMLElement:element];
    [self setDateToArticle:o inXMLElement:element];
}

-(void)setAndRefreshArticles:(NSArray*)x
{
    NSError*error=nil;
    BOOL success=[moc save:&error];
    if(!success){
	[[MOC sharedMOCManager] presentMOCSaveError:error];
    }

    NSMutableArray*objectIDsToBeRefreshed=[NSMutableArray array];
    for(Article*z in x){
	[objectIDsToBeRefreshed addObject:[z objectID]];
    }

    [self performSelectorOnMainThread:@selector(refreshManagedObjectsOnMainMocMainWork:) withObject:objectIDsToBeRefreshed waitUntilDone:YES];    
}
-(void)batchLoadArticlesFromArticleDatas:(NSArray*)datas
{
    NSMutableArray*a=[NSMutableArray array];
    for(ArticleData*d in datas){
	[a addObject:d.article];
    }
    NSEntityDescription*entity=[NSEntityDescription entityForName:@"Article" inManagedObjectContext:moc];
    NSFetchRequest*req=[[NSFetchRequest alloc]init];
    [req setEntity:entity];
    NSPredicate*pred=[NSPredicate predicateWithFormat:@"self IN %@",a];
    [req setPredicate:pred];
    [req setIncludesPropertyValues:YES];
    [req setReturnsObjectsAsFaults:NO];
    NSError*error=nil;
    [moc executeFetchRequest:req error:&error];    
}
-(NSArray*)articlesFromElements:(NSMutableArray*)a withXMLKey:(NSString*)xmlKey andKey:(NSString*)key
{
    if([a count]==0)
	return nil;
    NSMutableDictionary*dict=[NSMutableDictionary dictionary];
    for(NSXMLElement*e in a){
	NSString*v=[self valueForKey:xmlKey inXMLElement:e];
	[dict setObject:e forKey:v];
    }
    NSArray*values=[dict allKeys];
    values=[values sortedArrayUsingSelector:@selector(compare:)];
    NSEntityDescription*entity=[NSEntityDescription entityForName:@"ArticleData" inManagedObjectContext:moc];
    NSFetchRequest*req=[[NSFetchRequest alloc]init];
    [req setEntity:entity];
    NSPredicate*pred=[NSPredicate predicateWithFormat:@"%K IN %@",key,values];
    [req setPredicate:pred];
    [req setIncludesPropertyValues:YES];
    [req setRelationshipKeyPathsForPrefetching:[NSArray arrayWithObject:@"article"]];
    [req setReturnsObjectsAsFaults:NO];
    [req setSortDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:key
										   ascending:YES]]];
	    NSError*error=nil;
    NSArray*datas=[moc executeFetchRequest:req error:&error];
    [self batchLoadArticlesFromArticleDatas:datas];
    NSMutableArray*results=[NSMutableArray array];
    for(ArticleData*d in datas){
	Article*article=d.article;
	id obj=[d valueForKey:key];
	NSString*v=obj;
	if([obj isKindOfClass:[NSNumber class]]){
	    v=[(NSNumber*)obj stringValue];
	}
	NSXMLElement*e=[dict objectForKey:v];
//	NSLog(@"%@=%@ found, %@",key,v,e);
	[self populatePropertiesOfArticle:article fromXML:e];
	[results addObject:article];
	[a removeObject:e];
    }
    NSEntityDescription*articleEntity=[NSEntityDescription entityForName:@"Article" inManagedObjectContext:moc];
    for(NSXMLElement*e in a){
//	NSLog(@"%@=%@ not found, %@",key,[self valueForKey:xmlKey inXMLElement:e],e);
	Article*article=[[NSManagedObject alloc] initWithEntity:articleEntity insertIntoManagedObjectContext:moc];
	[self populatePropertiesOfArticle:article fromXML:e];
	[results addObject:article];
    }
    return results;
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
    
    NSMutableArray*articles=[NSMutableArray array];
    [articles addObjectsFromArray:[self articlesFromElements:lookForEprint withXMLKey:@"eprint" andKey:@"eprint"]];
    [articles addObjectsFromArray:[self articlesFromElements:lookForSpiresKey withXMLKey:@"spires_key" andKey:@"spiresKey"]];
    [articles addObjectsFromArray:[self articlesFromElements:lookForTitle withXMLKey:@"title" andKey:@"title"]];
    [self setAndRefreshArticles:articles];


    if([articles count]==1){
	Article*article=[articles objectAtIndex:0];
	NSOperation*op=[[BatchBibQueryOperation alloc] initWithArray:[NSArray arrayWithObject:article]];
	if(parent){
	    [parent addDependency:op];
	}
	[[OperationQueues spiresQueue] addOperation:op];
    }
}

-(void)refreshManagedObjectsOnMainMocMainWork:(NSArray*)y
{
    NSMutableSet*x=[NSMutableSet set];
    for(NSManagedObjectID* objectID in y){
	Article*mo=(Article*)[[MOC moc] objectWithID:objectID];
	[[MOC moc] refreshObject:mo.data mergeChanges:YES];
	[[MOC moc] refreshObject:mo mergeChanges:YES];
	[x addObject:mo];
    }
//    [(spires_AppDelegate*)[NSApp delegate] stopUpdatingMainView:self];
    AllArticleList*allArticleList=[AllArticleList allArticleListInMOC:[MOC moc]];
    [allArticleList addArticles:x];
    
    if(citedByTarget){
	[citedByTarget addCitedBy:x];
    }
    if(refersToTarget){
	[refersToTarget addRefersTo:x];
    }
    //    NSLog(@"add entry:%@",o);
    if(list){
	[list addArticles:x];
    }
    NSError*error=nil;
    BOOL success=[[MOC moc] save:&error];
    if(!success){
	[[MOC sharedMOCManager] presentMOCSaveError:error];
    }
//    [(spires_AppDelegate*)[NSApp delegate] startUpdatingMainView:self];
    
}


@end
