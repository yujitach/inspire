//
//  spires_AppDelegate.h
//  spires
//
//  Created by Yuji on 08/10/13.
//  Copyright Y. Tachikawa 2008 . All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class ArticleList;
@class ArticleView;
@class SideOutlineViewController;
@class Article;
@class HistoryController;
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
    IBOutlet NSToolbar*tb;
    IBOutlet SPSearchFieldWithProgressIndicator*searchField;

    IBOutlet SideOutlineViewController* sideTableViewController;
    IBOutlet IncrementalArrayController* ac;
    IBOutlet NSTableView* articleListView;    
    IBOutlet ArticleView*wv;

    
    IBOutlet HistoryController*historyController;
    //    ImporterController*importerController;
    BibViewController *bibViewController;
    ActivityMonitorController* activityMonitorController;
    PrefController*prefController;
    TeXWatcherController*texWatcherController;
    MessageViewerController*messageViewerController;
    ArxivNewCreateSheetHelper*arxivNewCreateSheetHelper;

    NSTimer*unreadTimer;
    int countDown;
    NSMutableArray*articlesAlreadyAccessedViaDOI;
}


@end

#import "spires_AppDelegate_actions.h"
@interface spires_AppDelegate (actions) <spires_AppDelegate_actions>
@end
