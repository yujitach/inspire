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

@interface spires_AppDelegate : NSObject <AppDelegate> // <NSPersistentStoreCoordinatorSyncing>
{
    IBOutlet NSWindow *window;
    IBOutlet BibViewController *bibViewController;
    IBOutlet IncrementalArrayController* ac;
    IBOutlet ArticleView*wv;
    IBOutlet NSToolbar*tb;
    IBOutlet HistoryController*historyController;
    ImporterController*importerController;
    ActivityMonitorController* activityMonitorController;
    PrefController*prefController;
    TeXWatcherController*texWatcherController;
    MessageViewerController*messageViewerController;
    ArxivNewCreateSheetHelper*arxivNewCreateSheetHelper;
    int countDown;
    
  /*  NSMutableArray* arxivLists;
    NSMutableArray* articleLists;*/
//    IBOutlet NSArrayController* articleListController;
 //   IBOutlet NSTableView* articleListView;
    IBOutlet SideOutlineViewController* sideTableViewController;
    IBOutlet SPSearchFieldWithProgressIndicator*searchField;
    
    NSTimer*unreadTimer;
/*    NSPersistentStoreCoordinator *persistentStoreCoordinator;
    NSManagedObjectModel *managedObjectModel;
    NSManagedObjectContext *managedObjectContext;
 */   
}

//- (NSPersistentStoreCoordinator *)persistentStoreCoordinator;
//- (NSManagedObjectModel *)managedObjectModel;
- (NSManagedObjectContext *)managedObjectContext;
//- (NSString *)applicationSupportFolder;
//- (NSString *)dataFilePath;

-(void)sendBugReport:(id)sender;
- (IBAction)saveAction:sender;
- (IBAction)search:sender;
//-(IBAction)installHook:(id)sender;
-(IBAction)reloadSelection:(id)sender;
-(IBAction)reloadSelectedArticleList:(id)sender;
-(IBAction)reloadAllArticleList:(id)sender;
-(IBAction)addArticleList:(id)sender;
-(IBAction)addArticleFolder:(id)sender;
-(IBAction)addArxivArticleList:(id)sender;
-(void)addArxivArticleListWithName:(NSString*)name;
-(IBAction)addCannedSearch:(id)sender;
-(IBAction)importSpiresXML:(id)sender;
-(IBAction)getBibEntries:(id)sender;
-(IBAction)getBibEntriesWithoutDisplay:(id)sender;
-(IBAction)copyBibKeyToPasteboard:(id)sender;
-(IBAction)openSelectionInQuickLook:(id)sender;
-(IBAction)openSelectionInPDFViewer:(id)sender;
-(IBAction)openSelectionInSecondaryPDFViewer:(id)sender;
-(IBAction)showReleaseNotes:(id)sender;
-(IBAction)showAcknowledgments:(id)sender;
-(IBAction)showUsage:(id)sender;
-(IBAction)showhideActivityMonitor:(id)sender;
-(IBAction)showPreferences:(id)sender;
-(IBAction)showTeXWatcher:(id)sender;
-(IBAction)openHomePage:(id)sender;
-(IBAction)zoomIn:(id)sender;
-(IBAction)zoomOut:(id)sender;
-(IBAction)turnOnOffLine:(id)sender;
-(IBAction)progressQuit:(id)sender;
-(IBAction)fixDataInconsistency:(id)sender;
@end
