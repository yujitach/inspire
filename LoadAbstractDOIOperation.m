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

@interface LoadAbstractDOIOperation ()
-(void)loadAbstractUsingDOIRealWork:(NSString*)content;
@end
@implementation LoadAbstractDOIOperation
-(LoadAbstractDOIOperation*)initWithArticle:(Article*)a;
{
    self=[super init];
    article=a;
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
    return [NSString stringWithFormat:@"load abstract for %@",article.title];
}

-(void)main
{
    if(!article || !article.title || [article.title isEqualToString:@""]){
//	[self finish];
	return;
    }
    NSURL*url=[NSURL URLWithString:[@"http://dx.doi.org/" stringByAppendingString:article.doi]];
    NSError*error=nil;
    NSString*s=[NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:&error];
    if(!s){
	NSLog(@"error while loading %@: %@",url, error);
	return;
    }
    if([s rangeOfString:@"Get the article at ScienceDirect"].location!=NSNotFound){
	NSLog(@"stupid Elsevier locator found");
	s=[s stringByMatching:@"value=\"(http://.+?)\"" capture:1];
	NSURL*newURL=[NSURL URLWithString:s];
	s=[NSString stringWithContentsOfURL:newURL encoding:NSUTF8StringEncoding error:&error];
	if(!s){
	    NSLog(@"error while loading %@: %@",url, error);
	    return;
	}
    }
    [self performSelectorOnMainThread:@selector(loadAbstractUsingDOIRealWork:) withObject:s waitUntilDone:YES];
}
-(void)loadAbstractUsingDOIRealWork:(NSString*)content
{
    NSString*journalName=article.journal.name;
    NSString*abstract=nil;
    if(
       [[[NSUserDefaults standardUserDefaults] arrayForKey:@"ElsevierJournals"] containsObject:journalName]
       ){
	NSArray*a=[content componentsSeparatedByString:@"Abstract</h3><p>"];
	if([a count]<2)
	    goto BAIL;
	a=[a[1] componentsSeparatedByString:@"</div><!-- articleText -->"];
	if([a count]<1)
	    goto BAIL;
	abstract=a[0];
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
	NSArray*a=[content componentsSeparatedByString:@"Abstract&nbsp;&nbsp;</span>"];
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
	[[article managedObjectContext] disableUndo];
	article.abstract=abstract;
	[[article managedObjectContext] enableUndo];
    }
BAIL:
    ;
//    [self finish];
}

@end
