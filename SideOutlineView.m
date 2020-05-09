//
//  SideOutlineView.m
//  spires
//
//  Created by Yuji on 09/03/18.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import "SideOutlineView.h"
#import "ArticleList.h"
#import "ArticleFolder.h"
#import "AppDelegate.h"
#import "SideOutlineViewController.h"
#import <AppKit/NSTrackingArea.h>
#import "TableViewContextMenuCategory.h"

@implementation SideOutlineView

// partly taken from http://www.cocoabuilder.com/archive/message/cocoa/2009/1/8/227041

#define kMaxFirstLevelIndentation 16
#define kMinFirstLevelIndentation 10

-(NSMenu*)menuForEvent:(NSEvent *)event
{
    return [self menuForEvent_TableViewContextMenuCategory:event];
}


-(CGFloat)indentationPerLevel
{
    return 10;
}
- (NSRect)frameOfCellAtColumn:(NSInteger)column row:(NSInteger)row
{
    NSRect frame = [super frameOfCellAtColumn:column row:row];
    NSRect dummy = [super frameOfCellAtColumn:column row:0];
    NSInteger level=[self levelForRow:row];
    frame.origin.x=dummy.origin.x+level*[self indentationPerLevel];
    frame.size.width=dummy.size.width-level*[self indentationPerLevel];
//    NSLog(@"level:%d row:%d rect:%@",(int)[self levelForRow:row],(int)row,NSStringFromRect(frame));
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
    if ( [self tableColumns][column] == [self outlineTableColumn] ) {
	
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
    NSRect dummy = [self frameOfCellAtColumn:0 row:row];
    frame.origin.x=dummy.origin.x-12;
    
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


-(void)keyDown:(NSEvent*)ev
{
    if([ev keyCode]==0x7c){ // right key
        SideOutlineViewController*soc=(SideOutlineViewController*)[self delegate];
        if([soc currentArticleList].children.count>0){
            [super keyDown:ev];
        }else{
            [[NSApp appDelegate] makeTableViewFirstResponder];
        }
    }else{
        [super keyDown:ev];
    }
}

@end
