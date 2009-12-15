//
//  SideOutlineView.m
//  spires
//
//  Created by Yuji on 09/03/18.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import "SideOutlineView.h"
#import "ArticleList.h"

#import <AppKit/NSTrackingArea.h>
#import "CellTrackingRect.h" 


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
	frame.origin.x-=[self indentationPerLevel]-3;
	frame.size.width+=[self indentationPerLevel]-3;
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

#pragma mark Tracking support
// taken from TrackableOutlineView.{m,h} in the Apple Sample code PhotoSearch

- (id)init {
    self = [super init];
    if (self) {
        iMouseRow = -1;
        iMouseCol = -1;
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        iMouseRow = -1;
        iMouseCol = -1;
    }
    return self;
}

- (void)dealloc {
    [iMouseCell release];
    [super dealloc];
}


- (void)updateTrackingAreas {
    for (NSTrackingArea *area in [self trackingAreas]) {
        // We have to uniquely identify our own tracking areas
        if (([area owner] == self) && ([[area userInfo] objectForKey:@"Row"] != nil)) {
            [self removeTrackingArea:area];
        }
    }
    
    // Find the visible cells that have a non-empty tracking rect and add rects for each of them
    NSRange visibleRows = [self rowsInRect:[self visibleRect]];
    NSIndexSet *visibleColIndexes = [self columnIndexesInRect:[self visibleRect]];
    
    NSPoint mouseLocation = [self convertPoint:[[self window] convertScreenToBase:[NSEvent mouseLocation]] fromView:nil];
    
    for (NSInteger row = visibleRows.location; row < visibleRows.location + visibleRows.length; row++ ) {
        // If it is a "full width" cell, we don't have to go through the rows
        NSCell *fullWidthCell = [self preparedCellAtColumn:-1 row:row];
        if (fullWidthCell) {
            if ([fullWidthCell respondsToSelector:@selector(addTrackingAreasForView:inRect:withUserInfo:mouseLocation:)]) {
                NSInteger col = -1;
                NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInteger:col], @"Col", [NSNumber numberWithInteger:row], @"Row", nil];
                [fullWidthCell addTrackingAreasForView:self inRect:[self frameOfCellAtColumn:col row:row] withUserInfo:userInfo mouseLocation:mouseLocation];
            }
        } else {
            for (NSInteger col = [visibleColIndexes firstIndex]; col != NSNotFound; col = [visibleColIndexes indexGreaterThanIndex:col]) {
                NSCell *cell = [self preparedCellAtColumn:col row:row];
                if ([cell respondsToSelector:@selector(addTrackingAreasForView:inRect:withUserInfo:mouseLocation:)]) {
                    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInteger:col], @"Col", [NSNumber numberWithInteger:row], @"Row", nil];
                    [cell addTrackingAreasForView:self inRect:[self frameOfCellAtColumn:col row:row] withUserInfo:userInfo mouseLocation:mouseLocation];
                }
            }
        }
    }
}

- (void)mouseEntered:(NSEvent *)event {
    if([event type]==NSLeftMouseDown){
	[self mouseDown:event];
    }
    // Delegate this to the appropriate cell. In order to allow the cell to maintain state, we copy it and use the copy until the mouse is moved outside of the cell.
    NSDictionary *userInfo = [event userData];
    NSNumber *row = [userInfo valueForKey:@"Row"];
    NSNumber *col = [userInfo valueForKey:@"Col"];
    if (row && col) {
        NSInteger rowVal = [row integerValue]; 
        NSInteger colVal = [col integerValue];
        NSCell *cell = [self preparedCellAtColumn:colVal row:rowVal];
        // Only set the mouseCell properties AFTER calling preparedCellAtColumn:row:.
        if (iMouseCell != cell) {
            [iMouseCell release];
            // Store off the col/row
            iMouseCol = colVal;
            iMouseRow = rowVal;
            // Store a COPY of the cell for use when tracking in an area
            iMouseCell = [cell copy];
            [iMouseCell setControlView:self];
            [iMouseCell mouseEntered:event];
        }
    }
}

- (void)mouseExited:(NSEvent *)event {
    NSDictionary *userInfo = [event userData];
    NSNumber *row = [userInfo valueForKey:@"Row"];
    NSNumber *col = [userInfo valueForKey:@"Col"];
    if (row && col) {
        NSCell *cell = [self preparedCellAtColumn:[col integerValue] row:[row integerValue]];
        [cell setControlView:self];
        [cell mouseExited:event];
        // We are now done with the copied cell
        [iMouseCell release];
        iMouseCell = nil;
        iMouseCol = -1;
        iMouseRow = -1;
    }
}

/* Since NSTableView/NSOutineView uses the same cell to "stamp" out each row, we need to send the mouseEntered/mouseExited events each time it is drawn. The easy hook for this is the preparedCell method. 
 */
- (NSCell *)preparedCellAtColumn:(NSInteger)column row:(NSInteger)row {
    // We check if the selectedCell is nil or not -- the selectedCell is a cell that is currently being edited or tracked. We don't want to return our override if we are in that state.
    if ([self selectedCell] == nil && (row == iMouseRow) && (column == iMouseCol)) {
        return iMouseCell;
    } else {
        return [super preparedCellAtColumn:column row:row];
    }
}

/* In order for the cell to properly update itself with an "updateCell:" call, we must handle the "mouseCell" as a special case
 */
- (void)updateCell:(NSCell *)aCell {
    if (aCell == iMouseCell) {
        [self setNeedsDisplayInRect:[self frameOfCellAtColumn:iMouseCol row:iMouseRow]];
    } else {
        [super updateCell:aCell];
    }
}


@end
