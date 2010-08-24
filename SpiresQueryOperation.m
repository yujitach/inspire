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
#import "WaitOperation.h"
#import "AppDelegate.h"
#import "SpiresHelper.h"
#import "SpiresQueryDownloader.h"
#import "BatchBibQueryOperation.h"
@interface SpiresQueryOperation ()
-(void)spiresQueryDidEnd:(NSXMLDocument*)doc;
@end
@implementation SpiresQueryOperation
@synthesize importer;
-(SpiresQueryOperation*)initWithQuery:(NSString*)q andMOC:(NSManagedObjectContext*)m;
{
    [super init];
    search=q;
    moc=m;
    return self;
}
-(void)run
{
    
    if([search hasPrefix:@"c "]){
	NSString*ccc=[[search componentsSeparatedByString:@"and"] objectAtIndex:0];
	NSArray*a=[ccc componentsSeparatedByString:@" "];
	if([a count]!=2) return;
	NSString*s=[a objectAtIndex:1];
	if([s isEqualToString:@""])return;
	citedByTarget=[Article intelligentlyFindArticleWithId:s inMOC:moc];
	if(!citedByTarget){
	    NSLog(@"citedByTarget couldn't be obtained for %@",search);
	}	
    }else{
	citedByTarget=nil;
    }
    if([search hasPrefix:@"r"]){
	NSString*ccc=[[search componentsSeparatedByString:@"and"] objectAtIndex:0];
	NSArray*a=[ccc componentsSeparatedByString:@" "];
	if([a count]==2){
	    NSString*s=[a objectAtIndex:1];
	    if([s isEqualToString:@""])return;
	    refersToTarget=[Article intelligentlyFindArticleWithId:s inMOC:moc];
	}else if([a count]==3){
	    // r key nnnnnnn
	    NSString*s=[a objectAtIndex:2];
	    refersToTarget=[Article intelligentlyFindArticleWithId:s inMOC:moc];
	}else{
	    refersToTarget=nil;
	}
	if(!refersToTarget){
	    NSLog(@"refersToTarget couldn't be obtained for %@",search);
	}
    }else{
	refersToTarget=nil;
    }
    [[NSApp appDelegate] startProgressIndicator];
    [[NSApp appDelegate] postMessage:@"Waiting reply from spires..."];
    self.isExecuting=YES;
    downloader=[[SpiresQueryDownloader alloc] initWithQuery:search delegate:self didEndSelector:@selector(spiresQueryDidEnd:)];
    if(!downloader){
	[[NSApp appDelegate] postMessage:nil];
	[[NSApp appDelegate] stopProgressIndicator];
	[self finish];
    }
}
-(void)spiresQueryDidEnd:(NSXMLDocument*)doc
{
    [[NSApp appDelegate] postMessage:nil];
    [[NSApp appDelegate] stopProgressIndicator];
    if(!doc){
	[self finish];
	return;
    }
    NSXMLElement* root=[doc rootElement];
    NSArray*elements=[root elementsForName:@"document"];
    NSLog(@"spires returned %d entries",(int)[elements count]);
    if([self isCancelled]){
	[self finish];
	return;
    }
    importer=[[BatchImportOperation alloc] initWithElements:elements
							  citedBy:citedByTarget
							 refersTo:refersToTarget
					    registerToArticleList:nil];
    [self finish];
    [[OperationQueues sharedQueue] addOperation:importer];    
}
-(NSString*)description
{
    return [NSString stringWithFormat:@"spires query:%@",search];
}
-(void)cleanupToCancel
{
    [[NSApp appDelegate] postMessage:nil];
    [[NSApp appDelegate] stopProgressIndicator];
}
@end
