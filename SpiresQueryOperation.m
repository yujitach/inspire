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
#import "SpiresHelper.h"
#import "SpiresQueryDownloader.h"
#import "BatchBibQueryOperation.h"
@implementation SpiresQueryOperation
@synthesize importer;
-(SpiresQueryOperation*)initWithQuery:(NSString*)q andMOC:(NSManagedObjectContext*)m;
{
    self=[super init];
    search=q;
    moc=m;
    return self;
}
-(void)run
{
    
    if([search hasPrefix:@"c "]){
	NSString*ccc=[[search componentsSeparatedByString:@"and"] objectAtIndex:0];
	NSArray*a=[ccc componentsSeparatedByString:@" "];
	if([a count]==2){
	    NSString*s=[a objectAtIndex:1];
	    if([s isEqualToString:@""])return;
	    citedByTarget=[Article intelligentlyFindArticleWithId:s inMOC:moc];
	}else if([a count]==3){
	    // c key nnnnnnn
	    NSString*s=[a objectAtIndex:2];
	    citedByTarget=[Article intelligentlyFindArticleWithId:s inMOC:moc];
	}else{
	    citedByTarget=nil;
	}
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
    self.isExecuting=YES;
    [self startAt:0];
}
-(void)startAt:(NSUInteger)start
{
    Article*a=nil;
    if(refersToTarget){
	a=refersToTarget;
    }else if(citedByTarget){
	a=citedByTarget;
    }
    downloader=[[SpiresQueryDownloader alloc] initWithQuery:search startAt:start forArticle:a whenDone:^(NSXMLDocument*doc,NSUInteger total){
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
        [[OperationQueues sharedQueue] addOperation:importer];
        if(start+[elements count]<total){
            [self startAt:start+[elements count]];
        }else{
            [self finish];
        }
    }];
    if(!downloader){
	[self finish];
    }
}
-(NSString*)description
{
    return [NSString stringWithFormat:@"spires query:%@",search];
}
@end
