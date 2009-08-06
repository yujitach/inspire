/*!
	@header NSOpenPanel+NDAlias
	@abstract Decalres the category <tt>NSOpenPanel (NDAlias)</tt>
	@discussion Thanks to Sean McBride for providing this 
	@date Thursday August 16 2007
	@author Sean McBride
	@copyright &#169; 2008 Nathan Day. All rights reserved.
 */

#import <Cocoa/Cocoa.h>
#import "NDSDKCompatibility.h"

/*!
	@category NSOpenPanel(NDAlias)
	@abstract Additional methods of <tt>NSOpenPanel</tt> to deal with <tt>NDAlias</tt> instances.
	@discussion Adds the single method <tt>aliases</tt>
 */
@interface NSOpenPanel (NDAlias)

/*!
	@method aliases
	@abstract Returns an array containing aliases to the selected files and directories.
	@discussion If multiple selections aren’t allowed, the array contains a single alias. The <tt>aliases</tt> works in a similiar way to -[NSOpenPanel filenames].
	@result <tt>NSArray</tt> of <tt>NDAlias<//t>
  */
- (NSArray *)aliases;

@end
