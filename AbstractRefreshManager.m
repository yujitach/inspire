//
//  AbstractRefreshManager.m
//  inspire
//
//  Created by Yuji on 2015/08/31.
//
//

#import "AbstractRefreshManager.h"
#import "Article.h"
#import "JournalEntry.h"
#import "DumbOperation.h"
#import "ArxivMetadataFetchOperation.h"
#import "LoadAbstractDOIOperation.h"

@implementation AbstractRefreshManager
{
    NSMutableArray*articlesRecentlyRefreshed;
}
+(AbstractRefreshManager*)sharedAbstractRefreshManager
{
    static AbstractRefreshManager*x=nil;
    if(!x){
        x=[[AbstractRefreshManager alloc]init];
    }
    return x;
}
-(void)refreshAbstractOfArticle:(Article*)a whenRefreshed:(void(^)(Article*refreshedArticle))whenDoneBlock
{
    if(![[OperationQueues arxivQueue] isOnline]){
        return;
    }
    if(a.abstract && ![a.abstract isEqualToString:@""]){
        return;
    }
    
    // prevent lots of access to the same article when the abstract loading fails
    {
        if(!articlesRecentlyRefreshed){
            articlesRecentlyRefreshed=[NSMutableArray array];
        }
        if([articlesRecentlyRefreshed count]>1000){
            articlesRecentlyRefreshed=[NSMutableArray array];
        }
        if([articlesRecentlyRefreshed containsObject:a]){
            return;
        }
        [articlesRecentlyRefreshed addObject:a];
    }
    
    
    if(a.eprint && ![a.eprint isEqualToString:@""]){
        NSOperation*op=[[ArxivMetadataFetchOperation alloc] initWithArticle:a];
        if(whenDoneBlock) {
            [op setCompletionBlock:^{
                dispatch_async(dispatch_get_main_queue(), ^{
                    whenDoneBlock(a);
                });
            }];
        }
        NSLog(@"actually prefetching abstract of: %@",a.eprint);
        [[OperationQueues arxivQueue] addOperation:op];
    }else if(a.doi && ![a.doi isEqualToString:@""]){
        if(!a.doi || [a.doi isEqualToString:@""]) return;
        NSArray* knownJournals=[[NSUserDefaults standardUserDefaults] arrayForKey:@"KnownJournals"];
        if(![knownJournals containsObject:a.journal.name]){
            return;
        }
        NSOperation*op=[[LoadAbstractDOIOperation alloc] initWithArticle:a];
        if(whenDoneBlock) {
            [op setCompletionBlock:^{
                dispatch_async(dispatch_get_main_queue(), ^{
                    whenDoneBlock(a);
                });
            }];
        }
        [[OperationQueues spiresQueue] addOperation:op];
    }
    
    if(!a.texKey || [a.texKey isEqualToString:@""]){
        //	[[DumbOperationQueue spiresQueue] addOperation:[[BatchBibQueryOperation alloc]initWithArray:[NSArray arrayWithObject:a]]];
        //	[self getBibEntriesWithoutDisplay:self];
    }

}
@end
