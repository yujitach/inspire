//
//  BatchBibQueryOperation.m
//  spires
//
//  Created by Yuji on 09/02/07.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import "BatchBibQueryOperation.h"
#import "Article.h"
#import "AppDelegate.h"
#import "SpiresHelper.h"

@implementation BatchBibQueryOperation
-(BatchBibQueryOperation*)initWithArray:(NSArray*)a;
{
    [super init];
    articles=[a copy];
    targets=[NSMutableArray array];
    for(Article* article in articles){
	NSString* target=nil;
	if(article.articleType==ATEprint){
	    target=[@"eprint " stringByAppendingString:article.eprint];
	}else if(article.articleType==ATSpires){
	    target=[@"spicite " stringByAppendingString:article.spicite];	
	}else if(article.articleType==ATSpiresWithOnlyKey){
	    target=[@"key " stringByAppendingString:[article.spiresKey stringValue]];	
	}
	if(!target)
	    target=(NSString*)[NSNull null];
	[targets addObject:target];
    }
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
    if([articles count]==0){
	return @"invalid query operation";
    }else{
	Article* a=[articles objectAtIndex:0];
	return [NSString stringWithFormat:@"bib query for %@ etc.",a.title];
    }
}

-(void)main
{
    dispatch_async(dispatch_get_main_queue(),^{
	[[NSApp appDelegate] startProgressIndicator];
    });
    for(NSUInteger i=0;i<[articles count];i++){
	Article* article=[articles objectAtIndex:i];
	NSString*target=[targets objectAtIndex:i];	
	if([self isCancelled])break;
	if(!target) continue;
	NSString* bib=[[[SpiresHelper sharedHelper] bibtexEntriesForQuery:target] objectAtIndex:0];
	if([self isCancelled])break;
	NSInteger r=[bib rangeOfString:@"{"].location;
	NSInteger t=[bib rangeOfString:@","].location;
	NSString* key=[bib substringWithRange:NSMakeRange(r+1, t-r-1)];
	NSString* latex=[[[SpiresHelper sharedHelper] latexEUEntriesForQuery:target] objectAtIndex:0];
	if([self isCancelled])break;
	NSString* harvmac=[[[SpiresHelper sharedHelper] harvmacEntriesForQuery:target] objectAtIndex:0];
	if([self isCancelled])break;
	NSInteger q=[harvmac rangeOfString:@"\n"].location;
	NSString* harvmacKey=[harvmac substringWithRange:NSMakeRange(1,q-1)];
	dispatch_async(dispatch_get_main_queue(),^{
	    [article setExtra:bib forKey:@"bibtex"];
	    [article setExtra:latex forKey:@"latex"];
	    [article setExtra:harvmac forKey:@"harvmac"];
	    [article setExtra:harvmacKey forKey:@"harvmacKey"];
	    article.texKey=key;
	});
    }
    dispatch_async(dispatch_get_main_queue(),^{
	[[NSApp appDelegate] stopProgressIndicator];
    });
//    [self finish];
}
@end
