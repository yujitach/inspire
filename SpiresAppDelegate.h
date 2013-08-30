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
@class PrefController;
@class TeXWatcherController;
@class MessageViewerController;
@class SPSearchFieldWithProgressIndicator;
@class ArxivNewCreateSheetHelper;

#import "AppDelegate.h"

@interface SpiresAppDelegate : NSObject <AppDelegate>// <NSPersistentStoreCoordinatorSyncing>
{
    IBOutlet NSWindow *window;
    IBOutlet NSToolbar*tb;
    IBOutlet SPSearchFieldWithProgressIndicator*searchField;

    IBOutlet SideOutlineViewController* sideOutlineViewController;
    IBOutlet NSArrayController* ac;
    IBOutlet NSTableView* articleListView;    
    IBOutlet NSOutlineView* sideOutlineView;
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
