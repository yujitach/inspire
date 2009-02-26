//
//  TableViewContextMenuCategory.m
//  spires
//
//  Created by Yuji on 08/10/18.
//  Copyright 2008 Y. Tachikawa. All rights reserved.
//

#import "TableViewContextMenuCategory.h"

@interface NSObject (TableViewContextMenuDelegate)
-(NSMenu*)tableView:(NSTableView*)tv contextMenuForColumn:(NSTableColumn*)col atRow:(int)i;
@end

@implementation NSTableView (TableViewContextMenuCategory)
-(NSMenu*)menuForEvent:(NSEvent*)event
{
    NSPoint mousePoint = [self convertPoint:[event locationInWindow] fromView:nil];
    int row = [self rowAtPoint:mousePoint];
    int column = [self columnAtPoint:mousePoint];
    NSTableColumn*col=nil;
    if(column!=-1){
	col=[[self tableColumns] objectAtIndex:column];
    }
    if([[self delegate] respondsToSelector:@selector(tableView:contextMenuForColumn:atRow:)]){
	return [[self delegate] tableView:self contextMenuForColumn:col atRow:row];
    }
    return nil;
}
@end
