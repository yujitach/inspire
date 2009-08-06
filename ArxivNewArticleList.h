//
//  ArxivNewArticleList.h
//  spires
//
//  Created by Yuji on 08/10/15.
//  Copyright 2008 Y. Tachikawa. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "ArticleList.h"


@interface ArxivNewArticleList :  ArticleList  
{
}

+(ArxivNewArticleList*)arXivNewArticleListWithName:(NSString*)s inMOC:(NSManagedObjectContext*)moc;

@end


