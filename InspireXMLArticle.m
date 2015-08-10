//
//  InspireXMLArticle.m
//  inspire
//
//  Created by Yuji on 2015/08/09.
//
//

#import "InspireXMLArticle.h"

@interface InspireXMLArticle ()
-(void)addAuthor:(NSString*)name;
@end


@interface InspireXMLParser: NSObject<NSXMLParserDelegate>
-(instancetype)initWithXMLData:(NSData*)data;
@property (readonly) NSMutableArray*articles;
@end


@implementation InspireXMLParser
{
    NSMutableString*currentString;
    NSString*currentTag;
    NSString*currentCode;
    NSMutableDictionary*subfieldDic;
    InspireXMLArticle*currentArticle;
}
@synthesize articles;
-(instancetype)initWithXMLData:(NSData*)data
{
    self=[super init];
    @autoreleasepool {
        NSXMLParser*parser=[[NSXMLParser alloc]initWithData:data];
        parser.delegate=self;
        [parser parse];
    }
    return self;
}
-(void)parserDidStartDocument:(NSXMLParser *)parser
{
    articles=[NSMutableArray array];
}
-(void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
    currentString=[NSMutableString string];
    if([elementName isEqualToString:@"record"]){
        currentArticle=[[InspireXMLArticle alloc] init];
    }else if([elementName isEqualToString:@"controlfield"]){
        
    }else if([elementName isEqualToString:@"datafield"]){
        currentTag=attributeDict[@"tag"];
        subfieldDic=[NSMutableDictionary dictionary];
    }else if([elementName isEqualToString:@"subfield"]){
        currentCode=attributeDict[@"code"];
    }
}
-(void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
    if([elementName isEqualToString:@"record"]){
        [articles addObject:currentArticle];
        currentArticle=nil;
    }else if([elementName isEqualToString:@"controlfield"]){
        [currentArticle setValue:currentString forKey:@"inspireKey"];
    }else if([elementName isEqualToString:@"datafield"]){
        if([currentTag isEqualToString:@"970"]){
            NSString*s=subfieldDic[@"a"];
            [currentArticle setValue:[s substringFromIndex:[@"SPIRES-" length]] forKey:@"spiresKey"];
        }else if([currentTag isEqualToString:@"100"]){
            [currentArticle addAuthor:subfieldDic[@"a"]];
        }else if([currentTag isEqualToString:@"700"]){
            [currentArticle addAuthor:subfieldDic[@"a"]];
        }else if([currentTag isEqualToString:@"710"]){
            [currentArticle setValue:subfieldDic[@"g"] forKey:@"collaboration"];
        }else if([currentTag isEqualToString:@"520"]){
            if([subfieldDic[@"9"] isEqualToString:@"arXiv"]){
                [currentArticle setValue:subfieldDic[@"a"] forKey:@"abstract"];
            }
        }else if([currentTag isEqualToString:@"037"]){
            if([subfieldDic[@"9"] isEqualToString:@"arXiv"]){
                [currentArticle setValue:subfieldDic[@"a"] forKey:@"eprint"];
            }
        }else if([currentTag isEqualToString:@"245"]){
            [currentArticle setValue:subfieldDic[@"a"] forKey:@"title"];
        }else if([currentTag isEqualToString:@"300"]){
            [currentArticle setValue:@([subfieldDic[@"a"] integerValue]) forKey:@"pages"];
        }else if([currentTag isEqualToString:@"773"]){
            NSString*title=subfieldDic[@"p"];
            if(title && ![title isEqualToString:@""]){
                [currentArticle setValue:title forKey:@"journalTitle"];
                [currentArticle setValue:subfieldDic[@"v"] forKey:@"journalVolume"];
                [currentArticle setValue:subfieldDic[@"c"] forKey:@"journalPage"];
                [currentArticle setValue:@([subfieldDic[@"y"] integerValue]) forKey:@"journalYear"];
            }
        }else if([currentTag isEqualToString:@"961"]){
            NSString*dateString=subfieldDic[@"x"];
            if(dateString){
                if([dateString length]==7){
                    dateString=[dateString stringByAppendingString:@"-00"];
                }
                NSDate*date=[NSDate dateWithString:[NSString stringWithFormat:@"%@ 00:00:00 +0000",dateString]];
                [currentArticle setValue:date forKey:@"date"];
            }
        }else if([currentTag isEqualToString:@"024"]){
            if([subfieldDic[@"2"] isEqualToString:@"DOI"]){
                [currentArticle setValue:subfieldDic[@"a" ] forKey:@"doi"];
            }
        }
        subfieldDic=nil;
    }else if([elementName isEqualToString:@"subfield"]){
        subfieldDic[currentCode]=currentString;
    }
    currentString=nil;
}
-(void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
    [currentString appendString:string];
}
@end

@implementation InspireXMLArticle
{
    NSMutableArray*authorArray;
}
+(NSString*)usedTags
{
    return @"001,970,100,700,710,520,037,245,300,773,961,024";
}
+(NSArray*)articlesFromXMLData:(NSData*)data
{
    InspireXMLParser*parser=[[InspireXMLParser alloc] initWithXMLData:data];
    return parser.articles;
}
-(instancetype)init
{
    self=[super init];
    authorArray=[NSMutableArray array];
    return self;
}
-(NSArray*)authors
{
    return authorArray;
}
-(void)addAuthor:(NSString*)name
{
    [authorArray addObject:name];
}
@end
