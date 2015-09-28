//
//  ArxivMetadataFetchOperation.m
//  spires
//
//  Created by Yuji on 09/02/08.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import "ArxivMetadataFetchOperation.h"
#import "Article.h"
#import "NSString+magic.h"
#import "MOC.h"

@implementation ArxivMetadataFetchOperation
{
    Article*article;
    NSString*arXivID;
    NSString*xmlString;
}

-(ArxivMetadataFetchOperation*)initWithArticle:(Article*)a;
{
    self=[super init];
    article=a;
    arXivID=a.eprint;
    return self;
}
-(NSString*)description
{
    return [NSString stringWithFormat:@"fetching metadata for %@",article.eprint];
}
-(NSString*)valueForXMLTag:(NSString*)tag
{
    NSString*regex=[NSString stringWithFormat:@"<%@[^>]*>(.+?)</%@",tag,tag];
    NSString*s=[xmlString stringByMatching:regex options:RKLDotAll inRange:NSMakeRange(0,xmlString.length) capture:1 error:NULL];
    if(!s || [s isEqualToString:@""])
        return nil;
    return s;
}

-(void)main
{    
    // see http://export.arxiv.org/api_help/docs/user-manual.html
    if([arXivID hasPrefix:@"arXiv:"]){
        arXivID=[arXivID substringFromIndex:[(NSString*)@"arXiv:" length]];
    }
    NSURL* url=[NSURL URLWithString:[NSString stringWithFormat:@"http://export.arxiv.org/api/query?id_list=%@",arXivID]];
    NSLog(@"query:%@",url);
    xmlString=[NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:NULL];
    xmlString=[self valueForXMLTag:@"entry"];
    NSMutableDictionary* dict=[NSMutableDictionary dictionary];
    
    {
        NSString* comment=[self valueForXMLTag:@"arxiv:comment"];
        if(comment){
            comment=[comment stringByReplacingOccurrencesOfString:@"\n " withString:@" "];
            comment=[comment stringByReplacingOccurrencesOfString:@" \n" withString:@" "];
            comment=[comment stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
            dict[@"comments"]=comment;
        }
    }
    
    {
        NSString*pc=[xmlString stringByMatching:@"term=\"([^\"]+)\"" capture:1];
        if(pc && ![pc isEqualToString:@""]){
            dict[@"primaryCategory"]=pc;
        }
    }

    {
        NSString* s=[self valueForXMLTag:@"id"];
        s=[s substringFromIndex:[(NSString*)@"http://arxiv.org/abs/" length]];
        NSArray*a=[s componentsSeparatedByString:@"v"];
        
        int v=[[a lastObject] intValue];
        if(v==0){
            dict=nil;
        }else{
            dict[@"version"]=@(v);
            NSString*abstract=[self valueForXMLTag:@"summary"];
            [dict setValue:abstract forKey:@"abstract"];
        }
    }
    {
        NSString*title=[self valueForXMLTag:@"title"];
        title=[title stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
        title=[title stringByReplacingOccurrencesOfRegex:@" +" withString:@" "];
        dict[@"title"]=title;
    }
    if(dict){
        [article.managedObjectContext performBlock:^{
            [[article managedObjectContext] disableUndo];
            article.abstract=dict[@"abstract"];
            article.version=dict[@"version"];
            article.comments=dict[@"comments"];
            if(![[article.title lowercaseString] isEqualToString:[dict[@"title"] lowercaseString]]){
                article.title=dict[@"title"];
            }
            article.arxivCategory=dict[@"primaryCategory"];
            [[article managedObjectContext] enableUndo];
        }];
    }
}
@end
