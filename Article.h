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

// title should contain strings WITHOUT ampersand-escapes,
// abstract should contain strings WITH ampersand-escapes.
#pragma mark intrinsic
@property  JournalEntry * journal;
@property  NSString * flagInternal;
@property  NSSet* citedBy;
@property  NSSet* refersTo;
@property  NSNumber* citecount;
@property  NSString*normalizedTitle;
@property  NSString*longishAuthorListForA;
@property  NSNumber *eprintForSorting;
@property  ArticleData*data;
#pragma mark forwarded to data
@property  NSString * abstract;
@property  NSString * arxivCategory;
@property  NSString * collaboration;
@property  NSString * comments;
@property  NSDate * date;
@property  NSString * doi;
@property  NSString * eprint;
@property  NSString*longishAuthorListForEA;
@property  NSString * memo;
@property  NSNumber * pages;
@property  NSString*shortishAuthorList;
@property  NSString* texKey;
@property  NSString * title;
@property  NSNumber * version;
//@property  NSString * spicite;
@property  NSNumber * spiresKey;
@property  NSNumber * inspireKey;
#pragma mark generated
@property (assign,readonly) BOOL hasPDFLocally; 
@property (assign,readonly) BOOL isEprint;
@property (readonly) NSString * quieterTitle; 
@property (readonly) NSString * pdfPath; 
@property (readonly) NSString* uniqueSpiresQueryString;
@property (readonly) NSString* uniqueInspireQueryString;
@property (readonly) NSString* IdForCitation;
@property (assign) ArticleFlag flag;
//@property  NSString *eprintForSortingAsString;


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

