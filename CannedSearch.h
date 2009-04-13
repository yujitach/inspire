//
//  CannedSearch.h
//  spires
//
//  Created by Yuji on 4/12/09.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ArticleList.h"

@interface CannedSearch : ArticleList {
    BOOL modifying;
    int state;
}
+(CannedSearch*)cannedSearchWithName:(NSString*)s inMOC:(NSManagedObjectContext*)moc;

@end
