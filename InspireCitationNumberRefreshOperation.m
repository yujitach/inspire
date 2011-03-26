//
//  InspireCitationNumberRefreshOperation.m
//  spires
//
//  Created by Yuji on 3/26/11.
//  Copyright 2011 Y. Tachikawa. All rights reserved.
//

#import "InspireCitationNumberRefreshOperation.h"
#import "Article.h"
#import "RegexKitLite.h"

@implementation InspireCitationNumberRefreshOperation
-(InspireCitationNumberRefreshOperation*)initWithArticles:(NSSet*)aa;
{
    self=[super init];
    articles=aa;
    recidToArticle=[NSMutableDictionary dictionary];
    for(Article*a in articles){
	[recidToArticle setObject:a forKey:[a.inspireKey stringValue]];
    }
    return self;
}
-(void)dealWith:(NSArray*)x
{
    NSString*urlString=[NSString stringWithFormat:@"http://inspirebeta.net/search?p=recid:%@&of=hb",
			[x componentsJoinedByString:@"+or+recid:"]];
    urlString=[urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSURL*url=[NSURL URLWithString:urlString];
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
}
@end
