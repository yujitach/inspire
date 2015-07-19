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
#import "MOC.h"

@implementation InspireCitationNumberRefreshOperation
{
    NSSet*articles;
    NSMutableDictionary*recidToArticle;
    NSManagedObjectContext*moc;
    int tot;
    int sofar;
    NSString*description_;
}

-(InspireCitationNumberRefreshOperation*)initWithArticles:(NSSet*)aa;
{
    self=[super init];
    articles=aa;
    Article*a=[articles anyObject];
    moc=a.managedObjectContext;
    [moc performBlockAndWait:^{
        description_=[NSString stringWithFormat:@"citation number query for %@ etc.",a.title];
    }];
    return self;
}
-(NSString*)description
{
    if([articles count]==0){
	return @"invalid query operation";
    }else{
	return description_;
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
        NSString*recid=[chunk stringByMatching:@"<abbr.+?title=\"(.+?)\"" capture:1];
        if(recid && ![recid isEqualToString:@""]){
            NSString*cited=[chunk stringByMatching:@"Cited +by +(\\d+) +rec" capture:1];
            if(cited)
                recidToCites[recid] = cited;
        }
    }
    for(NSString*rec in [recidToCites allKeys]){
        NSString*cited=recidToCites[rec];
        Article*article=recidToArticle[rec];
        if(cited && article){
            article.citecount=@([cited intValue]);
        }
    }
}
-(void)main
{
    [moc performBlockAndWait:^{
        recidToArticle=[NSMutableDictionary dictionary];
        for(Article*a in articles){
            recidToArticle[[a.inspireKey stringValue]] = a;
            tot++;
        }
        NSMutableArray*a=[NSMutableArray array];
        for(NSString*recid in [recidToArticle allKeys]){
            [a addObject:recid];
            if([a count]>16){
                [self dealWith:a];
                a=[NSMutableArray array];
                [moc save:NULL];
            }
        }
        if([a count]>0){
            [self dealWith:a];
            [moc save:NULL];
        }
    }];
    NSManagedObjectContext*mainMOC=[MOC moc];
    [mainMOC performBlockAndWait:^{
        [mainMOC save:NULL];
    }];
}
@end
