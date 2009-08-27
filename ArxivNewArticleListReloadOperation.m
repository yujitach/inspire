//
//  ArxivNewArticleListReloadOperation.m
//  spires
//
//  Created by Yuji on 8/26/09.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import "ArxivNewArticleListReloadOperation.h"
#import "ArxivNewArticleList.h"
#import "MOC.h"
#import "ArxivHelper.h"
#import "ProgressIndicatorController.h"
#import "Article.h"
#import "AllArticleList.h"
#import "spires_AppDelegate.h"
#import "RegexKitLite.h"
#import "NSString+XMLEntityDecoding.h"
#import "NSManagedObjectContext+TrivialAddition.h"


@implementation ArxivNewArticleListReloadOperation
-(NSOperation*)initWithArxivNewArticleList:(ArxivNewArticleList*)a;
{
    self=[super init];
    al=a;
    listName=al.name;
    moc=[MOC createSecondaryMOC];
    return self;
}
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
}

-(Article*)dealWith:(NSString*)s
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
    
    Article*ar=[Article articleWith:eprint forKey:@"eprint" inMOC:moc];
    if(!ar){
	NSEntityDescription*articleEntity=[NSEntityDescription entityForName:@"Article" inManagedObjectContext:moc];
	ar=[[NSManagedObject alloc] initWithEntity:articleEntity insertIntoManagedObjectContext:moc];
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
    return ar;
}
-(void)registerArticles:(NSArray*)y
{
    NSMutableSet*x=[NSMutableSet set];
    [[MOC moc] disableUndo];
    for(NSManagedObjectID* objectID in y){
	Article*mo=(Article*)[[MOC moc] objectWithID:objectID];
	[[MOC moc] refreshObject:mo mergeChanges:YES];
	[x addObject:mo];
    }
    
    [(spires_AppDelegate*)[NSApp delegate] stopUpdatingMainView:self];
    AllArticleList*allArticleList=[AllArticleList allArticleListInMOC:[MOC moc]];
    [allArticleList addArticles:x];
    
    al.articles=nil;
    [al addArticles:x];
    NSError*error=nil;
    [[MOC moc] save:&error];
    if(error){
	[[MOC sharedMOCManager] presentMOCSaveError:error];
    }
    [[MOC moc] enableUndo];
    [(spires_AppDelegate*)[NSApp delegate] startUpdatingMainView:self]; 
    [(spires_AppDelegate*)[NSApp delegate] clearingUp:self];        
}
-(void)main
{
    [[ProgressIndicatorController sharedController] performSelectorOnMainThread:@selector(startAnimation:)
								     withObject:self
								  waitUntilDone:NO];
    NSString*s=[[ArxivHelper sharedHelper] list:listName];
    
    NSMutableArray*articles=[NSMutableArray array];
    NSArray*a=[s componentsSeparatedByString:@"<dt>"];
    for(int i=1;i<[a count];i++){
	//	NSLog(@"%d",i);
	Article*ar=[self dealWith:[a objectAtIndex:i]];
	[articles addObject:ar];
    }

    NSError*error=nil;
    [moc save:&error];
    if(error){
	NSLog(@"secondary moc error");
	[[MOC sharedMOCManager] presentMOCSaveError:error];
    }
        
    NSMutableArray*articleIDs=[NSMutableArray array];
    for(Article*ar in articles){
	[articleIDs addObject:[ar objectID]];
    }
    [self performSelectorOnMainThread:@selector(registerArticles:)
			   withObject:articleIDs
			waitUntilDone:YES];

    [[ProgressIndicatorController sharedController] performSelectorOnMainThread:@selector(stopAnimation:)
								     withObject:self
								  waitUntilDone:NO];
}
@end
