//
//  SpiresXMLArticle.h
//  inspire
//
//  Created by Yuji on 2015/08/09.
//
//

#import "ProtoArticle.h"

@interface SpiresXMLArticle : ProtoArticle
+(NSArray*)articlesFromXMLData:(NSData*)data;
-(instancetype)initWithXMLElement:(NSXMLElement*)node;
@end
