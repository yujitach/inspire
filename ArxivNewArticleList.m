// 
//  ArxivNewArticleList.m
//  spires
//
//  Created by Yuji on 08/10/15.
//  Copyright 2008 Y. Tachikawa. All rights reserved.
//

#import "ArxivNewArticleList.h"
#import "Article.h"
#import "DumbOperation.h"
#import "ArxivNewArticleListReloadOperation.h"

@implementation ArxivNewArticleList 
+(ArxivNewArticleList*)arXivNewArticleListWithName:(NSString*)s inMOC:(NSManagedObjectContext*)moc
{
    NSEntityDescription*authorEntity=[NSEntityDescription entityForName:@"ArxivNewArticleList" inManagedObjectContext:moc];
    NSFetchRequest*req=[[NSFetchRequest alloc]init];
    [req setEntity:authorEntity];
    NSPredicate*pred=[NSPredicate predicateWithFormat:@"name = %@",s];
    [req setPredicate:pred];
    NSError*error=nil;
    NSArray*a=[moc executeFetchRequest:req error:&error];
    if([a count]>0){
	return [a objectAtIndex:0];
    }else{
	ArxivNewArticleList* mo=[[NSManagedObject alloc] initWithEntity:authorEntity 
				    insertIntoManagedObjectContext:moc];
	[mo setValue:s forKey:@"name"];
	NSSortDescriptor *sd=[[NSSortDescriptor  alloc] initWithKey:@"eprint" ascending:YES];
	[mo setSortDescriptors:[NSArray arrayWithObjects:sd,nil]];	
	return mo;
    }
}
/*
-(void)registerAuthorsInString:(NSString*)tmp toArticle:(Article*)ar
{
    NSArray*authors=[tmp componentsSeparatedByString:@"\">"];
    NSMutableArray* array=[NSMutableArray array];
    if([authors count]>1){
	for(int i=1;i<[authors count];i++){
	    NSString*s=[authors objectAtIndex:i];
	    s=[[s componentsSeparatedByString:@"</a>"] objectAtIndex:0];
	    s=[s stringByReplacingOccurrencesOfString:@"." withString:@". "];
	    NSArray*x=[s componentsSeparatedByString:@" "];
	    NSString*lastName=[x lastObject];
	    NSMutableArray*b=[NSMutableArray array];
	    for(int j=0;j<[x count]-1;j++){
		NSString*t=[x objectAtIndex:j];
		if(![t isEqualToString:@""]){
		    [b addObject:t];
		}
	    }
	    s=[NSString stringWithFormat:@"%@, %@",lastName, [b componentsJoinedByString:@" "]];
	    [array addObject:s];
	}
	[ar setAuthorNames:array];
    }
}*/
/*-(void)addOneEntryOfArxiv:(NSXMLElement*)element 
{
    NSString*otitle=[[[element elementsForName:@"title"] objectAtIndex:0] stringValue];
    if([otitle rangeOfString:@"UPDATED"].location!=NSNotFound)
	return;
    if([otitle rangeOfString:@"LISTED"].location!=NSNotFound)
	return;

    int lastp=[otitle rangeOfString:@"(" options:NSBackwardsSearch].location;
    NSString*title=[otitle substringToIndex:lastp];
    NSArray*a=[[otitle substringFromIndex:lastp+1] componentsSeparatedByString:@"v"];
//    NSLog(@"bar:%@",a);

    NSString*eprint=[NSString stringWithFormat:@"arXiv%@",[a objectAtIndex:1]];
    NSNumber*version=[NSNumber numberWithInt:[[[a objectAtIndex:2] substringToIndex:1] intValue]];
    //    NSLog(@"%@,%@,%@",title,eprint,version);
    
    NSString*abstract=[[[element elementsForName:@"description"] objectAtIndex:0] stringValue];
    abstract=[abstract stringByReplacingOccurrencesOfString:@"</p>" withString:@""];
    abstract=[abstract stringByReplacingOccurrencesOfString:@"<p>" withString:@""];
    abstract=[abstract stringByExpandingAmpersandEscapes];
    
    Article*ar=[Article articleWith:eprint forKey:@"eprint" inMOC:[self managedObjectContext]];
    if(!ar){
	ar=[Article newArticleInMOC:[self managedObjectContext]];
	ar.eprint=eprint;
    }
    ar.abstract=abstract;
    ar.version=version;
    ar.title=title;
    
    NSString*tmp=[[[element elementsForName:@"dc:creator"] objectAtIndex:0] stringValue];
    [self registerAuthorsInString:tmp toArticle:ar];
    [self addArticlesObject:ar];
}

-(void)reloadX
{
    self.articles=nil;
    NSXMLDocument*doc=[[ArxivHelper sharedHelper] xmlForPath:self.name];
    if(![doc rootElement]){
	NSLog(@"rss not available");
	return;
    }
    NSArray*items=[[doc rootElement] elementsForName:@"item"];
    for(NSXMLElement* element in items){
	[self addOneEntryOfArxiv:element ];
    }
    
}*/
/*-(void)dealWith:(NSString*)s
{
//    NSLog(@"%@",s);
    int i=[s rangeOfString:@"arXiv:"].location;
    NSString*eprint=[s substringFromIndex:i];
    {
	NSArray*x=[eprint componentsSeparatedByString:@"</a>"];
	eprint=[x objectAtIndex:0];
	if([eprint rangeOfString:@"/"].location!=NSNotFound){
	    eprint=[eprint substringFromIndex:[(NSString*)@"arXiv:" length]];
	}
    }
    
    
    NSArray*a=[s componentsSeparatedByString:@"</span>"];
    NSString*title=[a objectAtIndex:2];
    i=[title rangeOfString:@"</div>"].location;
    title=[title substringToIndex:i];
    title=[title stringByExpandingAmpersandEscapes];
    title=[title stringByReplacingOccurrencesOfRegex:@"^ +" withString:@""];
//    NSLog(@"%@",title);
    NSString*authorsList=[a objectAtIndex:3];
    i=[authorsList rangeOfString:@"</div>"].location;
    authorsList=[authorsList substringToIndex:i];
    authorsList=[authorsList stringByExpandingAmpersandEscapes];

    NSString*comments=nil;
    if([[a objectAtIndex:3] rangeOfString:@"omments"].location!=NSNotFound){
	comments=[a objectAtIndex:4];
	i=[comments rangeOfString:@"</div>"].location;
	comments=[comments substringToIndex:i];
	comments=[comments stringByExpandingAmpersandEscapes];
    }
//    NSLog(@"%@",authorsList);
    NSString*abstract=[a lastObject];
    if([abstract rangeOfString:@"<p>"].location!=NSNotFound){
	abstract=[[abstract componentsSeparatedByString:@"<p>"]objectAtIndex:1];
	abstract=[[abstract componentsSeparatedByString:@"</p>"]objectAtIndex:0];
//	abstract=[abstract stringByExpandingAmpersandEscapes];
// abstract is fed to the html view anyway, so there's no need to expand &...; escapes here.
    }else{
	abstract=nil;
    }
 
    Article*ar=[Article articleWith:eprint forKey:@"eprint" inMOC:[self managedObjectContext]];
    if(!ar){
	ar=[Article newArticleInMOC:[self managedObjectContext]];
	ar.eprint=eprint;
    }
    ar.abstract=abstract;
    ar.version=[NSNumber numberWithInt:1];
    ar.title=title;
    ar.comments=comments;
    ArticleFlag af=ar.flag;
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"shouldPutUnreadMarksForArxivNew"]){
	af|=AFIsUnread;
    }
    [ar setFlag:af];
    [self registerAuthorsInString:authorsList toArticle:ar];
    [self addArticlesObject:ar];
    
}*/
-(void)reload
{
    [[OperationQueues arxivQueue] addOperation:[[ArxivNewArticleListReloadOperation alloc] initWithArxivNewArticleList:self]];
/*    [ProgressIndicatorController startAnimation:self];
    [(spires_AppDelegate*)[NSApp delegate] stopUpdatingMainView:self];
    [[self managedObjectContext] disableUndo];
    NSString*s=[[ArxivHelper sharedHelper] list:self.name];
    if(!s){
	[ProgressIndicatorController stopAnimation:self];
	return;
    }
    self.articles=nil;
    

    NSArray*a=[s componentsSeparatedByString:@"<dt>"];
    for(int i=1;i<[a count];i++){
//	NSLog(@"%d",i);
	[self dealWith:[a objectAtIndex:i]];
    }
    NSError*error=nil;
    [[self managedObjectContext] save:&error];
    if(error){
	[[MOC sharedMOCManager] presentMOCSaveError:error];
    }
    [[self managedObjectContext] enableUndo];
    [(spires_AppDelegate*)[NSApp delegate] startUpdatingMainView:self];
    [ProgressIndicatorController stopAnimation:self];
    [(spires_AppDelegate*)[NSApp delegate] clearingUp:self];    
*/
}
-(NSImage*)icon
{
    return [NSImage imageNamed:@"arxiv.ico"];
}
-(BOOL)searchStringEnabled
{
    return NO;
}

@end
