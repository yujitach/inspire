//
//  ProtoArticle.h
//  inspire
//
//  Created by Yuji on 2015/08/09.
//
//

#import <Foundation/Foundation.h>

@protocol ProtoArticle<NSObject>
@property (readonly) NSString*title;
@property (readonly) NSNumber*inspireKey;
@property (readonly) NSNumber*spiresKey;
@property (readonly) NSString*eprint;
@property (readonly) NSArray*authors;
@property (readonly) NSString*abstract;
@property (readonly) NSString*collaboration;
@property (readonly) NSNumber*pages;
@property (readonly) NSNumber*citecount;
@property (readonly) NSDate*date;
@property (readonly) NSString*doi;
@property (readonly) NSString*comments;
@property (readonly) NSString*journalTitle;
@property (readonly) NSString*journalVolume;
@property (readonly) NSString*journalPage;
@property (readonly) NSNumber*journalYear;
@end
