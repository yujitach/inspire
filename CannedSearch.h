//
//  CannedSearch.h
//  spires
//
//  Created by Yuji on 4/12/09.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import "ArticleList.h"

@interface CannedSearch : ArticleList {
    BOOL modifying;
}
+(CannedSearch*)createCannedSearchWithName:(NSString*)s inMOC:(NSManagedObjectContext*)moc;
-(void)reloadLocal;
@end
