//
//  InspireJSONTransformer.m
//  inspire
//
//  Created by Yuji on 2020/06/10.
//

#import "InspireJSONTransformer.h"
#import "LightweightArticle.h"

@implementation InspireJSONTransformer
+(NSArray*)articlesFromJSON:(NSDictionary*)jsonDict
{
    static NSDateFormatter*df=nil;
    static NSDateFormatter*ymdf=nil;
    static NSDateFormatter*ydf=nil;
    if(!df){
        df=[[NSDateFormatter alloc] init];
        df.dateFormat=@"yyyy-MM-dd";
        df.timeZone=[NSTimeZone timeZoneForSecondsFromGMT:0];
        df.locale=[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    }
    if(!ymdf){
        ymdf=[[NSDateFormatter alloc] init];
        ymdf.dateFormat=@"yyyy-MM";
        ymdf.timeZone=[NSTimeZone timeZoneForSecondsFromGMT:0];
        ymdf.locale=[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    }
    if(!ydf){
        ydf=[[NSDateFormatter alloc] init];
        ydf.dateFormat=@"yyyy";
        ydf.timeZone=[NSTimeZone timeZoneForSecondsFromGMT:0];
        ydf.locale=[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    }
    NSMutableArray*array=[NSMutableArray array];
    NSDictionary*h=jsonDict[@"hits"];
    NSArray*hits=h[@"hits"];
    for(NSDictionary*entry in hits){
        LightweightArticle*article=[[LightweightArticle alloc] init];
        article.inspireKey=[NSNumber numberWithInteger:[entry[@"id"] integerValue]];
        NSDictionary*metadata=entry[@"metadata"];
        {
            NSArray*as=metadata[@"authors"];
            for(NSDictionary*a in as){
                [article addAuthor:a[@"full_name"]];
            }
        }
        {
            NSArray*as=metadata[@"abstracts"];
            BOOL found=NO;
            for(NSDictionary*a in as){
                NSString*source=a[@"source"];
                if([source isEqualToString:@"arXiv"]){
                    article.abstract=a[@"value"];
                    found=YES;
                    break;
                }
            }
            if(!found && as && as[0]){
                NSDictionary*a=as[0];
                article.abstract=a[@"value"];
            }
        }
        {
            NSArray*as=metadata[@"collaborations"];
            NSDictionary*a=as[0];
            if(a){
                article.collaboration=a[@"value"];
            }
        }
        {
            NSArray*as=metadata[@"arxiv_eprints"];
            NSDictionary*a=as[0];
            if(a){
                NSString*s=a[@"value"];
                if(![s containsString:@"/"]){
                    s=[@"arXiv:" stringByAppendingString:s];
                }
                article.eprint=s;
            }
        }
        {
            NSArray*as=metadata[@"titles"];
            BOOL found=NO;
            for(NSDictionary*a in as){
                NSString*source=a[@"source"];
                if([source isEqualToString:@"arXiv"]){
                    article.title=a[@"title"];
                    found=YES;
                    break;
                }
            }
            if(!found && as && as[0]){
                NSDictionary*a=as[0];
                article.title=a[@"title"];
            }
        }
        {
            NSString*numString=metadata[@"number_of_pages"];
            if(numString){
                article.pages=[NSNumber numberWithInteger:[numString integerValue]];
            }
        }
        {
            NSArray*as=metadata[@"publication_info"];
            NSDictionary*a=as[0];
            if(a){
                NSString*page=a[@"page_start"];
                if(!page){
                    page=a[@"artid"];
                }
                article.journalPage=page;
                article.journalYear=[NSNumber numberWithInteger:[a[@"year"] integerValue]];
                article.journalTitle=a[@"journal_title"];
                article.journalVolume=a[@"journal_volume"];
            }
        }
        {
            NSString*dateString=metadata[@"earliest_date"];
            NSDate*date=[df dateFromString:dateString];
            if(date){
                article.date=date;
            }else{
                date=[ymdf dateFromString:dateString];
                if(date){
                    article.date=date;
                }else{
                    date=[ydf dateFromString:dateString];
                    article.date=date;
                }
            }
        }
        {
            NSArray*as=metadata[@"dois"];
            NSDictionary*a=as[0];
            if(a){
                article.doi=a[@"value"];
            }
        }
        {
            article.citecount=[NSNumber numberWithInteger:[metadata[@"citation_count"] integerValue]];
        }
        [array addObject:article];
    }
    return array;
}
@end
