//
//  ArticleFolder.h
//  spires
//
//  Created by Yuji on 09/03/18.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

@import CoreData;
#import "ArticleList.h"

@interface ArticleFolder : ArticleList {

}
+(ArticleFolder*)createArticleFolderWithName:(NSString*)s inMOC:(NSManagedObjectContext*)moc;
@end
