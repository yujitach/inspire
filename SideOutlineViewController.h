//
//  SideTableViewController.h
//  spires
//
//  Created by Yuji on 08/10/25.
//  Copyright 2008 Y. Tachikawa. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TableViewContextMenuCategory.h"

//@class spires_AppDelegate;
@class ArticleList;
@interface SideOutlineViewController : NSViewController<TableViewContextMenuDelegate> {
    IBOutlet NSTreeController* articleListController;
    IBOutlet NSOutlineView* articleListView;
//    IBOutlet spires_AppDelegate* appDelegate;
    
}
-(ArticleList*)currentArticleList;
-(void)addArticleList:(ArticleList*)al;
//-(void)removeArticleList:(ArticleList*)al;
-(void)removeCurrentArticleList;
-(void)selectAllArticleList;
-(void)loadArticleLists;
-(void)selectArticleList:(ArticleList*)al;
-(void)detachFromMOC;
-(void)attachToMOC;
@end
