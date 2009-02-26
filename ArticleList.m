// 
//  ArticleList.m
//  spires
//
//  Created by Yuji on 08/10/15.
//  Copyright 2008 Y. Tachikawa. All rights reserved.
//

#import "ArticleList.h"

#import "Article.h"

@implementation ArticleList 

@dynamic name;
@dynamic articles;
@dynamic sortDescriptors;
@dynamic searchString;
@dynamic positionInView;
/*-(id)init
{
    [super init];
    self.sortDescriptor=[NSSet set];
    return self;
}*/
-(void)reload
{
}
-(NSImage*)icon
{
    return nil;
}
/*-(id)valueForUndefinedKey:(NSString*)key
{
    if([key isEqualToString:@"sortDescriptor"]){
	return [[NSSortDescriptor alloc] init];
    }else{
	return [super valueForUndefinedKey:key];
    }
}*/
-(BOOL)searchStringEnabled
{
    return YES;
}

@end
