//
//  ArticleListDictionaryRepresentation.m
//  inspire
//
//  Created by Yuji on 2015/08/11.
//
//

#import "ArticleListArchiveAdditions.h"
#import "Article.h"
#import "LightweightArticle.h"
#import "ArticleFolder.h"
#import "AllArticleList.h"
#import "CannedSearch.h"
#import "SimpleArticleList.h"
#import "BatchImportOperation.h"
#import "MOC.h"
@interface ArticleList(ArticleListDictionaryRepresentation)
-(NSDictionary*)dictionaryRepresentation;
-(NSArray*)arraysOfDictionaryRepresentationOfArticles;
@end

@implementation ArticleList (ArticleListDictionaryRepresentation)
-(NSArray*)arraysOfDictionaryRepresentationOfArticles
{
    NSMutableArray*ar=[NSMutableArray array];
    for(Article*a in self.articles){
        LightweightArticle*b=[[LightweightArticle alloc]initWithArticle:a];
        [ar addObject:b];
    }
    [ar sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"sortKey" ascending:YES ]]];
    NSMutableArray*as=[NSMutableArray array];
    for(LightweightArticle*a in ar){
        [as addObject:a.dic];
    }
    return as;
}
-(NSDictionary*)dictionaryRepresentation
{
    return @{@"type":[self className],@"name":self.name,@"positionInView":self.positionInView,@"articles":[self arraysOfDictionaryRepresentationOfArticles]};
}
@end

@implementation CannedSearch (ArticleListDictionaryRepresentation)
-(NSDictionary*)dictionaryRepresentation
{
    return @{@"type":[self className],@"name":self.name,@"positionInView":self.positionInView};
}
@end


@implementation AllArticleList (ArticleListDictionaryRepresentation)
-(NSDictionary*)dictionaryRepresentation
{
    return nil;
}
@end

@implementation ArticleFolder (ArticleListDictionaryRepresentation)
-(NSDictionary*)dictionaryRepresentation
{
    NSMutableDictionary*dic=[[super dictionaryRepresentation] mutableCopy];
    NSMutableArray*ar=[NSMutableArray array];
    
    for(ArticleList*al in self.children){
        [ar addObject:[al dictionaryRepresentation]];
    }
    [ar sortUsingDescriptors:@[[[NSSortDescriptor alloc] initWithKey:@"positionInView" ascending:YES ]]];

    [dic setObject:ar forKey:@"children"];
    return dic;
}
@end
@implementation ArticleList (ArticleListArchiveAdditions)
+(NSArray*)topLevelArticleListsFromMOC:(NSManagedObjectContext*)secondMOC
{
    NSEntityDescription*entity=[NSEntityDescription entityForName:@"ArticleList" inManagedObjectContext:secondMOC];
    NSPredicate*predicate=[NSPredicate predicateWithFormat:@"parent == nil"];
    NSFetchRequest*req=[[NSFetchRequest alloc] init];
    [req setPredicate:predicate];
    [req setEntity:entity];
    [req setIncludesPropertyValues:YES];
    NSError*error=nil;
    return [secondMOC executeFetchRequest:req error:&error];
}
+(void)prepareSnapShotAndPerform:(SnapShotBlock)block
{
    NSManagedObjectContext*secondMOC=[[MOC sharedMOCManager] createSecondaryMOC];
    [secondMOC performBlock:^{
        NSMutableArray*ar=[NSMutableArray array];
        NSArray*topLevelALs=[self topLevelArticleListsFromMOC:secondMOC];
        for(ArticleList*al in topLevelALs){
            NSDictionary*dic=[al dictionaryRepresentation];
            if(dic){
                [ar addObject:dic];
            }
        }
        [ar sortUsingDescriptors:@[[[NSSortDescriptor alloc] initWithKey:@"positionInView" ascending:YES ]]];
        dispatch_async(dispatch_get_main_queue(),^{
            block(@{@"children":ar});
        });
    }];
}
+(NSDictionary*)articleListForName:(NSString*)name andType:(NSString*)type inArray:(NSArray*)a
{
    for(NSDictionary*dic in a){
        if(![dic[@"name"] isEqualToString:name])break;
        if(![dic[@"type"] isEqualToString:type])break;
        return dic;
    }
    return nil;
}
+(NSArray*)dealWithSyncedAL:(NSDictionary*)dic withAL:(ArticleList*)al atFolder:(ArticleFolder*)af usingMOC:(NSManagedObjectContext*)secondMOC
{
    ArticleList*articleList=al;
    NSArray*notFoundArray=nil;
    if(!articleList){
        NSEntityDescription*entity=[NSEntityDescription entityForName:dic[@"type"] inManagedObjectContext:secondMOC];
        articleList=[[ArticleList alloc] initWithEntity:entity insertIntoManagedObjectContext:secondMOC];
        articleList.name=dic[@"name"];
        if(af){
            articleList.parent=af;
        }
    }
    articleList.positionInView=dic[@"positionInView"];
    if([articleList isKindOfClass:[CannedSearch class]]){
        CannedSearch*can=(CannedSearch*)articleList;
        [can reloadLocal];
    }else if([articleList isKindOfClass:[ArticleFolder class]]){
        notFoundArray=[self notFoundArticleListsAfterMergingChildren:dic[@"children"] toArticleFolder:(ArticleFolder*)articleList usingMOC:secondMOC];
    }else if([articleList isKindOfClass:[SimpleArticleList class]]){
        BatchImportOperation*op=[[BatchImportOperation alloc] initWithProtoArticles:dic[@"articles"] originalQuery:nil];
        __weak BatchImportOperation*weakOp=op;
        op.completionBlock=^{
            [articleList setArticles:weakOp.generated];
        };
        [[OperationQueues sharedQueue] addOperation:op];
    }
    return notFoundArray;
}
+(NSArray*)notFoundArticleListsAfterMergingChildren:(NSArray*)children toArticleFolder:(ArticleFolder*)af usingMOC:(NSManagedObjectContext*)secondMOC
{
    NSArray*articleLists=[af.children allObjects];
    NSMutableArray*mutableChildren=[children mutableCopy];
    if(!articleLists){
        articleLists=[self topLevelArticleListsFromMOC:secondMOC];
    }
    NSMutableArray*notFound=[NSMutableArray array];
    for(ArticleList*al in articleLists){
        if([al isKindOfClass:[AllArticleList class]])break;
        NSDictionary*newDic=[self articleListForName:al.name andType:al.className inArray:mutableChildren];
        if(!newDic){
            NSArray*notFoundArray=[self dealWithSyncedAL:newDic withAL:al atFolder:af usingMOC:secondMOC];
            if(notFoundArray){
                [notFound addObjectsFromArray:notFoundArray];
            }
            [mutableChildren removeObject:newDic];
        }else{
            [notFound addObject:al];
        }
    }
    for(NSDictionary*dic in mutableChildren){
        [self dealWithSyncedAL:dic withAL:nil atFolder:af usingMOC:secondMOC];
    }
    return notFound;
}
+(void)mergeSnapShot:(NSDictionary *)snapShot andDealWithArticleListsToBeRemoved:(ToBeRemovedBlock)block
{
    NSManagedObjectContext*secondMOC=[[MOC sharedMOCManager]createSecondaryMOC];
    [secondMOC performBlock:^{
        NSArray*notFound=[self notFoundArticleListsAfterMergingChildren:snapShot[@"children"] toArticleFolder:nil usingMOC:secondMOC];
        block(notFound);
    }];
}
@end
