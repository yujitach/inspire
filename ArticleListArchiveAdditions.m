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
#import "ArxivNewArticleList.h"
#import "BatchImportOperation.h"
#import "MOC.h"
@interface ArticleList(ArticleListDictionaryRepresentation)
-(NSDictionary*)dictionaryRepresentation;
-(void)loadFromDictionary:(NSDictionary*)dic;
-(NSArray*)arraysOfDictionaryRepresentationOfArticles;
@end

@implementation ArticleList (ArticleListDictionaryRepresentation)
+(NSArray*)arraysOfDictionaryRepresentationOfFlaggedArticlesInMOC:(NSManagedObjectContext*)secondMOC
{
    NSEntityDescription*entity=[NSEntityDescription entityForName:@"Article" inManagedObjectContext:secondMOC];
    NSPredicate*predicate=[NSPredicate predicateWithFormat:@"%K contains %@",@"flagInternal",@"F"];
    NSFetchRequest*req=[[NSFetchRequest alloc] init];
    [req setPredicate:predicate];
    [req setEntity:entity];
    [req setIncludesPropertyValues:YES];
    NSError*error=nil;
    NSArray*articles=[secondMOC executeFetchRequest:req error:&error];

    
    NSMutableArray*ar=[NSMutableArray array];
    for(Article*a in articles){
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
    return @{@"type":NSStringFromClass([self class]),@"name":self.name,@"positionInView":self.positionInView,@"articles":[self arraysOfDictionaryRepresentationOfArticles]};
}
-(void)loadFromDictionary:(NSDictionary *)dic
{
    NSMutableArray*lightweightArticles=[NSMutableArray array];
    for(NSDictionary*subDic in dic[@"articles"]){
        [lightweightArticles addObject:[[LightweightArticle alloc] initWithDictionary:subDic]];
    }
    NSManagedObjectContext*secondMOC=self.managedObjectContext;
    BatchImportOperation*op=[[BatchImportOperation alloc] initWithProtoArticles:lightweightArticles originalQuery:nil updatesCitations:NO usingMOC:secondMOC];
    
    __weak BatchImportOperation*weakOp=op;
    op.completionBlock=^{
        NSSet*generated=weakOp.generated;
        if(!generated)return;
        if(generated.count==0)return;
        [secondMOC performBlock:^{
            [self setArticles:generated];
            [secondMOC save:NULL];
        }];
    };
    [[OperationQueues sharedQueue] addOperation:op];
}
@end
@implementation ArxivNewArticleList (ArticleListDictionaryRepresentation)
-(void)loadFromDictionary:(NSDictionary *)dic
{
    // the difference from the vanila ArticleList is that we do register imported articles to the MOC, but not to the list itself. This is done in order to avoid the following situation: when you first launch the app, the app finds an update from other machine, slowly reading it, while you manually refresh the arxiv/new. Then the arxiv/new obtained from the web is often overwritten from other machine.
    NSMutableArray*lightweightArticles=[NSMutableArray array];
    for(NSDictionary*subDic in dic[@"articles"]){
        [lightweightArticles addObject:[[LightweightArticle alloc] initWithDictionary:subDic]];
    }
    NSManagedObjectContext*secondMOC=self.managedObjectContext;
    BatchImportOperation*op=[[BatchImportOperation alloc] initWithProtoArticles:lightweightArticles originalQuery:nil updatesCitations:NO usingMOC:secondMOC];
    [[OperationQueues sharedQueue] addOperation:op];
}
@end
@implementation CannedSearch (ArticleListDictionaryRepresentation)
-(NSDictionary*)dictionaryRepresentation
{
    NSMutableDictionary*dic=[[super dictionaryRepresentation] mutableCopy];
    if(!self.searchString){
        self.searchString=self.name;
    }
    [dic setValue:self.searchString forKey:@"searchString"];
    return dic;
}
-(void)loadFromDictionary:(NSDictionary *)dic
{
    self.searchString=dic[@"searchString"];
    [super loadFromDictionary:dic];
}
@end


@implementation AllArticleList (ArticleListDictionaryRepresentation)
-(NSDictionary*)dictionaryRepresentation
{
    return nil;
}
-(void)loadFromDictionary:(NSDictionary *)dic
{
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
+(NSDictionary*)articleListForName:(NSString*)name andType:(NSString*)type inArray:(NSArray*)a
{
    for(NSDictionary*dic in a){
        if([dic[@"name"] isEqualToString:name] && [dic[@"type"] isEqualToString:type])
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
    if([articleList isKindOfClass:[ArticleFolder class]]){
        notFoundArray=[self notFoundArticleListsAfterMergingChildren:dic[@"children"] toArticleFolder:(ArticleFolder*)articleList usingMOC:secondMOC];
    }else{
        [articleList loadFromDictionary:dic];
    }
    return notFoundArray;
}
+(void)populateFlaggedArticlesFrom:(NSArray*)a usingMOC:(NSManagedObjectContext*)secondMOC
{
    NSMutableArray*lightweightArticles=[NSMutableArray array];
    for(NSDictionary*subDic in a){
        [lightweightArticles addObject:[[LightweightArticle alloc] initWithDictionary:subDic]];
    }
    BatchImportOperation*op=[[BatchImportOperation alloc] initWithProtoArticles:lightweightArticles originalQuery:nil updatesCitations:NO usingMOC:secondMOC];
    
    __weak BatchImportOperation*weakOp=op;
    op.completionBlock=^{
        NSSet*generated=weakOp.generated;
        if(!generated)return;
        if(generated.count==0)return;
        [secondMOC performBlock:^{
            for(Article*x in generated){
                if(!(x.flag & AFIsFlagged)){
                    x.flag=(x.flag)|AFIsFlagged;
                }
            }
            [secondMOC save:NULL];
        }];
    };
    [[OperationQueues sharedQueue] addOperation:op];
}
+(NSArray*)notFoundArticleListsAfterMergingChildren:(NSArray*)children toArticleFolder:(ArticleFolder*)af usingMOC:(NSManagedObjectContext*)secondMOC
{
    NSLog(@"merging to folder:%@",af?af.name:@"toplevel");
    NSArray*articleLists=[af.children allObjects];
    NSMutableArray*seen=[NSMutableArray array];
    if(!articleLists){
        articleLists=[self topLevelArticleListsFromMOC:secondMOC];
    }
    NSMutableArray*notFound=[NSMutableArray array];
    for(ArticleList*al in articleLists){
        if([al isKindOfClass:[AllArticleList class]])continue;
        NSDictionary*newDic=[self articleListForName:al.name andType:NSStringFromClass([al class]) inArray:children];
        if(newDic){
 //           NSLog(@"existing %@ found in synced content",al.name);
            NSArray*notFoundArray=[self dealWithSyncedAL:newDic withAL:al atFolder:af usingMOC:secondMOC];
            if(notFoundArray){
                [notFound addObjectsFromArray:notFoundArray];
            }
            [seen addObject:al.name];
        }else{
 //           NSLog(@"existing %@ NOT found in synced content",al.name);
            [notFound addObject:al];
        }
    }
    for(NSDictionary*dic in children){
        if([seen containsObject:dic[@"name"]])
            continue;
 //       NSLog(@"new content %@ in synced content",dic[@"name"]);
        [self dealWithSyncedAL:dic withAL:nil atFolder:af usingMOC:secondMOC];
    }
    return notFound;
}
@end
@implementation PrepareSnapshotOperation
-(void)main
{
    NSManagedObjectContext*secondMOC=[[MOC sharedMOCManager] createSecondaryMOC];
    [secondMOC performBlockAndWait:^{
        NSMutableArray*ar=[NSMutableArray array];
        NSArray*topLevelALs=[ArticleList topLevelArticleListsFromMOC:secondMOC];
        NSArray*flagged=[ArticleList arraysOfDictionaryRepresentationOfFlaggedArticlesInMOC:secondMOC];
        for(ArticleList*al in topLevelALs){
            NSDictionary*dic=[al dictionaryRepresentation];
            if(dic){
                [ar addObject:dic];
            }
        }
        [ar sortUsingDescriptors:@[[[NSSortDescriptor alloc] initWithKey:@"positionInView" ascending:YES ]]];
        self.snapShot=@{@"children":ar,@"flagged":flagged};
    }];
    
}
@end

