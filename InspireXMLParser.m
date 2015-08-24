//
//  InspireXMLArticle.m
//  inspire
//
//  Created by Yuji on 2015/08/09.
//
//

#import "InspireXMLParser.h"
#import "LightweightArticle.h"

@interface InspireXMLParser ()
@property NSMutableArray*articles;
@end

@implementation InspireXMLParser
{
    NSMutableString*currentString;
    NSString*currentTag;
    NSString*currentCode;
    NSMutableDictionary*subfieldDic;
    LightweightArticle*currentArticle;
    NSDateFormatter*df;
}
@synthesize articles;
+(NSString*)usedTags
{
    return @"001,970,100,700,710,520,037,245,300,773,961,269,024";
}
+(NSArray*)articlesFromXMLData:(NSData*)data
{
    InspireXMLParser*parser=[[InspireXMLParser alloc] initWithXMLData:data];
    return parser.articles;
}
-(instancetype)initWithXMLData:(NSData*)data
{
    self=[super init];
    @autoreleasepool {
        df=[[NSDateFormatter alloc] init];
        df.dateFormat=@"yyyy-MM-dd";
        df.timeZone=[NSTimeZone timeZoneForSecondsFromGMT:0];
        df.locale=[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
        
        [data writeToFile:@"/tmp/inspireOutput.xml" atomically:NO];
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
        currentArticle=[[LightweightArticle alloc] init];
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
        currentArticle.inspireKey=@([currentString integerValue]);
    }else if([elementName isEqualToString:@"datafield"]){
        if([currentTag isEqualToString:@"970"]){
            NSString*s=subfieldDic[@"a"];
            NSString*spiresKey=[s substringFromIndex:[@"SPIRES-" length]];
            currentArticle.spiresKey=@([spiresKey integerValue]);
        }else if([currentTag isEqualToString:@"100"]){
            [currentArticle addAuthor:subfieldDic[@"a"]];
        }else if([currentTag isEqualToString:@"700"]){
            [currentArticle addAuthor:subfieldDic[@"a"]];
        }else if([currentTag isEqualToString:@"710"]){
            currentArticle.collaboration=subfieldDic[@"g"];
        }else if([currentTag isEqualToString:@"520"]){
            if([subfieldDic[@"9"] isEqualToString:@"arXiv"]){
                currentArticle.abstract=subfieldDic[@"a"];
            }
        }else if([currentTag isEqualToString:@"037"]){
            if([subfieldDic[@"9"] isEqualToString:@"arXiv"]){
                currentArticle.eprint=subfieldDic[@"a"];
            }
        }else if([currentTag isEqualToString:@"245"]){
            currentArticle.title=subfieldDic[@"a"];
        }else if([currentTag isEqualToString:@"300"]){
            currentArticle.pages=@([subfieldDic[@"a"] integerValue]);
        }else if([currentTag isEqualToString:@"773"]){
            NSString*title=subfieldDic[@"p"];
            if(title && ![title isEqualToString:@""]){
                currentArticle.journalTitle=title;
                currentArticle.journalVolume=subfieldDic[@"v"];
                currentArticle.journalPage=subfieldDic[@"c"];
                currentArticle.journalYear=@([subfieldDic[@"y"] integerValue]);
            }
        }else if([currentTag isEqualToString:@"269"]){
            NSString*dateString=subfieldDic[@"c"];
            if(dateString){
                if([dateString length]==7){
                    dateString=[dateString stringByAppendingString:@"-01"];
                }
                NSDate*date=[df dateFromString:dateString];
                currentArticle.date=date;
            }
        }else if([currentTag isEqualToString:@"961"]){
            if(!(currentArticle.date)){
                NSString*dateString=subfieldDic[@"x"];
                if(dateString){
                    if([dateString length]==7){
                        dateString=[dateString stringByAppendingString:@"-01"];
                    }
                    NSDate*date=[df dateFromString:dateString];
                    currentArticle.date=date;
                }
            }
        }else if([currentTag isEqualToString:@"024"]){
            if([subfieldDic[@"2"] isEqualToString:@"DOI"]){
                currentArticle.doi=subfieldDic[@"a"];
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

