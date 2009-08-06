/*
 *  NSPathControl+NDAlias.m category
 *
 *  Created by Sean McBride on Thu Aug 16 2007.
 *  Copyright 2007 Nathan Day. All rights reserved.
 */

#import <Cocoa/Cocoa.h>

#import "NSPathControl+NDAlias.h"
#import "NDAlias.h"

@implementation NSPathControl (NDAlias)

- (NSString*)path
{
	NSString		* path = nil;
	NSURL			* url = [self URL];
	if( url && [url isFileURL] )
	{ 
		path = [url path];
	}
	
	return path;
}

- (NDAlias*)alias
{
	NDAlias		* alias = nil;
	NSURL		* url = [self URL];
	if( url && [url isFileURL] )
	{
		alias = [NDAlias aliasWithURL:url];
	}
	
	return alias;
}

- (void)setAlias:(NDAlias*)alias
{
	NSURL* url = [alias URL];
	if( url != nil )
	{
		[self setURL:url];
	}
}

@end
