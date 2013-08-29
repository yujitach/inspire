// 
//  JournalEntry.m
//  spires
//
//  Created by Yuji on 08/10/20.
//  Copyright 2008 Y. Tachikawa. All rights reserved.
//

#import "JournalEntry.h"

#import "Article.h"

@implementation JournalEntry 

@dynamic volume;
@dynamic name;
@dynamic year;
@dynamic page;
@dynamic endPage;
@dynamic article;
+(JournalEntry*)journalEntryWithName:(NSString*)name Volume:(NSString*)vol Year:(int)year Page:(NSString*)page inMOC:(NSManagedObjectContext*)moc;
{
    NSEntityDescription*journalEntity=[NSEntityDescription entityForName:@"JournalEntry" inManagedObjectContext:moc];
    JournalEntry* mo=(JournalEntry*)[[NSManagedObject alloc] initWithEntity:journalEntity
				 insertIntoManagedObjectContext:moc];
    mo.volume=vol;
    mo.year=@(year);
    mo.name=name;
    mo.page=page;
    return mo;
}
@end
