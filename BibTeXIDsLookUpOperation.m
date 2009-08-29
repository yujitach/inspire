//
//  BibTeXIDsLookUpOperation.m
//  spires
//
//  Created by Yuji on 7/5/09.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import "BibTeXIDsLookUpOperation.h"
#import "MOC.h"
#import "Article.h"
#import "BatchBibQueryOperation.h"

@implementation BibTeXIDsLookUpOperation
-(id)initWithKeys:(NSArray*)a parent:(NSOperation*)p;
{
    self=[super init];
    keys=a;
    parent=p;
    return self;
}
-(NSString*)description
{
    return [NSString stringWithFormat:@"BibTeX lookup for IDs %@, etc.",[keys anyObject]];
}
-(void)run
{
    self.isExecuting=YES;
    NSMutableArray*as=[NSMutableArray array];
    for(NSString*key in keys){
	Article*a=[Article intelligentlyFindArticleWithId:key inMOC:[MOC moc]];
	NSLog(@"key:%@ article:%@",key,a);
	if(a){
	    [as addObject:a];
	}
    }
    NSOperation*op=[[BatchBibQueryOperation alloc] initWithArray:as];
    if(parent){
	[parent addDependency:op];
    }
    [[OperationQueues spiresQueue] addOperation:op];
    [self finish];
}
@end
