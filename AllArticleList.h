//
//  AllArticleList.h
//  spires
//
//  Created by Yuji on 08/10/15.
//  Copyright 2008 Y. Tachikawa. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "ArticleList.h"

#define LOADED_ENTRIES_MAX 1000

@interface AllArticleList :  ArticleList  
+(AllArticleList*)allArticleListInMOC:(NSManagedObjectContext*)moc;// This returns nil if not found
+(AllArticleList*)allArticleList; //this returns the allArticleList associated to the main MOC!
@end


