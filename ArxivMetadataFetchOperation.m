//
//  ArxivMetadataFetchOperation.m
//  spires
//
//  Created by Yuji on 09/02/08.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import "ArxivMetadataFetchOperation.h"
#import "Article.h"
#import "MOC.h"

@implementation ArxivMetadataFetchOperation
-(ArxivMetadataFetchOperation*)initWithArticle:(Article*)a;
{
    [super init];
    article=a;
    arXivID=a.eprint;
    return self;
}
-(NSString*)description
{
    return [NSString stringWithFormat:@"fetching metadata for %@",article.eprint];
}
-(NSString*)valueForKey:(NSString*)key inXMLElement:(NSXMLElement*)element
{
    NSArray*a=[element elementsForName:key];
    if(a==nil||[a count]==0)return nil;
    NSString*s=[[a objectAtIndex:0] stringValue];
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
    NSError*error=nil;
    NSXMLDocument* doc=[[NSXMLDocument alloc] initWithContentsOfURL:url options:0 error:&error];
    if(!doc){
	NSLog(@"XML error: %@",error);
	return;
    }
    NSXMLElement* elem=nil;
    {
	NSArray*ar=[[doc rootElement] elementsForName:@"entry"];
	if(!ar || [ar count]==0){
	    return;
	}
	elem=[ar objectAtIndex:0];
    }
    NSMutableDictionary* dict=[NSMutableDictionary dictionary];
    
    NSString* s=[self valueForKey:@"id" inXMLElement:elem];
    s=[s substringFromIndex:[(NSString*)@"http://arxiv.org/abs/" length]];
    NSArray*a=[s componentsSeparatedByString:@"v"];
    NSString* comment=[self valueForKey:@"arxiv:comment" inXMLElement:elem];
    if(comment){
	comment=[comment stringByReplacingOccurrencesOfString:@"\n " withString:@" "];
	comment=[comment stringByReplacingOccurrencesOfString:@" \n" withString:@" "];
	comment=[comment stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
	[dict setValue:comment forKey:@"comments"];
    }
    
    {
	NSArray*ar=[elem elementsForName:@"arxiv:primary_category"];
	if(ar && [ar count]>0){
	    NSXMLElement*x=[ar objectAtIndex:0];
	    NSString*pc=[[x attributeForName:@"term"] stringValue];
	    [dict setValue:pc forKey:@"primaryCategory"];
	}
    }
    
    int v=[[a lastObject] intValue];
    if(v==0){
	dict=nil;
    }else{
	[dict setValue:[NSNumber numberWithInt:v] forKey:@"version"];
	NSString*abstract=[self valueForKey:@"summary" inXMLElement:elem];
	// abstract is kept as an HTML, but XML decoder automatically converts &-escapes into real alphabets.
	// so I need to reverse them. Ugh.
	abstract=[abstract stringByReplacingOccurrencesOfString:@"&" withString:@"&amp;"];
	abstract=[abstract stringByReplacingOccurrencesOfString:@"<" withString:@"&lt;"];
	abstract=[abstract stringByReplacingOccurrencesOfString:@">" withString:@"&gt;"];
	[dict setValue:abstract forKey:@"abstract"];
    }
    if(dict){dispatch_async(dispatch_get_main_queue(),^{
	[[article managedObjectContext] disableUndo];
	article.abstract=[dict objectForKey:@"abstract"];
	article.version=[dict objectForKey:@"version"];    
	article.comments=[dict objectForKey:@"comments"];
	NSString*title=[self valueForKey:@"title" inXMLElement:elem];
	if(![[article.title lowercaseString] isEqualToString:[title lowercaseString]]){
	    article.title=title;
	}
	article.arxivCategory=[dict objectForKey:@"primaryCategory"];
	[[article managedObjectContext] enableUndo];
    });}
}
@end
