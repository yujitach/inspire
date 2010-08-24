//
//  IncrementalArrayController.m
//  spires
//
//  Created by Yuji on 09/02/25.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import "IncrementalArrayController.h"
#import "ArticleList.h"
#import "AllArticleList.h"
#import "SpiresPredicateTransformer.h"
@implementation IncrementalArrayController
-(void)mark;
{
    NSString*s=[tf stringValue];
    if(s && ![s isEqualToString:@""]){
	markedString=s;
    }else{
	markedString=nil;
    }
}
- (NSArray *)arrangeObjects:(NSArray *)objects
{
    NSString*s=[tf stringValue];
    NSString*mark=markedString;
    [self mark];
//  Now try to shortcut the filtering depending on the search string.
//  The idea is rather heuristic: when the spires query string chaned by adding one alphabetic letter,
//  the result should be a narrowing, so there should be no need to filter an entire array.
//  KVO other than the search string should still cause refiltering,
//  and that is detected by the fact that it will trigger this method without changing the search string.
    if(!mark || [s isEqualToString:mark] || [mark hasSuffix:@" "] || ![s hasPrefix:mark]){
//	NSLog(@"refiltering: %@:",s);
//	NSLog(@"desc:%@",[self sortDescriptors]);
	previousArray=[super arrangeObjects:objects];
	return previousArray;
    }else{ // shares the same prefix
	NSRange r=[s rangeOfString:mark];
	NSString*t=[s substringFromIndex:r.location+r.length];
	if(t && [t rangeOfString:@" "].location!=NSNotFound ){
//	    NSLog(@"refiltering!: %@:",s);
	    previousArray=[super arrangeObjects:objects];	    
	}else{
//	NSLog(@"shortcutting: %@:",s);
	    previousArray=[super arrangeObjects:previousArray];
	}
	return previousArray;
    }
}
@end
