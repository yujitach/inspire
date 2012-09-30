//
//  SideTableViewController.h
//  spires
//
//  Created by Yuji on 08/10/25.
//  Copyright 2008 Y. Tachikawa. All rights reserved.
//

#import <Cocoa/Cocoa.h>

//@class spires_AppDelegate;
@class ArticleList;
@class AllArticleList;
@interface SideTableViewController : NSObject {
    IBOutlet NSArrayController* articleListController;
    IBOutlet NSTableView* articleListView;
//    IBOutlet spires_AppDelegate* appDelegate;
    AllArticleList*allArticleList;
    
}
-(void)rearrangePositionInViewForArticleLists;
-(ArticleList*)currentArticleList;
-(void)addArticleList:(ArticleList*)al;
-(void)removeArticleList:(ArticleList*)al;
-(void)selectAllArticleList;
-(void)selectArticleList:(ArticleList*)al;
@end
