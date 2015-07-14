//
//  ArticleFetchOperation.m
//  inspire
//
//  Created by Yuji on 2012/09/30.
//
//

#import "ArticleFetchOperation.h"
#import "ArticleList.h"
#import "AllArticleList.h"
#import "MOC.h"
#import "SpiresHelper.h"

@implementation ArticleFetchOperation
{
    NSString*search;
    NSManagedObjectID*articleListID;
    NSUInteger offset;
}
-(ArticleFetchOperation*)initWithQuery:(NSString*)search_ forArticleList:(ArticleList*)al
{
    if(self=[super init]){
        search=search_;
        articleListID=al.objectID;
    }
    return self;
}
#define BATCHSIZE 50
-(void)main
{
    NSFetchRequest*req=[[NSFetchRequest alloc] init];
    NSManagedObjectContext*moc=[[MOC sharedMOCManager] createSecondaryMOC];
    SpiresHelper*helper=[SpiresHelper helperWithMOC:moc];
    NSEntityDescription*entity=[NSEntityDescription entityForName:@"Article" inManagedObjectContext:moc];
    [req setEntity:entity];
    NSPredicate*predicate=[helper predicateFromSPIRESsearchString:search];
    [req setPredicate:predicate];
    [req setFetchLimit:BATCHSIZE];
    [req setIncludesPropertyValues:YES];
    [req setRelationshipKeyPathsForPrefetching:@[@"inLists"]];
    while(1){
        if([self isCancelled]){
            return;
        }
        if(offset>LOADED_ENTRIES_MAX){
            return;
        }
        __block BOOL shouldReturn=NO;
        [moc performBlockAndWait:^{
            NSError*error=nil;
            [req setFetchOffset:offset];
            NSArray*a=[moc executeFetchRequest:req error:&error];
            ArticleList*articleList=(ArticleList*)[moc objectWithID:articleListID];
            
            if(!a || a.count==0){
                shouldReturn=YES;
            }
            offset+=a.count;
            [articleList addArticles:[NSSet setWithArray:a]];
            [moc save:NULL];
        }];
        if(shouldReturn){
            return;
        }
    }
}
-(NSString*)description
{
    return [NSString stringWithFormat:@"internal query with offset:%d",(int)offset];
}
@end
