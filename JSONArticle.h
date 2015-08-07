//
//  JSONArticle.h
//  inspire
//
//  Created by Yuji on 2015/08/07.
//
//

#import <Foundation/Foundation.h>

@interface JSONArticle:NSObject
+(NSString*)requiredFields;
-(instancetype)initWithDictionary:(NSDictionary*)dic;
@property (readonly) NSString*title;
@property (readonly) NSString*recid;
@property (readonly) NSString*spiresKey;
@property (readonly) NSString*eprint;
@property (readonly) NSArray*authors;
@property (readonly) NSString*abstract;
@property (readonly) NSString*collaboration;
@property (readonly) NSNumber*pages;
@property (readonly) NSNumber*citecount;
@property (readonly) NSDate*date;
@property (readonly) NSDictionary*publicationInfo;
@property (readonly) NSString*doi;
@property (readonly) NSString*comment;
@property (readonly) NSString*journalTitle;
@property (readonly) NSString*journalVolume;
@property (readonly) NSString*journalPages;
@property (readonly) NSNumber*journalYear;
@end
