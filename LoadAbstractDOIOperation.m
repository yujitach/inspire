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
#import "NSManagedObjectContext+TrivialAddition.h"

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
    if(![obj isKindOfClass:[DumbOperation class]]){
	return NO;
    }
    return [[self description] isEqualToString:[obj description]];
}
-(NSString*)description
{
    return [NSString stringWithFormat:@"load abstract for %@",article.title];
}
-(BOOL)wantToRunOnMainThread
{
    return NO;
}

-(void)main
{
    if(!article || !article.title || [article.title isEqualToString:@""]){
	[self finish];
	return;
    }
    NSURL*url=[NSURL URLWithString:[@"http://dx.doi.org/" stringByAppendingString:article.doi]];
    NSError*error=nil;
    NSString*s=[NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:&error];
    if(error){
	NSLog(@"error while loading %@: %@",url, error);
    }
    [self performSelectorOnMainThread:@selector(loadAbstractUsingDOIRealWork:) withObject:s waitUntilDone:NO];
}
-(void)loadAbstractUsingDOIRealWork:(NSString*)content
{
    NSString*journalName=article.journal.name;
    NSString*abstract=nil;
    if(/*[journalName isEqualToString:@"Phys.Lett."]
     ||[journalName isEqualToString:@"Nucl.Phys."]
     ||[journalName isEqualToString:@"Annals Phys."]
     ||[journalName isEqualToString:@"Phys.Rept."]*/
       [[[NSUserDefaults standardUserDefaults] arrayForKey:@"ElsevierJournals"] containsObject:journalName]
       ){
	NSArray*a=[content componentsSeparatedByString:@"Abstract</h3><p>"];
	if([a count]<2)
	    goto BAIL;
	a=[[a objectAtIndex:1] componentsSeparatedByString:@" </div><!-- articleText -->"];
	if([a count]<1)
	    goto BAIL;
	abstract=[a objectAtIndex:0];
    }else if(/*[journalName isEqualToString:@"Phys.Rev."]
     ||[journalName isEqualToString:@"Phys.Rev.Lett."]
     ||[journalName isEqualToString:@"Rev.Mod.Phys."]*/
	     [[[NSUserDefaults standardUserDefaults] arrayForKey:@"APSJournals"] containsObject:journalName]
	     ){
	NSArray*a=[content componentsSeparatedByString:@"aps-abstractbox aps-mediumtext\">"];
	if([a count]<2)
	    goto BAIL;
	a=[[a objectAtIndex:1] componentsSeparatedByString:@"</div>"];
	if([a count]<1)
	    goto BAIL;
	abstract=[a objectAtIndex:0];
    }else if(
	     [[[NSUserDefaults standardUserDefaults] arrayForKey:@"SpringerJournals"] containsObject:journalName]
	     ){
	NSArray*a=[content componentsSeparatedByString:@"Abstract&nbsp;&nbsp;</span>"];
	if([a count]<2)
	    goto BAIL;
	a=[[a objectAtIndex:1] componentsSeparatedByString:@"</div>"];
	if([a count]<1)
	    goto BAIL;
	abstract=[a objectAtIndex:0];
    }else if(
	     [[[NSUserDefaults standardUserDefaults] arrayForKey:@"AIPJournals"] containsObject:journalName]
	){
	NSArray*a=[content componentsSeparatedByString:@"<div id=\"abstract\">"];
	if([a count]<2)
	    goto BAIL;
	a=[[a objectAtIndex:1] componentsSeparatedByString:@"</div>"];
	if([a count]<1)
	    goto BAIL;
	abstract=[a objectAtIndex:0];	
    }else if([journalName isEqualToString:@"Prog.Theor.Phys."]){
	NSArray*a=[content componentsSeparatedByString:@"<p class=\"abstract\">"];
	if([a count]<2)
	    goto BAIL;
	a=[[a objectAtIndex:1] componentsSeparatedByString:@"</p><!-- end abstract -->"];
	if([a count]<1)
	    goto BAIL;
	abstract=[a objectAtIndex:0];	
    }
    if(abstract){
	abstract=[abstract stringByReplacingOccurrencesOfString:@"<p>" withString:@""];
	abstract=[abstract stringByReplacingOccurrencesOfString:@"</p>" withString:@""];
	[[article managedObjectContext] disableUndo];
	article.abstract=abstract;
	[[article managedObjectContext] enableUndo];
    }
BAIL:
    [self finish];
}

@end
