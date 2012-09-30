//
//  TableViewContextMenuCategory.h
//  spires
//
//  Created by Yuji on 08/10/18.
//  Copyright 2008 Y. Tachikawa. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol TableViewContextMenuDelegate
-(NSMenu*)tableView:(NSTableView*)tv contextMenuForColumn:(NSTableColumn*)col atRow:(NSInteger)i;
@end


@interface NSTableView (TableViewContextMenuCategory)


@end
