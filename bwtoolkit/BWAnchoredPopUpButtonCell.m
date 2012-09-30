//
//  BWAnchoredPopUpButtonCell.m
//  BWToolkit
//
//  Created by Brandon Walkin (www.brandonwalkin.com)
//  All code is provided under the New BSD license.
//

#import "BWAnchoredPopUpButtonCell.h"
#import "BWAnchoredPopUpButton.h"
#import "BWAnchoredButtonBar.h"
#import "NSColor+BWAdditions.h"
#import "NSImage+BWAdditions.h"

static NSColor *fillStop1, *fillStop2, *fillStop3, *fillStop4;
static NSColor *topBorderColor, *bottomBorderColor, *sideBorderColor, *sideInsetColor, *pressedColor;
static NSColor *enabledTextColor, *disabledTextColor, *enabledImageColor, *disabledImageColor;
static NSColor *borderedSideBorderColor, *borderedTopBorderColor;
static NSGradient *fillGradient;
static NSImage *pullDownArrow;
static NSShadow *contentShadow;
static CGFloat arrowInset = 11.0f;

@interface NSCell (BWAPUBCPrivate)
- (NSDictionary *)_textAttributes;
@end

@interface BWAnchoredPopUpButtonCell (BWAPUBCPrivate)
- (NSColor *)textColor;
- (NSColor *)imageColor;
- (NSRect)highlightRectForBounds:(NSRect)cellFrame;
- (void)drawArrowInFrame:(NSRect)cellFrame;
@end

@implementation BWAnchoredPopUpButtonCell

+ (void)initialize;
{
    fillStop1				= [NSColor colorWithCalibratedWhite:(253.0f / 255.0f) alpha:1];
    fillStop2				= [NSColor colorWithCalibratedWhite:(242.0f / 255.0f) alpha:1];
    fillStop3				= [NSColor colorWithCalibratedWhite:(230.0f / 255.0f) alpha:1];
	fillStop4				= [NSColor colorWithCalibratedWhite:(230.0f / 255.0f) alpha:1];
	
    fillGradient			= [[NSGradient alloc] initWithColorsAndLocations:
							   fillStop1, (CGFloat)0.0,
							   fillStop2, (CGFloat)0.45454,
							   fillStop3, (CGFloat)0.45454,
							   fillStop4, (CGFloat)1.0,
							   nil];
	
	topBorderColor			= [NSColor colorWithCalibratedWhite:(202.0f / 255.0f) alpha:1];
	bottomBorderColor		= [NSColor colorWithCalibratedWhite:(170.0f / 255.0f) alpha:1];
	sideBorderColor			= [NSColor colorWithCalibratedWhite:(0.0f / 255.0f) alpha:0.2f];
	sideInsetColor			= [NSColor colorWithCalibratedWhite:(255.0f / 255.0f) alpha:0.5f];
	
	pressedColor			= [NSColor colorWithCalibratedWhite:(0.0f / 255.0f) alpha:0.35f];
	
	enabledTextColor	= [NSColor colorWithCalibratedWhite:(10.0f / 255.0f) alpha:1];
	disabledTextColor	= [enabledTextColor colorWithAlphaComponent:0.6f];
	
	enabledImageColor	= [NSColor colorWithCalibratedWhite:(72.0f / 255.0f) alpha:1];
	disabledImageColor	= [enabledImageColor colorWithAlphaComponent:0.6f];
	
	borderedSideBorderColor	= [NSColor colorWithCalibratedWhite:(0.0f / 255.0f) alpha:0.25f];
	borderedTopBorderColor	= [NSColor colorWithCalibratedWhite:(190.0f / 255.0f) alpha:1];
	
	contentShadow = [[NSShadow alloc] init];
	[contentShadow setShadowOffset:NSMakeSize(0,-1)];
	[contentShadow setShadowColor:[NSColor colorWithCalibratedWhite:(255.0f / 255.0f) alpha:0.75f]];

	NSBundle *bundle = [NSBundle bundleForClass:[BWAnchoredPopUpButtonCell class]];		
	pullDownArrow = [[NSImage alloc] initWithContentsOfFile:[bundle pathForImageResource:@"ButtonBarPullDownArrow.pdf"]];
}

- (NSControlSize)controlSize
{
	return NSSmallControlSize;
}

- (void)setControlSize:(NSControlSize)size
{
	
}

#pragma mark Draw Bezel & Arrows

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	[super drawWithFrame:cellFrame inView:controlView];

	if ([self isHighlighted])
	{
		[pressedColor set];
		NSRectFillUsingOperation([self highlightRectForBounds:cellFrame], NSCompositeSourceOver);
	}
}

- (NSRect)highlightRectForBounds:(NSRect)bounds
{
	return bounds;
}

- (void)drawBorderAndBackgroundWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	BOOL inBorderedBar = YES;
	
	if ([[[self controlView] superview] respondsToSelector:@selector(isAtBottom)])
	{
		if ([(BWAnchoredButtonBar *)[[self controlView] superview] isAtBottom])
			inBorderedBar = NO;			
	}
	
	[fillGradient drawInRect:cellFrame angle:90];
	
	[bottomBorderColor bwDrawPixelThickLineAtPosition:0 withInset:0 inRect:cellFrame inView:[self controlView] horizontal:YES flip:YES];
	[sideInsetColor bwDrawPixelThickLineAtPosition:1 withInset:1 inRect:cellFrame inView:[self controlView] horizontal:NO flip:NO];
	[sideInsetColor bwDrawPixelThickLineAtPosition:1 withInset:1 inRect:cellFrame inView:[self controlView] horizontal:NO flip:YES];
	
	if (inBorderedBar)
	{
		[borderedTopBorderColor bwDrawPixelThickLineAtPosition:0 withInset:0 inRect:cellFrame inView:[self controlView] horizontal:YES flip:NO];
		[borderedSideBorderColor bwDrawPixelThickLineAtPosition:0 withInset:1 inRect:cellFrame inView:[self controlView] horizontal:NO flip:NO];
		[borderedSideBorderColor bwDrawPixelThickLineAtPosition:0 withInset:1 inRect:cellFrame inView:[self controlView] horizontal:NO flip:YES];
	}
	else
	{
		[topBorderColor bwDrawPixelThickLineAtPosition:0 withInset:0 inRect:cellFrame inView:[self controlView] horizontal:YES flip:NO];
		[sideBorderColor bwDrawPixelThickLineAtPosition:0 withInset:1 inRect:cellFrame inView:[self controlView] horizontal:NO flip:NO];
		[sideBorderColor bwDrawPixelThickLineAtPosition:0 withInset:1 inRect:cellFrame inView:[self controlView] horizontal:NO flip:YES];
	}

	if (inBorderedBar && [[self controlView] respondsToSelector:@selector(isAtLeftEdgeOfBar)])
	{
		if ([(BWAnchoredPopUpButton *)[self controlView] isAtLeftEdgeOfBar])
			[bottomBorderColor bwDrawPixelThickLineAtPosition:0 withInset:1 inRect:cellFrame inView:[self controlView] horizontal:NO flip:NO];
		if ([(BWAnchoredPopUpButton *)[self controlView] isAtRightEdgeOfBar])
			[bottomBorderColor bwDrawPixelThickLineAtPosition:0 withInset:1 inRect:cellFrame inView:[self controlView] horizontal:NO flip:YES];
	}
	
	[self drawArrowInFrame:cellFrame];
}

- (void)drawArrowInFrame:(NSRect)cellFrame
{
	NSPoint drawPoint;
	drawPoint.x = NSMaxX(cellFrame) - arrowInset;
	
	NSImage *arrow = [pullDownArrow bwTintedImageWithColor:[self imageColor]];
	
	NSAffineTransform* transform = [NSAffineTransform transform];
	[transform translateXBy:0.0f yBy:cellFrame.size.height];
	[transform scaleXBy:1.0f yBy:-1.0f];
	[transform concat];
	
	[contentShadow set];
	
	if ([self pullsDown])
	{
		// Draw pull-down arrow
		drawPoint.y = (CGFloat)round(cellFrame.size.height / 2) - 2;
		[arrow drawAtPoint:drawPoint fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0f];
	}
	else
	{
		// Draw bottom pop-up arrow
		drawPoint.y = (CGFloat)round(cellFrame.size.height / 2) - 4;
		[arrow drawAtPoint:drawPoint fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0f];
		
		// Draw top pop-up arrow
		drawPoint.y -= 1;
		
		NSAffineTransform* transform2 = [NSAffineTransform transform];
		[transform2 translateXBy:0.0f yBy:cellFrame.size.height];
		[transform2 scaleXBy:1.0f yBy:-1.0f];
		[transform2 concat];
		
		[arrow drawAtPoint:drawPoint fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0f];
		
		[transform2 invert];
		[transform2 concat];
	}

	[transform invert];
	[transform concat];	
}

#pragma mark Draw Title

- (NSColor *)textColor
{
	return [self isEnabled] ? enabledTextColor : disabledTextColor;
}

- (NSDictionary *)_textAttributes
{
	NSMutableDictionary *attributes = [[NSMutableDictionary alloc] init];
	[attributes addEntriesFromDictionary:[super _textAttributes]];
	[attributes setObject:[self textColor] forKey:NSForegroundColorAttributeName];
	[attributes setObject:[NSFont systemFontOfSize:11] forKey:NSFontAttributeName];
	[attributes setObject:contentShadow forKey:NSShadowAttributeName];
	
	return attributes;
}

- (NSRect)titleRectForBounds:(NSRect)bounds
{
	NSRect titleRect = [super titleRectForBounds:bounds];
	
	titleRect.origin.y -= 1;
	titleRect = NSInsetRect(titleRect, 3, 0);
	
	return titleRect;
}

#pragma mark Draw Image

- (NSColor *)imageColor
{
	return [self isEnabled] ? enabledImageColor : disabledImageColor;
}

- (NSRect)imageRectForBounds:(NSRect)theRect
{
	NSRect imageRect = [super imageRectForBounds:theRect];
	
	if (imageRect.size.width < [self image].size.width)
		imageRect.size.width += 1;
	
	imageRect.origin.x += 1;
	
	return imageRect;
}

- (void)drawImageWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{	
	NSImage *image = [self image];
	
	if (image != nil)
	{
		if ([[image name] isEqualToString:@"NSActionTemplate"])
			[image setSize:NSMakeSize(10,10)];
		
		NSImage *newImage = image;
		
		if ([image isTemplate])
			newImage = [image bwTintedImageWithColor:[self imageColor]];

		NSAffineTransform* transform = [NSAffineTransform transform];
		[transform translateXBy:0.0f yBy:cellFrame.size.height];
		[transform scaleXBy:1.0f yBy:-1.0f];
		[transform concat];
		
		[newImage drawInRect:[self imageRectForBounds:cellFrame] fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1];

		[transform invert];
		[transform concat];
	}	
}

@end
