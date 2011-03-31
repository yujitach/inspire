//
//  Article.h
//  spires
//
//  Created by Yuji on 08/10/13.
//  Copyright 2008 Y. Tachikawa. All rights reserved.
//

#import <CoreData/CoreData.h>
typedef enum {
    AFNone=0,
    AFIsUnread=1,
    AFIsFlagged=2,
    AFHasPDF=4
} ArticleFlag;
@class JournalEntry;
@class ArticleData;
@interface Article :  NSManagedObject  
{
}

#pragma mark intrinsic
@property (retain) JournalEntry * journal;
@property (retain) NSString * flagInternal;
@property (retain) NSSet* citedBy;
@property (retain) NSSet* refersTo;
@property (retain) NSNumber* citecount;
@property (retain) NSString*normalizedTitle;
@property (retain) NSString*longishAuthorListForA;
@property (retain) NSNumber *eprintForSorting;
@property (retain) ArticleData*data;
#pragma mark forwarded to data
@property (retain) NSString * abstract;
@property (retain) NSString * arxivCategory;
@property (retain) NSString * collaboration;
@property (retain) NSString * comments;
@property (retain) NSDate * date;
@property (retain) NSString * doi;
@property (retain) NSString * eprint;
@property (retain) NSString*longishAuthorListForEA;
@property (retain) NSString * memo;
@property (retain) NSNumber * pages;
@property (retain) NSString*shortishAuthorList;
@property (retain) NSString* texKey;
@property (retain) NSString * title;
@property (retain) NSNumber * version;
@property (retain) NSString * spicite;
@property (retain) NSNumber * spiresKey;
@property (retain) NSNumber * inspireKey;
#pragma mark generated
@property (assign,readonly) BOOL hasPDFLocally; 
@property (assign,readonly) BOOL isEprint;
@property (retain,readonly) NSString * pdfPath; 
@property (retain,readonly) NSString* uniqueSpiresQueryString;
@property (retain,readonly) NSString* IdForCitation;
@property (assign) ArticleFlag flag;
@property (retain) NSString *eprintForSortingAsString;


//+(Article*)articleWith:(NSString*)value inDataForKey:(NSString*)key inMOC:(NSManagedObjectContext*)moc;
+(Article*)intelligentlyFindArticleWithId:(NSString*)idToLookUp inMOC:(NSManagedObjectContext*)moc;
+(NSString*)eprintForSortingFromEprint:(NSString*)eprint;

-(void)associatePDF:(NSString*)path;
-(void)setExtra:(id)content forKey:(NSString*)key;
-(id)extraForKey:(NSString*)key;
-(void)setAuthorNames:(NSArray*)authorNames;
@end

@interface Article (CoreDataGeneratedAccessors)

- (void)addCitedByObject:(NSManagedObject *)value;
- (void)removeCitedByObject:(NSManagedObject *)value;
- (void)addCitedBy:(NSSet *)value;
- (void)removeCitedBy:(NSSet *)value;

- (void)addRefersToObject:(NSManagedObject *)value;
- (void)removeRefersToObject:(NSManagedObject *)value;
- (void)addRefersTo:(NSSet *)value;
- (void)removeRefersTo:(NSSet *)value;


@end

