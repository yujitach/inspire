/*!
	@header NSPathControl+NDAlias.h
	@abstract Decalres the category <tt>NSPathControl (NDAlias)</tt>
	@discussion Thanks to Sean McBride for providing this 
	@date Thursday August 16 2007
	@author Sean McBride
	@copyright &#169; 2007 Nathan Day. All rights reserved.
 */

#import <Cocoa/Cocoa.h>
#import "NDSDKCompatibility.h"

@class NDAlias;

/*!
	@category NSPathControl(NDAlias)
	@abstract Additional meethods of <tt>NSPathControl</tt> to deal with <tt>NDAlias</tt> instances.
	@discussion Adds three methods to <tt>NSPathControl</tt>
	@author Sean McBride
	@date Saturday, 16 August 2007
 */
@interface NSPathControl (NDAlias)

/*!
	@method path
	@abstract Returns the path value displayed by the receiver.
	@discussion <tt>path</tt> is equivelent to <tt>-[NSPathControl URL]</tt> but returning a POSIX path <tt>NSString</tt>
	@author Sean McBride
	@date Saturday, 16 August 2007
	@result A POSIX path.
 */
- (NSString*)path;

/*!
	@method alias
	@abstract Returns the path value displayed by the receiver as an alias.
	@discussion <tt>alias</tt> is equivelent to <tt>-[NSPathControl URL]</tt> but returning a <tt>NDAlias</tt>
	@author Sean McBride
	@date Saturday, 16 August 2007
	@result A <tt>NDAlias</tt>.
 */
- (NDAlias*)alias;

/*!
	@method setAlias:
	@abstract Sets the path value displayed by the receiver.
	@discussion <#discussion#>
	@author Sean McBride
	@date Saturday, 16 August 2007
	@param alias <#result#>
 */
- (void)setAlias:(NDAlias*)alias;

@end
