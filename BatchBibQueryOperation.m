//
//  BatchBibQueryOperation.m
//  spires
//
//  Created by Yuji on 09/02/07.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import "BatchBibQueryOperation.h"
#import "Article.h"
#import "ProgressIndicatorController.h"
#import "SpiresHelper.h"
@implementation BatchBibQueryOperation
-(BatchBibQueryOperation*)initWithArray:(NSArray*)a;
{
    [super init];
    articles=[a copy];
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
-(void)getBibEntriesInternal:(NSArray*)a
{
    Article*article=[a objectAtIndex:0];
    [article setExtra:[a objectAtIndex:2] forKey:@"bibtex"];
    [article setExtra:[a objectAtIndex:3] forKey:@"latex"];
    [article setExtra:[a objectAtIndex:4] forKey:@"harvmac"];
    [article setExtra:[a objectAtIndex:5] forKey:@"harvmacKey"];
    article.texKey=[a objectAtIndex:1];
    
}
-(void)main
{
    [ProgressIndicatorController performSelectorOnMainThread:@selector(startAnimation:) withObject:self waitUntilDone:NO];
    for(Article* article in articles){
	if([self isCancelled])break;
/*	if(article.texKey && ![article.texKey isEqualToString:@""]){
	    continue;
	}*/
	NSString* target=nil;
	if(article.articleType==ATEprint){
	    target=[@"eprint " stringByAppendingString:article.eprint];
	}else if(article.articleType==ATSpires){
	    target=[@"spicite " stringByAppendingString:article.spicite];	
	}else if(article.articleType==ATSpiresWithOnlyKey){
	    target=[@"key " stringByAppendingString:[article.spiresKey stringValue]];	
	}
	NSString* bib=[[[SpiresHelper sharedHelper] bibtexEntriesForQuery:target] objectAtIndex:0];
	if([self isCancelled])break;
	int r=[bib rangeOfString:@"{"].location;
	int t=[bib rangeOfString:@","].location;
	NSString* key=[bib substringWithRange:NSMakeRange(r+1, t-r-1)];
	NSString* latex=[[[SpiresHelper sharedHelper] latexEUEntriesForQuery:target] objectAtIndex:0];
	if([self isCancelled])break;
	NSString* harvmac=[[[SpiresHelper sharedHelper] harvmacEntriesForQuery:target] objectAtIndex:0];
	if([self isCancelled])break;
	int q=[harvmac rangeOfString:@"\n"].location;
	NSString* harvmacKey=[harvmac substringWithRange:NSMakeRange(1,q-1)];
	NSArray* arr=[NSArray arrayWithObjects:article,key,bib,latex,harvmac,harvmacKey,nil];
	[self performSelectorOnMainThread:@selector(getBibEntriesInternal:) withObject:arr waitUntilDone:YES];
    }
    [ProgressIndicatorController performSelectorOnMainThread:@selector(stopAnimation:) withObject:self waitUntilDone:NO];
//    [self finish];
}
@end
