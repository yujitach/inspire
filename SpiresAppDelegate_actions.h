//
//  spires_AppDelegate_actions.h
//  spires
//
//  Created by Yuji on 12/8/09.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SpiresAppDelegate.h"
@interface SpiresAppDelegate (actions)

-(IBAction)sendBugReport:(id)sender;
-(IBAction)dumpBibtexFile:(id)sender;
-(IBAction)installSafariExtension:(id)sender;
-(IBAction)saveAction:(id)sender;
-(IBAction)search:(id)sender;
-(IBAction)reloadSelection:(id)sender;
-(IBAction)reloadSelectedArticleList:(id)sender;
-(IBAction)reloadAllArticleList:(id)sender;
-(IBAction)addArticleList:(id)sender;
-(IBAction)addArticleFolder:(id)sender;
-(IBAction)addArxivArticleList:(id)sender;
-(IBAction)addCannedSearch:(id)sender;
//-(IBAction)importSpiresXML:(id)sender;
-(IBAction)getBibEntries:(id)sender;
-(IBAction)getBibEntriesWithoutDisplay:(id)sender;
-(IBAction)copyBibKeyToPasteboard:(id)sender;
-(IBAction)openSelectionInQuickLook:(id)sender;
-(IBAction)openSelectionInPDFViewer:(id)sender;
-(IBAction)openSelectionInSecondaryPDFViewer:(id)sender;
-(IBAction)showReleaseNotes:(id)sender;
-(IBAction)showAcknowledgments:(id)sender;
-(IBAction)showhideActivityMonitor:(id)sender;
-(IBAction)showPreferences:(id)sender;
-(IBAction)showTeXWatcher:(id)sender;
-(IBAction)openHomePage:(id)sender;
-(IBAction)zoomIn:(id)sender;
-(IBAction)zoomOut:(id)sender;
-(IBAction)progressQuit:(id)sender;
-(IBAction)fixDataInconsistency:(id)sender;
//-(IBAction)regenerateMainList:(id)sender;
-(IBAction)openPDF:(id)sender;
-(IBAction)openJournal:(id)sender;
-(IBAction)openPDForJournal:(id)sender;
-(IBAction)dumpDebugInfo:(id)sender;
-(IBAction)deleteArticleList:(id)sender;
-(IBAction)deleteEntry:(id)sender;
-(IBAction)deletePDFForEntry:(id)sender;
-(IBAction)toggleFlagged:(id)sender;
-(IBAction)saveAction:(id)sender;
-(IBAction)reloadFromSPIRES:(id)sender;

@end
