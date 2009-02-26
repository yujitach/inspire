//
//  ArxivMetadataFetchOperation.m
//  spires
//
//  Created by Yuji on 09/02/08.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import "ArxivMetadataFetchOperation.h"
#import "Article.h"
#import "ArxivHelper.h"
#import "NSManagedObjectContext+TrivialAddition.h"

@implementation ArxivMetadataFetchOperation
-(ArxivMetadataFetchOperation*)initWithArticle:(Article*)a;
{
    [super init];
    article=a;
    return self;
}
-(NSString*)description
{
    return [NSString stringWithFormat:@"fetching metadata for %@",article.eprint];
}
-(void)main
{    
    [[ArxivHelper sharedHelper] onlineMetaDataForID:article.eprint
					   delegate:self 
				     didEndSelector:@selector(fetchMetaDataFromArxivReturnPDFNoCheck:) ];
}
-(void)fetchMetaDataFromArxivReturnPDFNoCheck:(NSDictionary*)dict
{
    if(dict){
	[[[[NSApplication sharedApplication] delegate] managedObjectContext] disableUndo];
	article.abstract=[dict objectForKey:@"abstract"];
	article.version=[dict objectForKey:@"version"];    
	article.comments=[dict objectForKey:@"comments"];
	[[[[NSApplication sharedApplication] delegate] managedObjectContext] enableUndo];
    }
    [self finish];
}
@end
