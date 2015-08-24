//
//  SpiresHelper.h
//  spires
//
//  Created by Yuji on 08/10/16.
//  Copyright 2008 Y. Tachikawa. All rights reserved.
//

@import CoreData;


#define INSPIREWWWHEAD @"http://inspirehep.net/search?p="


@interface SpiresHelper : NSObject
+(SpiresHelper*)sharedHelper;
+(SpiresHelper*)helperWithMOC:(NSManagedObjectContext*)moc;
-(NSPredicate*) predicateFromSPIRESsearchString:(NSString*)string;
-(NSURL*)inspireURLForQuery:(NSString*)search;
-(NSArray*)bibtexEntriesForQuery:(NSString*)search;
-(NSArray*)latexEUEntriesForQuery:(NSString*)search;
-(NSArray*)harvmacEntriesForQuery:(NSString*)search;
@end
