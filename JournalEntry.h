//
//  JournalEntry.h
//  spires
//
//  Created by Yuji on 08/10/20.
//  Copyright 2008 Y. Tachikawa. All rights reserved.
//

#import <CoreData/CoreData.h>

@class Article;

@interface JournalEntry :  NSManagedObject  
{
}

@property  NSString * volume;
@property  NSString * name;
@property  NSNumber * year;
@property  NSString * page;
@property  NSNumber * endPage;
@property  Article * article;
+(JournalEntry*)journalEntryWithName:(NSString*)name Volume:(NSString*)volume Year:(NSNumber*)year Page:(NSString*)page inMOC:(NSManagedObjectContext*)moc;
@end


