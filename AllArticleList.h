//
//  AllArticleList.h
//  spires
//
//  Created by Yuji on 08/10/15.
//  Copyright 2008 Y. Tachikawa. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "ArticleList.h"


@interface AllArticleList :  ArticleList  
{
}

+(AllArticleList*)allArticleListInMOC:(NSManagedObjectContext*)moc;
+(AllArticleList*)createAllArticleListInMOC:(NSManagedObjectContext*)moc;

@end


