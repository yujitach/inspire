//
//  spires_AppDelegate.h
//  spires
//
//  Created by Yuji on 08/10/13.
//  Copyright Y. Tachikawa 2008 . All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>
@class ArticleView;
@class SideOutlineViewController;
@class HistoryController;
@class SPSearchFieldWithProgressIndicator;

@class BibViewController;
@class ActivityMonitorController;
@class PrefController;
@class TeXWatcherController;
@class MessageViewerController;
@class ArxivNewCreateSheetHelper;

#import "AppDelegate.h"

@interface SpiresAppDelegate : NSObject <AppDelegate,WKNavigationDelegate>
{
    IBOutlet NSWindow *window;
    IBOutlet NSToolbar*tb;
    IBOutlet SPSearchFieldWithProgressIndicator*searchField;
    IBOutlet SideOutlineViewController* sideOutlineViewController;
    IBOutlet NSArrayController* ac;
    IBOutlet NSTableView* articleListView;    
    IBOutlet NSOutlineView* sideOutlineView;
    IBOutlet HistoryController*historyController;
    
    BibViewController *bibViewController;
    ActivityMonitorController* activityMonitorController;
    PrefController*prefController;
    TeXWatcherController*texWatcherController;
    MessageViewerController*messageViewerController;
    ArxivNewCreateSheetHelper* arxivNewCreateSheetHelper;
}
@end
