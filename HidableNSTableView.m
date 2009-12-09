//
//  HidableNSTableView.m
//  spires
//
//  Created by Yuji on 08/10/14.
//  Copyright 2008 Y. Tachikawa. All rights reserved.
//

#import "HidableNSTableView.h"
#import "spires_AppDelegate_actions.h"

// taken from http://www.fernlightning.com/doku.php?id=randd:dyntablecolumns
@interface HidableNSTableView ()
- (void)saveTableColumns:(NSNotification*)n;
- (void)contextMenuSelected:(id)sender;
@end
@implementation HidableNSTableView
-(void)awakeFromNib
{
    saveName=[self autosaveName];
    [self setAutosaveName:nil];
    NSArray *cols = [[NSUserDefaults standardUserDefaults] arrayForKey:saveName];
    tableHeaderContextMenu = [[NSMenu alloc] initWithTitle:@""];
    [[self headerView] setMenu:tableHeaderContextMenu];
    tableColumns = [NSArray arrayWithArray:[self tableColumns]]; // clone array so compiles/runs on 10.5
    NSEnumerator *enumerator = [tableColumns objectEnumerator];
    NSTableColumn *column;
    while((column = [enumerator nextObject])) {
	NSString *title = [[column headerCell] title];
	NSMenuItem *item = [tableHeaderContextMenu addItemWithTitle:title action:@selector(contextMenuSelected:) keyEquivalent:@""];
	[item setTarget:self];
	[item setRepresentedObject:column];
	[item setState:cols?NSOffState:NSOnState];
	if(cols) [self removeTableColumn:column]; // initially want to show all columns
    }
    // add columns in correct order with correct width, ensure menu items are in correct state
    enumerator = [cols objectEnumerator];
    NSDictionary *colinfo;
    while((colinfo = [enumerator nextObject])) {
	NSMenuItem *item = [tableHeaderContextMenu itemWithTitle:[colinfo objectForKey:@"title"]];
	if(!item) continue; // missing title
	[item setState:NSOnState];
	column = [item representedObject];
	[column setWidth:[[colinfo objectForKey:@"width"] floatValue]];
	[self addTableColumn:column];
    }
    [self sizeLastColumnToFit];
    // listen for changes so know when to save
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(saveTableColumns:) name:NSTableViewColumnDidMoveNotification object:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(saveTableColumns:) name:NSTableViewColumnDidResizeNotification object:self];
}

- (void)saveTableColumns:(NSNotification*)n {
    if([n object]!=self)return;
    NSMutableArray *cols = [NSMutableArray array];
    NSEnumerator *enumerator = [[self tableColumns] objectEnumerator];
    NSTableColumn *column;
    while((column = [enumerator nextObject])) {
	[cols addObject:[NSDictionary dictionaryWithObjectsAndKeys:
			 [[column headerCell] title], @"title",
			 [NSNumber numberWithFloat:[column width]], @"width",
			 nil]];
    }
    [[NSUserDefaults standardUserDefaults] setObject:cols forKey:saveName];
}
- (void)contextMenuSelected:(id)sender {
    BOOL on = ([sender state] == NSOnState);
    [sender setState:(on ? NSOffState : NSOnState)];
    NSTableColumn *column = [sender representedObject];
    if(on) {		
	[self removeTableColumn:column];
	[self sizeLastColumnToFit];
    } else {
	[self addTableColumn:column];
	    [self sizeToFit];
    }
    [self setNeedsDisplay:YES];
    [self saveTableColumns:nil];
}

-(void)keyDown:(NSEvent*)ev
{
//    NSLog(@"%x",[ev keyCode]);
    if([[ev characters] isEqualToString:@" "]){
	[NSApp sendAction:@selector(openSelectionInQuickLook:) to:nil from:self];
    }else if([ev keyCode]==0x24|| [ev keyCode]==76){ // if return or enter
	[NSApp sendAction:@selector(openPDF:) to:nil from:self];
    }else{
	[super keyDown:ev];
    }
}


// added Apr 16 2009
-(void)showColumnWithTitle:(NSString*)title
{
    NSMenuItem *item = [tableHeaderContextMenu itemWithTitle:title];
    if([item state]==NSOnState)return;
    [item setState:NSOnState];
    NSTableColumn*column=[item representedObject];
    NSArray*a=[NSArray arrayWithArray:[self tableColumns]];
    for(NSTableColumn*c in a){
	[self removeTableColumn:c];
    }
    [self addTableColumn:column];
    for(NSTableColumn*c in a){
	[self addTableColumn:c];
    }    
    //    [self sizeToFit];
    [self setNeedsDisplay:YES];
    [self saveTableColumns:nil];
}

@end
