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
    self=[super init];
    articles=[a copy];
    targets=[NSMutableArray array];
    for(Article* article in articles){
	NSString* target=[article uniqueInspireQueryString];
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
	Article* a=articles[0];
	return [NSString stringWithFormat:@"bib query for %@ etc.",a.title];
    }
}

-(void)main
{
    if(articles.count ==0)return;
    dispatch_async(dispatch_get_main_queue(),^{
        [[NSApp appDelegate] startProgressIndicator];
    });
    Article*a=articles[0];
    NSManagedObjectContext*moc=a.managedObjectContext;
    [moc performBlockAndWait:^{
        for(NSUInteger i=0;i<[articles count];i++){
            Article* article=articles[i];
            NSString*target=targets[i];
            NSLog(@"looking up %@",target);
            if([self isCancelled])break;
            if(!target) continue;
            NSString* bib=[[SpiresHelper sharedHelper] bibtexEntriesForQuery:target][0];
            if(!bib)break;
            if([self isCancelled])break;
            NSInteger r=[bib rangeOfString:@"{"].location;
            NSInteger t=[bib rangeOfString:@","].location;
            NSString* key=[bib substringWithRange:NSMakeRange(r+1, t-r-1)];
            NSString* latex=[[SpiresHelper sharedHelper] latexEUEntriesForQuery:target][0];
            if([self isCancelled])break;
            NSString* harvmac=[[SpiresHelper sharedHelper] harvmacEntriesForQuery:target][0];
            if([self isCancelled])break;
            NSInteger q=[harvmac rangeOfString:@"\n"].location;
            NSString* harvmacKey=[harvmac substringWithRange:NSMakeRange(1,q-1)];
            [article setExtra:bib forKey:@"bibtex"];
            [article setExtra:latex forKey:@"latex"];
            [article setExtra:harvmac forKey:@"harvmac"];
            [article setExtra:harvmacKey forKey:@"harvmacKey"];
            article.texKey=key;
        }
        [moc save:NULL];
        dispatch_async(dispatch_get_main_queue(),^{
            [[NSApp appDelegate] stopProgressIndicator];
        });
    }];
}
@end
