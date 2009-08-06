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

@property (retain) NSString * volume;
@property (retain) NSString * name;
@property (retain) NSNumber * year;
@property (retain) NSString * page;
@property (retain) NSNumber * endPage;
@property (retain) Article * article;
+(JournalEntry*)journalEntryWithName:(NSString*)name Volume:(NSString*)volume Year:(int)year Page:(NSString*)page inMOC:(NSManagedObjectContext*)moc;
@end


