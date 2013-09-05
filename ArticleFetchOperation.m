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
    ArticleList*articleList;
    NSUInteger offset;
}
-(ArticleFetchOperation*)initWithQuery:(NSString*)search_ forArticleList:(ArticleList*)al
{
    if(self=[super init]){
        search=search_;
        articleList=al;
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
    [req setResultType:NSManagedObjectIDResultType];
    [req setIncludesPropertyValues:YES];
    [req setRelationshipKeyPathsForPrefetching:@[@"inLists"]];
    NSMutableArray*total=[NSMutableArray array];
    while(1){
        if([self isCancelled]){
            return;
        }
        if(offset>LOADED_ENTRIES_MAX){
            return;
        }
        NSError*error=nil;
        [req setFetchOffset:offset];
        NSArray*a=[moc executeFetchRequest:req error:&error];
        if(!a || a.count==0){
            return;
        }
        offset+=a.count;
        [total addObjectsFromArray:a];
        dispatch_async(dispatch_get_main_queue(),^{
            NSMutableSet*tempSet=[NSMutableSet set];
            for(NSManagedObjectID*moid in a){
                if([self isCancelled])
                    return;
                Article*article=(Article*)[[MOC moc] objectWithID:moid];
                [tempSet addObject:article];
            }
            [[MOC moc] disableUndo];
            [articleList addArticles:tempSet];
            [[MOC moc] enableUndo];
        });
    }
    dispatch_async(dispatch_get_main_queue(),^{
        NSMutableSet*tempSet=[NSMutableSet set];
        for(NSManagedObjectID*moid in total){
            Article*article=(Article*)[[MOC moc] objectWithID:moid];
            [tempSet addObject:article];
        }
        [[MOC moc] disableUndo];
        [articleList setArticles:tempSet];
        [[MOC moc] enableUndo];
    });
    

}
-(NSString*)description
{
    return [NSString stringWithFormat:@"internal query with offset:%d",(int)offset];
}
@end
