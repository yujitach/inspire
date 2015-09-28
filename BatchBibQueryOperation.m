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
#import "MOC.h"

@implementation BatchBibQueryOperation
{
    NSMutableArray*articleIDs;
}
-(BatchBibQueryOperation*)initWithArray:(NSArray*)a;
{
    self=[super init];
    articleIDs=[NSMutableArray array];
    for(Article*article in a){
        [articleIDs addObject:article.objectID];
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
    if([articleIDs count]==0){
	return @"invalid query operation";
    }else{
//	Article* a=articles[0];
//	return [NSString stringWithFormat:@"bib query for %@ etc.",a.title];
        return @"a bib query.";
    }
}

-(void)main
{
    if(articleIDs.count ==0)return;
    dispatch_async(dispatch_get_main_queue(),^{
        [[NSApp appDelegate] startProgressIndicator];
    });
    NSManagedObjectContext*moc=[[MOC sharedMOCManager] createSecondaryMOC];
    [moc performBlockAndWait:^{
        for(NSManagedObjectID*objectID in articleIDs){
            Article* article=[moc objectWithID:objectID];
            
            NSString* target=[article uniqueInspireQueryString];
            if(!target)
                continue;

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
