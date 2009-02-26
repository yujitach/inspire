//
//  IncrementalArrayController.m
//  spires
//
//  Created by Yuji on 09/02/25.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import "IncrementalArrayController.h"


@implementation IncrementalArrayController
-(BOOL)refuseFiltering
{
    return refuseFiltering;
}
-(void)setRefuseFiltering:(BOOL)b
{
    markedString=nil;
    [self rearrangeObjects];
    refuseFiltering=b;
}
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
    if(self.refuseFiltering)
	return previousArray;
//  Now try to shortcut the filtering depending on the search string.
//  The idea is rather heuristic: when the spires query string chaned by adding one alphabetic letter,
//  the result should be a narrowing, so there should be no need to filter an entire array.
//  KVO other than the search string should still cause refiltering,
//  and that is detected by the fact that it will trigger this method without changing the search string.
    if(!markedString || [s isEqualToString:markedString] || [markedString hasSuffix:@" "] || ![s hasPrefix:markedString]){
//	NSLog(@"refiltering: %@:",s);
	[self mark];
	previousArray=[super arrangeObjects:objects];
	return previousArray;
    }else{
//	NSLog(@"shortcutting: %@:",s);
	[self mark];
	previousArray=[super arrangeObjects:previousArray];
	return previousArray;
    }
}
@end
