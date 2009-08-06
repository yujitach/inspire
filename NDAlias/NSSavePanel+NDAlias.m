/*
 *  NSSavePanel+NDAlias.m category
 *
 *  Created by Sean McBride on Sat Mar 18 2008.
 *  Copyright 2008 Nathan Day. All rights reserved.
 */

#import "NSSavePanel+NDAlias.h"

#import "NDAlias.h"

/*
 * class implementation NSSavePanel (NDAlias)
 */
@implementation NSSavePanel (NDAlias)

/*
 * -directoryAlias
 */
- (NDAlias *)directoryAlias
{
	NDAlias *			anAlias = nil;
	NSString *			directory = [self directory];
	if (directory != nil)
	{
		anAlias = [NDAlias aliasWithPath:directory];
	}
	
	return anAlias;
}

/*
 * -setDirectoryAlias:
 */
- (void)setDirectoryAlias:(NDAlias*)alias
{
	NSString* fullPath = [alias path];
	[self setDirectory:fullPath];
}

@end
