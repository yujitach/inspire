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
@class SideTableViewController;
@class Article;
@class HistoryController;
@class ImporterController;
@class PDFHelper;
@class BibViewController;
@class ActivityMonitorController;
@interface spires_AppDelegate : NSObject <NSPersistentStoreCoordinatorSyncing>
{
    IBOutlet NSWindow *window;
    IBOutlet NSWindow *prefWindow;
    IBOutlet BibViewController *bibViewController;
//    IBOutlet NSTextField* tf;
//    IBOutlet NSProgressIndicator* pi;
    IBOutlet NSArrayController* ac;
//    IBOutlet NSTableView*tv;
    IBOutlet ArticleView*wv;
    IBOutlet NSToolbar*tb;
//    IBOutlet NSTextField* infoTextField;
    IBOutlet HistoryController*historyController;
//    IBOutlet PDFHelper* pdfHelper;
//    IBOutlet NSButton* resizer;
//    IBOutlet NSSplitView* splitView;
    ImporterController*importerController;
    int countDown;
    ArticleList* allArticleList;
    
  /*  NSMutableArray* arxivLists;
    NSMutableArray* articleLists;*/
    IBOutlet NSArrayController* articleListController;
 //   IBOutlet NSTableView* articleListView;
    IBOutlet SideTableViewController* sideTableViewController;
    IBOutlet ActivityMonitorController* activityMonitorController;
  
    
    
    NSPersistentStoreCoordinator *persistentStoreCoordinator;
    NSManagedObjectModel *managedObjectModel;
    NSManagedObjectContext *managedObjectContext;

}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator;
- (NSManagedObjectModel *)managedObjectModel;
- (NSManagedObjectContext *)managedObjectContext;
- (NSString *)applicationSupportFolder;
- (NSString *)dataFilePath;

-(void)sendBugReport:(id)sender;
- (IBAction)saveAction:sender;
- (IBAction)search:sender;
-(IBAction)installHook:(id)sender;
-(IBAction)reloadSelection:(id)sender;
-(IBAction)reloadSelectedArticleList:(id)sender;
-(IBAction)reloadAllArticleList:(id)sender;
-(IBAction)addArticleList:(id)sender;
-(IBAction)addArxivArticleList:(id)sender;
-(IBAction)importSpiresXML:(id)sender;
-(IBAction)getBibEntries:(id)sender;
-(IBAction)getBibEntriesWithoutDisplay:(id)sender;
-(IBAction)openSelectionInQuickLook:(id)sender;
-(IBAction)openSelectionInPDFViewer:(id)sender;
-(IBAction)openSelectionInSecondaryPDFViewer:(id)sender;
-(IBAction)showReleaseNotes:(id)sender;
-(IBAction)showAcknowledgments:(id)sender;
-(IBAction)showUsage:(id)sender;
-(IBAction)openHomePage:(id)sender;
-(void)showInfoOnAssociation;
-(BOOL)currentListIsArxivReplaced;
-(void)handleURL:(NSURL*) url;
-(void)rearrangePositionInViewForArticleLists;
@end
extern NSString *ArticleDropPboardType;
extern NSString *ArticleListDropPboardType;
