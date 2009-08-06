/*
 *  NSOpenPanel+NDAlias.m category
 *
 *  Created by Sean McBride on Sat Aug 16 2007.
 *  Copyright 2007 Nathan Day. All rights reserved.
 */

#import "NSOpenPanel+NDAlias.h"

#import "NDAlias.h"

/*
 * class implementation NSOpenPanel (NDAlias)
 */
@implementation NSOpenPanel (NDAlias)

/*
 * -aliases
 */
- (NSArray *)aliases
{
	NSMutableArray *	aliases = nil;
	NSArray *			filenames = [self filenames];
	NSUInteger			i;
	if (filenames != nil)
	{
		aliases = [NSMutableArray array];
		for( i = 0; i < [filenames count]; i++)
		{
			NDAlias *		anAlias = [NDAlias aliasWithPath:[filenames objectAtIndex:i]];
			[aliases addObject:anAlias];
		}
	}
	
	return aliases;
}

@end


