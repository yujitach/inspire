//
//  SpiresXMLArticle.m
//  inspire
//
//  Created by Yuji on 2015/08/09.
//
//

#import "SpiresXMLArticle.h"

@implementation SpiresXMLArticle
{
    NSXMLElement*element;
    NSXMLElement*journal;
}
+(NSURL*)xslURL
{
    static NSURL*xslURL=nil;
    if(!xslURL){
        xslURL=[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"marc2spires" ofType:@"xsl"]];
    }
    return xslURL;
}
+(NSArray*)articlesFromXMLData:(NSData*)data
{
    NSXMLDocument*original=[[NSXMLDocument alloc] initWithData:data options:NSXMLNodeOptionsNone error:NULL];
    NSXMLDocument*doc=[original objectByApplyingXSLTAtURL:[self xslURL]
                                                   arguments:nil
                                                       error:NULL];

    NSXMLElement* root=[doc rootElement];
    NSArray*elements=[root elementsForName:@"document"];
    NSMutableArray*result=[NSMutableArray array];
    for(NSXMLElement*e in elements){
        [result addObject:[[SpiresXMLArticle alloc] initWithXMLElement:e]];
    }
    return result;
}
-(instancetype)initWithXMLElement:(NSXMLElement*)node
{
    self=[super init];
    element=node;
    return self;
}
-(NSXMLElement*)journal
{
    if(!journal){
        NSArray* x=[element elementsForName:@"journal"];
        if(!x || [x count]==0) return nil;
        journal=x[0];
    }
    return journal;
}
-(NSString*)stringForKey:(NSString*)key inXMLElement:(NSXMLElement*)xmlElement
{
    NSArray*a=[xmlElement elementsForName:key];
    if(a==nil||[a count]==0)return nil;
    NSString*s=[a[0] stringValue];
    if(!s || [s isEqualToString:@""])
        return nil;
    return s;
}
-(NSString*)stringForKey:(NSString*)key
{
    return [self stringForKey:key inXMLElement:element];
}
-(NSString*)journalTitle
{
    if(!self.journal) return nil;
    return [self stringForKey:@"name" inXMLElement:self.journal];
}
-(NSString*)journalPage
{
    if(!self.journal) return nil;
    return [self stringForKey:@"page" inXMLElement:self.journal];
}
-(NSString*)journalVolume
{
    if(!self.journal) return nil;
    return [self stringForKey:@"volume" inXMLElement:self.journal];
}
-(NSNumber*)journalYear
{
    if(!self.journal) return nil;
    return @([[self stringForKey:@"year" inXMLElement:self.journal] integerValue]);
}

-(NSString*)eprint
{
    return [self stringForKey:@"eprint"];
}
-(NSString*)spiresKey
{
    return [self stringForKey:@"spires_key"];
}
-(NSString*)inspireKey
{
    return [self stringForKey:@"inspire_key"];
}
-(NSString*)doi
{
    return [self stringForKey:@"doi"];
}
-(NSString*)title
{
    return [self stringForKey:@"title"];
}
-(NSString*)collaboration
{
    return [self stringForKey:@"collaboration"];
}
-(NSString*)abstract
{
    return [self stringForKey:@"abstract"];
}
-(NSString*)comments
{
    return [self stringForKey:@"comments"];
}
-(NSNumber*)citecount
{
    return nil;
}
-(NSNumber*)pages
{
    NSString*p=[self stringForKey:@"pages"];
    if(p){
        return @([p integerValue]);
    }else{
        return nil;
    }
}
-(NSDate*)date
{
    NSString*dateString=[self stringForKey:@"date"];
    if(!dateString || [dateString length]!=8)return nil;
    NSString*year=[dateString substringToIndex:4];
    NSString*month=[dateString substringWithRange:NSMakeRange(4,2)];
    NSDate*date=[NSDate dateWithString:[NSString stringWithFormat:@"%@-%@-01 00:00:00 +0000",year,month]];
    return date;
}
-(NSArray*)authors
{
    NSError*error=nil;
    NSArray*a=[element nodesForXPath:@"authaffgrp/author" error:&error];
    NSMutableArray* array=[NSMutableArray array];
    
    for(NSXMLElement*e in a){
        [array addObject:[e stringValue]];
    }
    return array;
}
@end
