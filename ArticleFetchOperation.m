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
        offset=0;
    }
    return self;
}
#define BATCHSIZE 30
-(void)main
{
    NSManagedObjectContext*moc=[MOC moc];
    SpiresHelper*helper=[SpiresHelper helperWithMOC:moc];
    NSEntityDescription*entity=[NSEntityDescription entityForName:@"Article" inManagedObjectContext:moc];
    NSPredicate*predicate=[helper predicateFromSPIRESsearchString:search];
    ArticleList*articleList=(ArticleList*)[moc objectWithID:articleListID];
    while(1){
        if([self isCancelled]){
            return;
        }
        if(offset>LOADED_ENTRIES_MAX){
            return;
        }
        __block NSArray*a=nil;
        
        [moc performBlockAndWait:^{
            // apparently the fetch offset is not respected unless the moc is saved!
            NSFetchRequest*req=[[NSFetchRequest alloc] init];
            [req setPredicate:predicate];
            [req setEntity:entity];
            [req setFetchLimit:BATCHSIZE];
            [req setIncludesPropertyValues:YES];
            [req setRelationshipKeyPathsForPrefetching:@[@"inLists"]];
            [req setFetchOffset:offset];
            NSError*error=nil;
            a=[moc executeFetchRequest:req error:&error];
            NSSet*set=[NSSet setWithArray:a];
            [articleList addArticles:set];
            [moc save:NULL];
        }];
        if(!a || a.count<BATCHSIZE){
            return;
        }
        offset+=a.count;
    }
}
-(NSString*)description
{
    return [NSString stringWithFormat:@"internal query with offset:%d",(int)offset];
}
@end
