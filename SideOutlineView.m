//
//  SideOutlineView.m
//  spires
//
//  Created by Yuji on 09/03/18.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import "SideOutlineView.h"
#import "ArticleList.h"

@implementation SideOutlineView

// partly taken from http://www.cocoabuilder.com/archive/message/cocoa/2009/1/8/227041

#define kMaxFirstLevelIndentation 16
#define kMinFirstLevelIndentation 10




- (NSRect)frameOfCellAtColumn:(NSInteger)column row:(NSInteger)row
{
    NSRect frame = [super frameOfCellAtColumn:column row:row];
    BOOL hasFolder=NO;
    for(int i=0;i<[self numberOfRows];i++){
	NSTreeNode*item=[self itemAtRow:i];
	ArticleList*al=[item representedObject];
	if([al.children count]>0){
	    hasFolder=YES;
	    break;
	}
    }
    if(!hasFolder){
	frame.origin.x-=[self indentationPerLevel];
	frame.size.width+=[self indentationPerLevel];
	return frame;	
    }
    if ( [[self tableColumns] objectAtIndex:column] == [self outlineTableColumn] ) {
	
	CGFloat indent = [self indentationPerLevel];
	
	if ( indent > kMaxFirstLevelIndentation ) {
	    frame.origin.x -= (indent - kMaxFirstLevelIndentation);
	    frame.size.width += (indent - kMaxFirstLevelIndentation);
	}
	else if ( indent < kMinFirstLevelIndentation ) {
	    frame.origin.x += (kMinFirstLevelIndentation - indent);
	    frame.size.width -= (kMinFirstLevelIndentation - indent);
	}
	
    }
    return frame;
    
}
-(IBAction)selectAll:(id)sender
{
}
// corrects disclosure control icon
- (NSRect)frameOfOutlineCellAtRow:(NSInteger)row;
{    
    NSRect frame = [super frameOfOutlineCellAtRow:row];
    
    CGFloat indent = [self indentationPerLevel];
    if ( indent > kMaxFirstLevelIndentation )
	frame.origin.x -= (indent - kMaxFirstLevelIndentation);
    else if ( indent < kMinFirstLevelIndentation )
	frame.origin.x += (kMinFirstLevelIndentation - indent);
    
    return frame;
}

- (BOOL)shouldCollapseAutoExpandedItemsForDeposited:(BOOL)deposited
{
    return NO;
}

@end
