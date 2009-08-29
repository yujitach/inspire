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
#import "SpiresQueryDownloader.h"
#import "BatchBibQueryOperation.h"
@implementation SpiresQueryOperation
-(SpiresQueryOperation*)initWithQuery:(NSString*)q andMOC:(NSManagedObjectContext*)m;
{
    [super init];
    search=q;
    moc=m;
    return self;
}
-(void)setParent:(NSOperation*)p
{
    parent=p;
    if(parent){
	[parent addDependency:self];
    }    
}
-(void)run
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
    self.isExecuting=YES;
    downloader=[[SpiresQueryDownloader alloc] initWithQuery:search delegate:self didEndSelector:@selector(spiresQueryDidEnd:userInfo:) userInfo:nil];
    if(!downloader){
	[self finish];
    }
}
-(void)spiresQueryDidEnd:(NSXMLDocument*)doc userInfo:(id)ignore
{
    if(!doc){
	[self finish];
	return;
    }
    NSXMLElement* root=[doc rootElement];
    NSArray*elements=[root elementsForName:@"document"];
    NSLog(@"spires returned %d entries",[elements count]);
    if([self isCancelled]){
	[self finish];
	return;
    }
    BatchImportOperation*op=[[BatchImportOperation alloc] initWithElements:elements
							  citedBy:citedByTarget
							 refersTo:refersToTarget
					    registerToArticleList:nil];
    if(parent){
	[op setParent:parent];
    }
    [[OperationQueues sharedQueue] addOperation:op];
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
-(void)cleanupToCancel
{
    [ProgressIndicatorController stopAnimation:self];
}
@end
