//
//  ArticleListDictionaryRepresentation.m
//  inspire
//
//  Created by Yuji on 2015/08/11.
//
//

#import "ArticleListDictionaryRepresentation.h"
#import "Article.h"
#import "LightweightArticle.h"
#import "ArticleFolder.h"
#import "AllArticleList.h"
#import "CannedSearch.h"

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
