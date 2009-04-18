//
//  Article.h
//  spires
//
//  Created by Yuji on 08/10/13.
//  Copyright 2008 Y. Tachikawa. All rights reserved.
//

#import <CoreData/CoreData.h>
typedef enum {
    ATEprint,
    ATSpires,
    ATSpiresWithOnlyKey,
    ATGeneric
} ArticleType;
typedef enum {
    AFNone,
    AFUnread,
    AFRead,
    AFFlagged
} ArticleFlag;
@class JournalEntry;
@interface Article :  NSManagedObject  
{
}

@property (retain) JournalEntry * journal;
@property (retain) NSString * comments;
@property (retain) NSNumber * version;
@property (retain) NSNumber * pages;
@property (retain) NSString * doi;
@property (retain) NSString * eprint;
@property (retain) NSString * spiresKey;
@property (retain) NSString * abstract;
@property (retain,readonly) NSString * pdfPath; 
@property (assign,readonly) BOOL  hasPDFLocally; 
@property (assign,readonly) ArticleType articleType;
@property (retain) NSData* pdfAlias;
@property (retain) NSData* extraURLs;
@property (retain) NSNumber* citecount;
@property (retain) NSString * spicite;
@property (retain) NSString * title;
@property (retain) NSString * memo;
@property (retain) NSDate * date;
@property (retain) NSSet* authors;
@property (retain) NSSet* citedBy;
@property (retain) NSSet* refersTo;
@property (retain) NSString* texKey;
@property (retain,readonly) NSString* uniqueId;
@property (retain,readonly) NSString* IdForCitation;
@property (retain) NSString*normalizedTitle;
@property (retain) NSString*shortishAuthorList;
@property (retain) NSString*longishAuthorListForA;
@property (retain) NSString*longishAuthorListForEA;
@property (retain) NSNumber *eprintForSorting;
@property (assign) ArticleFlag flag;


+(Article*)newArticleInMOC:(NSManagedObjectContext*)moc;
+(Article*)articleWith:(NSString*)value forKey:(NSString*)key inMOC:(NSManagedObjectContext*)moc;
+(Article*)intelligentlyFindArticleWithId:(NSString*)idToLookUp inMOC:(NSManagedObjectContext*)moc;

-(void)associatePDF:(NSString*)path;
-(void)setExtra:(id)content forKey:(NSString*)key;
-(id)extraForKey:(NSString*)key;
@end

@interface Article (CoreDataGeneratedAccessors)
- (void)addAuthorsObject:(NSManagedObject *)value;
- (void)removeAuthorsObject:(NSManagedObject *)value;
- (void)addAuthors:(NSSet *)value;
- (void)removeAuthors:(NSSet *)value;

- (void)addCitedByObject:(NSManagedObject *)value;
- (void)removeCitedByObject:(NSManagedObject *)value;
- (void)addCitedBy:(NSSet *)value;
- (void)removeCitedBy:(NSSet *)value;

- (void)addRefersToObject:(NSManagedObject *)value;
- (void)removeRefersToObject:(NSManagedObject *)value;
- (void)addRefersTo:(NSSet *)value;
- (void)removeRefersTo:(NSSet *)value;

@end

