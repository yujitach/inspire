//
//  LightweightArticle.h
//  inspire
//
//  Created by Yuji on 2015/08/11.
//
//

#import <Foundation/Foundation.h>
#import "ProtoArticle.h"

@interface LightweightArticle : NSObject<ProtoArticle>
@property (strong) NSString*title;
@property (strong) NSNumber*inspireKey;
@property (strong) NSNumber*spiresKey;
@property (strong) NSString*eprint;
@property (strong) NSArray*authors;
@property (strong) NSString*abstract;
@property (strong) NSString*collaboration;
@property (strong) NSNumber*pages;
@property (strong) NSNumber*citecount;
@property (strong) NSDate*date;
@property (strong) NSString*doi;
@property (strong) NSString*comments;
@property (strong) NSString*journalTitle;
@property (strong) NSString*journalVolume;
@property (strong) NSString*journalPage;
@property (strong) NSNumber*journalYear;
-(void)addAuthor:(NSString*)author;
@end
