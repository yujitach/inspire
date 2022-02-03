//
//  LoadAbstractDOIOperation.m
//  spires
//
//  Created by Yuji on 09/02/08.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import "LoadAbstractDOIOperation.h"
#import "Article.h"
#import "JournalEntry.h"
#import "NSString+magic.h"
#import "MOC.h"

@implementation LoadAbstractDOIOperation
{
    NSManagedObjectID*objID;
}
-(LoadAbstractDOIOperation*)initWithArticle:(Article*)a;
{
    self=[super init];
    objID=a.objectID;
//    NSLog(@"%@",article.title);
    return self;
}

-(BOOL)isEqual:(id)obj
{
    if(![obj isKindOfClass:[NSOperation class]]){
	return NO;
    }
    return [[self description] isEqualToString:[obj description]];
}
-(NSString*)description
{
//    return [NSString stringWithFormat:@"load abstract for %@",article.title];
    return @"load abstract via DOI";
}

-(void)main
{
    NSManagedObjectContext*secondMOC=[[MOC sharedMOCManager] createSecondaryMOC];
    [secondMOC performBlock:^{
        Article*article=[secondMOC objectWithID:objID];
        if(!article || !article.title || [article.title isEqualToString:@""]){
            return;
        }
        
        NSURL*url=[NSURL URLWithString:[@"https://dx.doi.org/" stringByAppendingString:article.doi]];
        NSError*error=nil;
        NSString*s=[NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:&error];
        if(!s){
            NSLog(@"error while loading %@: %@",url, error);
            return;
        }
        if([s rangeOfString:@"sciencedirect"].location!=NSNotFound){
            NSString*sdID=[s stringByMatching:@"https://www.sciencedirect.com/science/article/pii/([01-9]+)" capture:1];
            NSURL*newURL=[NSURL URLWithString:[NSString stringWithFormat:@"https://www.sciencedirect.com/science/article/pii/%@?np=y",sdID]];
            s=[NSString stringWithContentsOfURL:newURL encoding:NSUTF8StringEncoding error:&error];
            if(!s){
                NSLog(@"error while loading %@: %@",url, error);
                return;
            }
        }
        [self loadAbstractUsingDOIRealWork:s forArticle:article];
        [secondMOC save:NULL];
    }];
    
}
-(void)loadAbstractUsingDOIRealWork:(NSString*)content forArticle:(Article*)article
{
    NSString*journalName=article.journal.name;
    NSString*abstract=nil;
    if(
       [[[NSUserDefaults standardUserDefaults] arrayForKey:@"ElsevierJournals"] containsObject:journalName]
       ){
	NSArray*a=[content componentsSeparatedByString:@"Abstract</h2><p id=\"\">"];
	if([a count]<2)
	    goto BAIL;
	a=[a[1] componentsSeparatedByString:@"</p></div>"];
	if([a count]<1)
	    goto BAIL;
	abstract=a[0];
        abstract=[abstract stringByReplacingOccurrencesOfRegex:@"data-mathurl=\".+?\"" withString:@""];
        abstract=[abstract stringByReplacingOccurrencesOfRegex:@"data-mathURL=\".+?\"" withString:@""];
        abstract=[abstract stringByReplacingOccurrencesOfRegex:@"<img xmlns:xoe=\"http://www.elsevier.com/xml/xoe/dtd\".+?>" withString:@""];
        abstract=[abstract stringByReplacingOccurrencesOfRegex:@"<noscript.+?>" withString:@""];
        abstract=[abstract stringByReplacingOccurrencesOfRegex:@"</noscript>" withString:@""];
        abstract=[abstract stringByReplacingOccurrencesOfRegex:@"<!--ja:math-->" withString:@""];
    }else if(
	     [[[NSUserDefaults standardUserDefaults] arrayForKey:@"AnnualReviewJournals"] containsObject:journalName]
	     ){
	NSArray*a=[content componentsSeparatedByString:@"<p class=\"first last\">"];
	if([a count]<2)
	    goto BAIL;
	a=[a[1] componentsSeparatedByString:@"</p>"];
	if([a count]<1)
	    goto BAIL;
	abstract=a[0];
    }else if(
	     [[[NSUserDefaults standardUserDefaults] arrayForKey:@"APSJournals"] containsObject:journalName]
	     ){
	NSArray*a=[content componentsSeparatedByString:@"aps-abstractbox'>"];
	if([a count]<2)
	    goto BAIL;
	a=[a[1] componentsSeparatedByString:@"</div>"];
	if([a count]<1)
	    goto BAIL;
	abstract=a[0];
    }else if(
	     [[[NSUserDefaults standardUserDefaults] arrayForKey:@"IOPJournals"] containsObject:journalName]
	     ){
	NSArray*a=[content componentsSeparatedByString:@"Abstract.</strong>"];
	if([a count]<2)
	    goto BAIL;
	a=[a[1] componentsSeparatedByString:@"</p>"];
	if([a count]<1)
	    goto BAIL;
	abstract=a[0];
    }else if(
	     [[[NSUserDefaults standardUserDefaults] arrayForKey:@"SpringerJournals"] containsObject:journalName]
	     ){
	NSArray*a=[content componentsSeparatedByString:@"<div class=\"abstract-content formatted\" itemprop=\"description\">"];
	if([a count]<2)
	    goto BAIL;
	a=[a[1] componentsSeparatedByString:@"</div>"];
	if([a count]<1)
	    goto BAIL;
	abstract=a[0];
    }else if(
	     [[[NSUserDefaults standardUserDefaults] arrayForKey:@"AIPJournals"] containsObject:journalName]
	){
	NSArray*a=[content componentsSeparatedByString:@"<div id=\"abstract\">"];
	if([a count]<2)
	    goto BAIL;
	a=[a[1] componentsSeparatedByString:@"</div>"];
	if([a count]<1)
	    goto BAIL;
	abstract=a[0];	
    }else if(
	     [[[NSUserDefaults standardUserDefaults] arrayForKey:@"WSJournals"] containsObject:journalName]
	     ){
	NSArray*a=[content componentsSeparatedByString:@"Abstract:</b>"];
	if([a count]<2)
	    goto BAIL;
	NSString*s=[a[1] stringByMatching:@"<div class=\"text\">(.+)</div>"];
	if(s && ![s isEqualToString:@""]){
	    abstract=s;
	}
    }else if(
	     [[[NSUserDefaults standardUserDefaults] arrayForKey:@"PTPJournals"] containsObject:journalName]
	     ){
	NSArray*a=[content componentsSeparatedByString:@"<p class=\"abstract\">"];
	if([a count]<2)
	    goto BAIL;
	a=[a[1] componentsSeparatedByString:@"</p><!-- end abstract -->"];
	if([a count]<1)
	    goto BAIL;
	abstract=a[0];	
    }
    if(abstract){
	abstract=[abstract stringByReplacingOccurrencesOfString:@"<p>" withString:@""];
	abstract=[abstract stringByReplacingOccurrencesOfString:@"</p>" withString:@""];
	article.abstract=abstract;
    }
BAIL:
    ;
//    [self finish];
}

@end
