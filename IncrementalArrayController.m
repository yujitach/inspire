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
/*-(void)awakeFromNib
{
    [articleListController addObserver:self
			    forKeyPath: @"selection.searchString"
			       options: NSKeyValueObservingOptionNew 
			       context:nil];
    [articleListController addObserver:self
			    forKeyPath: @"selection"
			       options: NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial
			       context:nil];
}
-(void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if(object==articleListController){
	NSArray*a=[articleListController selectedObjects];
	ArticleList*al=nil;
	if([a count]>0){
	    al=[a objectAtIndex:0];
	}
	
	if([keyPath isEqualToString:@"selection"]){
	    if(al && [al isKindOfClass:[AllArticleList class]]){
		listPredicate=[NSPredicate predicateWithValue:YES];
	    }else if(al){
		listPredicate=[NSPredicate predicateWithFormat:@"%@ in inLists", al,nil];
	    }else{
		listPredicate=[NSPredicate predicateWithValue:YES];
	    }
	    //	    listPredicate=[NSPredicate predicateWithValue:YES];
	}
	//else if([keyPath isEqualToString:@"selection.searchString"]){
	    NSPredicate*spiresPredicate=[SpiresPredicateTransformer transformedValue:al.searchString];
	    NSPredicate*combinedPredicate=[NSCompoundPredicate andPredicateWithSubpredicates:[NSArray arrayWithObjects:listPredicate,spiresPredicate,nil]];
//	    NSLog(@"%@",combinedPredicate);
	    [self setFetchPredicate:combinedPredicate];
	    [self fetch:self];
	    [self rearrangeObjects];
//	    [self didChangeArrangementCriteria];
//	}
    }
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}*/
-(id)initWithCoder:(NSCoder*)coder;
{
    self=[super initWithCoder:coder];
    // refuse updating UI right after loaded from the NIB
    refuseFiltering=YES;
    return self;
}
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
    NSString*mark=markedString;
    [self mark];
//  Now try to shortcut the filtering depending on the search string.
//  The idea is rather heuristic: when the spires query string chaned by adding one alphabetic letter,
//  the result should be a narrowing, so there should be no need to filter an entire array.
//  KVO other than the search string should still cause refiltering,
//  and that is detected by the fact that it will trigger this method without changing the search string.
    if(!mark || [s isEqualToString:mark] || [mark hasSuffix:@" "] || ![s hasPrefix:mark]){
//	NSLog(@"refiltering: %@:",s);
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
