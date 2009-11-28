//
//  ArticleData.h
//  spires
//
//  Created by Yuji on 11/27/09.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import <CoreData/CoreData.h>

@class Article;
@interface ArticleData : NSManagedObject {

}
@property (retain) NSString * abstract;
@property (retain) NSNumber* citecount;
@property (retain) NSString * comments;
@property (retain) NSDate * date;
@property (retain) NSString * doi;
@property (retain) NSString * eprint;
@property (retain) NSData* extraURLs;
@property (retain) NSString* longishAuthorListForEA;
@property (retain) NSString * memo;
@property (retain) NSNumber * pages;
@property (retain) NSData* pdfAlias;
@property (retain) NSString*shortishAuthorList;
@property (retain) NSString * spicite;
@property (retain) NSNumber * spiresKey;
@property (retain) NSString* texKey;
@property (retain) NSString * title;
@property (retain) NSNumber * version;
@property (retain) Article* article;

@end
