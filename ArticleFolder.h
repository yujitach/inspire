//
//  ArticleFolder.h
//  spires
//
//  Created by Yuji on 09/03/18.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ArticleList.h"

@interface ArticleFolder : ArticleList {

}
+(ArticleFolder*)articleFolderWithName:(NSString*)s inMOC:(NSManagedObjectContext*)moc;
@end
