//
//  InspireCitationNumberRefreshOperation.m
//  spires
//
//  Created by Yuji on 3/26/11.
//  Copyright 2011 Y. Tachikawa. All rights reserved.
//

#import "InspireCitationNumberRefreshOperation.h"
#import "Article.h"
#import "NSString+magic.h"
#import "SpiresHelper.h"

@implementation InspireCitationNumberRefreshOperation
-(InspireCitationNumberRefreshOperation*)initWithArticles:(NSSet*)aa;
{
    self=[super init];
    articles=aa;
    recidToArticle=[NSMutableDictionary dictionary];
    for(Article*a in articles){
	[recidToArticle setObject:a forKey:[a.inspireKey stringValue]];
	tot++;
    }
    return self;
}
-(NSString*)description
{
    if([articles count]==0){
	return @"invalid query operation";
    }else{
	Article* a=[articles anyObject];
	return [NSString stringWithFormat:@"bib query for %@ etc.",a.title];
    }
}
-(void)dealWith:(NSArray*)x
{
    sofar+=(int)[x count];

    NSString*query=[NSString stringWithFormat: @"recid:%@&of=hb",[x componentsJoinedByString:@" or recid:"]];
    NSURL*url=[[SpiresHelper sharedHelper] inspireURLForQuery:query];
    NSString*result=[NSString stringWithContentsOfURL:url
					     encoding:NSUTF8StringEncoding
						error:NULL];
    NSArray*chunks=[result componentsSeparatedByString:@"<tr"];
    NSMutableDictionary*recidToCites=[NSMutableDictionary dictionary];
    for(NSString*chunk in chunks){
	if([chunk rangeOfString:@"unapi-id"].location==NSNotFound)
	    continue;
//	NSLog(@"chunk:%@",chunk);
	NSString*recid=[chunk stringByMatching:@"<abbr.+?title=\"(.+?)\"" capture:1];
//	NSLog(@"recid:%@",recid);
	if(recid && ![recid isEqualToString:@""]){
	    NSString*cited=[chunk stringByMatching:@"Cited +by +(\\d+) +rec" capture:1];
//	    NSLog(@"cited:%@",cited);
	    if(cited)
		[recidToCites setObject:cited forKey:recid];
	}
    }
    dispatch_async(dispatch_get_main_queue(),^{
//	[[NSApp appDelegate] postMessage:[NSString stringWithFormat:@"Refreshing citations %d/%d",sofar,tot]];
	for(NSString*rec in [recidToCites allKeys]){
	    NSString*cited=[recidToCites objectForKey:rec];
	    Article*article=[recidToArticle objectForKey:rec];
	    if(cited && article){
		article.citecount=[NSNumber numberWithInt:[cited intValue]];
	    }
	}
    });
}
-(void)main
{
/*    dispatch_async(dispatch_get_main_queue(),^{
	[[NSApp appDelegate] startProgressIndicator];
    });    */
    NSMutableArray*a=[NSMutableArray array];
    for(NSString*recid in [recidToArticle allKeys]){
	[a addObject:recid];
	if([a count]>16){
	    [self dealWith:a];
	    a=[NSMutableArray array];
	}
    }
    if([a count]>0){
	[self dealWith:a];
    }
/*    dispatch_async(dispatch_get_main_queue(),^{
	[[NSApp appDelegate] postMessage:nil];
	[[NSApp appDelegate] stopProgressIndicator];
    });        */
}
@end
