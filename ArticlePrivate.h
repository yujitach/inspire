//
//  ArticlePrivate.h
//  spires
//
//  Created by Yuji on 12/15/09.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface Article (private)
+(NSString*)longishAuthorListForAFromAuthorNames:(NSArray*)array;
+(NSString*)longishAuthorListForEAFromAuthorNames:(NSArray*)array;
+(NSString*)shortishAuthorListFromAuthorNames:(NSArray*)array;
+(NSString*)flagInternalFromFlag:(ArticleFlag)flag;
+(ArticleFlag)flagFromFlagInternal:(NSString*)flagInternal;
@end
