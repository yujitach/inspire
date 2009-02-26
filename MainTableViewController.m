//
//  MainTableViewController.m
//  spires
//
//  Created by Yuji on 09/02/01.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import "MainTableViewController.h"
#import "Article.h"
NSString *ArticleDropPboardType=@"articleDropType";


@implementation MainTableViewController
-(void)awakeFromNib
{
    [tv setDoubleAction:@selector(openPDF:)];
    [tv setTarget:nil];
    [tv setDraggingSourceOperationMask:NSDragOperationCopy forLocal:NO];
}
#pragma mark Table View Delegates
- (BOOL)tableView:(NSTableView *)aTableView acceptDrop:(id < NSDraggingInfo >)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)operation
{
    return NO;
}
- (NSDragOperation)tableView:(NSTableView*)tvv validateDrop:(id <NSDraggingInfo>)info proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)operation
{
    //    if(tvv==tv)
    return NSDragOperationNone;
}
- (BOOL)tableView:(NSTableView *)aTableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pboard
{
    if(aTableView!=tv){
	return NO;
    }
    NSArray* a=[[ac arrangedObjects] objectsAtIndexes:rowIndexes];
    NSMutableArray* b=[NSMutableArray array];
    for(Article*i in a){
	[b addObject:[[i objectID] URIRepresentation]];
    }
    [pboard declareTypes:[NSArray arrayWithObjects:NSStringPboardType,ArticleDropPboardType,nil] owner:nil];
    [pboard setData:[NSKeyedArchiver archivedDataWithRootObject:b] forType:ArticleDropPboardType];
    NSMutableString* s=[NSMutableString string];
    for(Article* i in a){
	[s appendString:i.preferredId];
	[s appendString:@"\n"];
    }
    [pboard setString:[s substringToIndex:[s length]-1]
	      forType:NSStringPboardType];
    return YES;
}
- (BOOL)tableView:(NSTableView *)aTableView shouldEditTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    return NO;
}
-(NSMenu*)tableView:(NSTableView*)tvv contextMenuForColumn:(NSTableColumn*)col atRow:(int)i;
{
    //    NSLog(@"context menu for %@:%d",col,i);
    //	[tvv selectRow:i byExtendingSelection:NO];
    NSMenu* menu=[[NSMenu alloc] initWithTitle:@"context menu"];
    [menu insertItemWithTitle:@"Reload data from spires" 
		       action:@selector(reloadFromSPIRES:)
		keyEquivalent:@""
		      atIndex:0];	
    [menu insertItemWithTitle:@"QuickLook" 
		       action:@selector(openSelectionInQuickLook:)
		keyEquivalent:@""
		      atIndex:1];	
    [menu insertItemWithTitle:@"Show bib" 
		       action:@selector(getBibEntries:)
		keyEquivalent:@""
		      atIndex:2];	
    [menu insertItemWithTitle:@"Delete" 
		       action:@selector(deleteEntry:)
		keyEquivalent:@""
		      atIndex:3];	
    [menu insertItemWithTitle:@"Dump debug info" 
		       action:@selector(dumpDebugInfo:)
		keyEquivalent:@""
		      atIndex:4];	
    return menu;
}
@end
