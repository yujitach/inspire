/*!
	@header NSSavePanel+NDAlias
	@abstract Decalres the category <tt>NSSavePanel (NDAlias)</tt>
	@discussion Thanks to Sean McBride for providing this 
	@date Thursday March 18 2008
	@author Sean McBride
	@copyright &#169; 2008 Nathan Day. All rights reserved.
 */

#import <Cocoa/Cocoa.h>
#import "NDSDKCompatibility.h"

@class NDAlias;

/*!
	@category NSSavePanel(NDAlias)
	@abstract Additional methods of <tt>NSSavePanel</tt> to deal with <tt>NDAlias</tt> instances.
	@discussion Adds the single method <tt>directoryAlias</tt>
 */
@interface NSSavePanel (NDAlias)

/*!
	@method directoryAlias
	@abstract Returns an NDAlias of the directory currently shown in the receiver.
	@discussion Works in a similiar way to -[NSSavePanel directory].
	@result <tt>NDAlias<//t>
  */
- (NDAlias *)directoryAlias;

/*!
	@method setDirectoryAlias
	@abstract Sets the current directory currently shown in the receiver to the alias given.
	@discussion Works in a similiar way to -[NSSavePanel setDirectory].
	@result
  */
- (void)setDirectoryAlias:(NDAlias*)alias;

@end
