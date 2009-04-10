//
//  SpiresQueryOperation.m
//  spires
//
//  Created by Yuji on 09/02/07.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import "SpiresQueryOperation.h"
#import "Article.h"
#import "BatchImportOperation.h"
#import "ProgressIndicatorController.h"
#import "SpiresHelper.h"
#import "BatchBibQueryOperation.h"
@implementation SpiresQueryOperation
-(SpiresQueryOperation*)initWithQuery:(NSString*)q andMOC:(NSManagedObjectContext*)m;
{
    [super init];
    search=q;
    moc=m;
    return self;
}
-(void)main
{
    if([search hasPrefix:@"c"]){
	NSString*ccc=[[search componentsSeparatedByString:@"and"] objectAtIndex:0];
	NSArray*a=[ccc componentsSeparatedByString:@" "];
	if([a count]!=2) return;
	NSString*s=[a objectAtIndex:1];
	if([s isEqualToString:@""])return;
	if([s rangeOfString:@":"].location!=NSNotFound || [s rangeOfString:@"/"].location!=NSNotFound)
	    citedByTarget=[Article articleWith:s forKey:@"eprint" inMOC:moc];
	else
	    citedByTarget=[Article articleWith:s forKey:@"spicite" inMOC:moc];
    }else{
	citedByTarget=nil;
    }
    if([search hasPrefix:@"r"]){
	NSString*ccc=[[search componentsSeparatedByString:@"and"] objectAtIndex:0];
	NSArray*a=[ccc componentsSeparatedByString:@" "];
	if([a count]==2){
	    NSString*s=[a objectAtIndex:1];
	    if([s isEqualToString:@""])return;
	    if([s rangeOfString:@":"].location!=NSNotFound || [s rangeOfString:@"/"].location!=NSNotFound)
		refersToTarget=[Article articleWith:s forKey:@"eprint" inMOC:moc];
	    else
		refersToTarget=[Article articleWith:s forKey:@"spicite" inMOC:moc];
	}else if([a count]==3){
	    NSString*s=[a objectAtIndex:2];
	    refersToTarget=[Article articleWith:s forKey:@"spiresKey" inMOC:moc];
	}else{
	    refersToTarget=nil;
	}
    }else{
	refersToTarget=nil;
    }
    [ProgressIndicatorController startAnimation:self];
    [[SpiresHelper sharedHelper] querySPIRES:search delegate:self didEndSelector:@selector(spiresQueryDidEnd:userInfo:) userInfo:nil];
}
-(void)spiresQueryDidEnd:(NSXMLDocument*)doc userInfo:(id)ignore
{
    NSXMLElement* root=[doc rootElement];
    NSArray*elements=[root elementsForName:@"document"];
    NSLog(@"spires returned %d entries",[elements count]);
    if(self.canceled){
	[self finish];
	return;
    }
    [self.queue addOperation:[[BatchImportOperation alloc] initWithElements:elements
									//		   andMOC:moc
											  citedBy:citedByTarget
											 refersTo:refersToTarget
									    registerToArticleList:nil]];
    [ProgressIndicatorController stopAnimation:self];
//    if([search hasPrefix:@"tex"]){
	// this cheat guarantees that texKey is always generated for a lookup of a texKey.
//    }
    
    [self finish];
}
-(NSString*)description
{
    return [NSString stringWithFormat:@"spires query:%@",search];
}

@end
