//
//  InspireXMLArticle.h
//  inspire
//
//  Created by Yuji on 2015/08/09.
//
//

#import "ProtoArticle.h"

@interface InspireXMLArticle : ProtoArticle
+(NSString*)usedTags;
+(NSArray*)articlesFromXMLData:(NSData*)data;
@end
