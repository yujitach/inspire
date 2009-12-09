//
//  spires_AppDelegate.h
//  spires
//
//  Created by Yuji on 08/10/13.
//  Copyright Y. Tachikawa 2008 . All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>
#import <SyncServices/SyncServices.h>
@class ArticleList;
@class ArticleView;
//@class SideTableViewController;
@class SideOutlineViewController;
@class Article;
@class HistoryController;
@class ImporterController;
@class PDFHelper;
@class BibViewController;
@class ActivityMonitorController;
@class IncrementalArrayController;
@class PrefController;
@class TeXWatcherController;
@class MessageViewerController;
@class SPSearchFieldWithProgressIndicator;
@class ArxivNewCreateSheetHelper;

#import "AppDelegate.h"

@interface spires_AppDelegate : NSObject <AppDelegate>// <NSPersistentStoreCoordinatorSyncing>
{
    IBOutlet NSWindow *window;
    IBOutlet IncrementalArrayController* ac;
    IBOutlet ArticleView*wv;
    IBOutlet NSToolbar*tb;
    IBOutlet HistoryController*historyController;
//    ImporterController*importerController;
    BibViewController *bibViewController;
    ActivityMonitorController* activityMonitorController;
    PrefController*prefController;
    TeXWatcherController*texWatcherController;
    MessageViewerController*messageViewerController;
    ArxivNewCreateSheetHelper*arxivNewCreateSheetHelper;
    int countDown;
    
  /*  NSMutableArray* arxivLists;
    NSMutableArray* articleLists;*/
//    IBOutlet NSArrayController* articleListController;
    IBOutlet NSTableView* articleListView;
    IBOutlet SideOutlineViewController* sideTableViewController;
    IBOutlet SPSearchFieldWithProgressIndicator*searchField;
    
    NSTimer*unreadTimer;
}


@end


