//
//  ArticleListDictionaryRepresentation.h
//  inspire
//
//  Created by Yuji on 2015/08/11.
//
//

#import "ArticleList.h"

@interface ArticleList(ArticleListDictionaryRepresentation)
-(NSDictionary*)dictionaryRepresentation;
-(NSArray*)arraysOfDictionaryRepresentationOfArticles;
@end
