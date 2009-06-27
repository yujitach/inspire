//
//  spires_AppDelegate.m
//  spires
//
//  Created by Yuji on 08/10/13.
//  Copyright Y. Tachikawa 2008 . All rights reserved.
//

#import "spires_AppDelegate.h"
#import "spires_AppDelegate_SyncCategory.h"
#import "MOC.h"

#import "Article.h"
#import "Author.h"
#import "JournalEntry.h"

#import "ArxivHelper.h"
#import "SpiresHelper.h"

#import "AllArticleList.h"
#import "ArxivNewArticleList.h"
#import "SimpleArticleList.h"
#import "ArticleFolder.h"
#import "CannedSearch.h"

#import "ArticleView.h"

//#import "SideTableViewController.h"
#import "SideOutlineViewController.h"

#import "HistoryController.h"

#import "NSString+XMLEntityDecoding.h"
#import "NSManagedObjectContext+TrivialAddition.h"
#import "NSURL+libraryProxy.h"
#import "ImporterController.h"
#import "IncrementalArrayController.h"
#import "ActivityMonitorController.h"
#import "PrefController.h"

#import "PDFHelper.h"
#import "BibViewController.h"
#import "ProgressIndicatorController.h"

#import "SpiresQueryOperation.h"
#import "TeXBibGenerationOperation.h"
#import "BatchBibQueryOperation.h"
#import "LoadAbstractDOIOperation.h"
#import "ArxivMetadataFetchOperation.h"
#import "ArticleListReloadOperation.h"
#import "SPSearchFieldWithProgressIndicator.h"

#import <Sparkle/SUUpdater.h>
//#import <ExceptionHandling/NSExceptionHandler.h>
//#import "QuickLookInternal.h"

#define TICK (.5)
#define GRACEMIN (3.0/TICK)
#define GRACE ([[NSUserDefaults standardUserDefaults] floatForKey:@"arXivWaitInSeconds"]/TICK)
NSString *ArticleListDropPboardType=@"articleListDropType";

@implementation spires_AppDelegate
+(void)initialize
{
    NSDictionary* defaultDict=[NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"defaults" ofType:@"plist"]];
    [[NSUserDefaults standardUserDefaults] registerDefaults: defaultDict];

}
#pragma mark NSApplication delegates
- (void)applicationWillBecomeActive:(NSNotification *)notification
{
    [window makeKeyAndOrderFront:self];
    // delay is necessary because this is also called during the spires-quicklook-ended call.
    [[PDFHelper sharedHelper] performSelector:@selector(activateQuickLookIfNecessary) withObject:nil afterDelay:0];
//    NSLog(@"%@",wv);
}
- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)app
{
    [window makeKeyAndOrderFront:self];
//    NSLog(@"%@",wv);
    return NO;
}
-(void)rearrangePositionInViewForArticleLists
{
    [sideTableViewController rearrangePositionInViewForArticleLists];
}
-(void)handlePDF:(NSString*)path
{
    NSFileManager* fm=[NSFileManager defaultManager];
    NSString* pdfDir=[[NSUserDefaults standardUserDefaults] stringForKey:@"pdfDir"];
    NSString*fileName=[path lastPathComponent];
    NSString*destination=[[NSString stringWithFormat:@"%@/%@",pdfDir,fileName] stringByExpandingTildeInPath];
    NSLog(@"moves %@ to %@",path,destination);
    NSError*error=nil;
    [fm moveItemAtPath:path toPath:destination error:&error];
    if(error){
	[[NSApplication sharedApplication] presentError:error];
    }
}
-(void)application:(NSApplication*)app openFiles:(NSArray*)array
{
//    NSLog(@"%@",array);
    for(NSString*path in array){
	if([path hasSuffix:@".pdf"]){
	    [self handlePDF:path];
	}else if([path hasSuffix:@".tex"]){
	    [[DumbOperationQueue spiresQueue] addOperation:[[TeXBibGenerationOperation alloc] initWithTeXFile:path
												       andMOC:[self managedObjectContext] byLookingUpWeb:YES]];
	}
    }
}

/* #pragma mark Coping with database format change
-(void)updateFormatForA:(NSArray*)articles
{
    [[MOC moc] disableUndo];
    [self stopUpdatingMainView:self];
    for(Article* a in articles){
	a.longishAuthorListForA=[@"; " stringByAppendingString:a.longishAuthorListForA];
	a.longishAuthorListForEA=[@"; " stringByAppendingString:a.longishAuthorListForEA];
    }
    [self startUpdatingMainView:self];
    [[MOC moc] enableUndo];
    NSError* error=nil;
    [[MOC moc] save:&error];
    if(error){
	NSLog(@"moc error: %@",error);
    }
}
-(void)updateFormatForAIfNeeded:(id)ignored
{
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"FormatOfLongishiAuthorListForAFixedApril2009"]){
	return;
    }
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"FormatOfLongishiAuthorListForAFixedApril2009"];
    
    NSEntityDescription*articleEntity=[NSEntityDescription entityForName:@"Article" inManagedObjectContext:[MOC moc]];
    NSFetchRequest*req=[[NSFetchRequest alloc]init];
    [req setEntity:articleEntity];
    NSPredicate*pred=[NSPredicate predicateWithFormat:@"not (%K beginswith %@)",@"longishAuthorListForA",@"; "];
    [req setPredicate:pred];
    NSError*error=nil;
    NSArray*a=[[MOC moc] executeFetchRequest:req error:&error];
    if([a count]>0){
	NSAlert*alert=[NSAlert alertWithMessageText:@"spires.app will update the format of the database."
				      defaultButton:@"OK" 
				    alternateButton:nil
					otherButton:nil
			  informativeTextWithFormat:@"spires.app will tweak the format of its database to make the searching efficient.\n"
		       @"This may take some time. Spinning beachball might appear, but please be patient do not quit the app."];
	[alert runModal];
	[self updateFormatForA:a];
    }
}*/
#pragma mark Crash Detection

-(NSString*)recentlyCrashed
{
    NSFileManager*fm=[NSFileManager defaultManager];
    NSString*crashDir=[@"~/Library/Logs/CrashReporter" stringByExpandingTildeInPath];
    NSArray*a=[fm directoryContentsAtPath:crashDir];
    NSDate*date=[NSDate distantPast];
    NSString*s=nil;
    for(NSString* path in a){
	if(![path hasPrefix:@"spires"])
	    continue;
	NSDictionary *fileAttributes = [fm fileAttributesAtPath:[crashDir stringByAppendingFormat:@"/%@",path] traverseLink:YES];
	NSDate* modDate=[fileAttributes objectForKey:NSFileModificationDate];
	if([modDate compare:date]==NSOrderedDescending){
	    date=modDate;
	    s=path;
	}
    }
    if(!s)
	return nil;
    if([s isEqualToString:[[NSUserDefaults standardUserDefaults] stringForKey:@"lastCrashLog"]]) return nil;
    [[NSUserDefaults standardUserDefaults] setObject:s forKey:@"lastCrashLog"];
    return [crashDir stringByAppendingFormat:@"/%@",s];
}
-(void)prepareCrashReport:(NSString*)path
{
    NSFileManager*fm=[NSFileManager defaultManager];
    [fm createDirectoryAtPath:@"/tmp/SpiresCrashReport" attributes:nil];
    [fm copyPath:path toPath:[@"/tmp/SpiresCrashReport/" stringByAppendingString:[path lastPathComponent]] handler:nil];
    system("grep spires /var/log/system.log | grep -v malloc  > /tmp/SpiresCrashReport/system.spires.log");
    system("bzip2 -dc /var/log/system.log.0.bz2 | grep spires | grep -v malloc  > /tmp/SpiresCrashReport/system.spires.0.log");
    system("rm /tmp/SpiresCrashReport/*.tar.bz2");
    NSString*line=[NSString stringWithFormat:@"cd /tmp/SpiresCrashReport; tar jcf SpiresCrashReport-%d.tar.bz2 *.log *.crash",time(NULL) ];
    system([line UTF8String]);
    system("rm /tmp/SpiresCrashReport/*.log");
    system("rm /tmp/SpiresCrashReport/*.crash");
    [[NSWorkspace sharedWorkspace] openFile:@"/tmp/SpiresCrashReport/" withApplication:@"Finder"];
}

-(IBAction)crashCheck:(id)sender
{
    static NSString*path=nil;
    path=[self recentlyCrashed];
    if(!path)
	return;
    NSAlert*alert=[NSAlert alertWithMessageText:@"Sorry, spires.app recently crashed.\nPlease help develop this app by sending me the crash report."
				  defaultButton:@"Yes" 
				alternateButton:@"No thanks"
				    otherButton:nil
		      informativeTextWithFormat:@"Clicking Yes will bring up your email program and a Finder window containing the crash log.\n"
    @"Please attach the log file to the email and send it.\n"
    @"The log will contain the name of the articles which caused the crash, etc, which you can check by unzipping the file."];
//    [alert setShowsSuppressionButton:YES];
/*    [alert beginSheetModalForWindow:window
		      modalDelegate:self
		     didEndSelector:@selector(crashAlertDidEnd:returnCode:contextInfo:)
			contextInfo:path];    */
    NSInteger returnCode=[alert runModal];
    if(returnCode==NSAlertDefaultReturn){
	[self prepareCrashReport:path];
	[self sendBugReport:self];
    }
    
}
/*- (void) crashAlertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(NSString*)path
{
    if(returnCode==NSAlertDefaultReturn){
	[self prepareCrashReport:path];
	[self sendBugReport:self];
    }
}*/

#pragma mark article list management

-(BOOL)currentListIsArxivReplaced
{
//    ArticleList* al=[[articleListController selectedObjects] objectAtIndex:0];
    ArticleList*al=[sideTableViewController currentArticleList];
    if(![al isKindOfClass:[ArxivNewArticleList class]]){
	return NO;
    }
    NSArray* a=[al.name componentsSeparatedByString:@"/"];
    if([a count]>1 && [[a objectAtIndex:1] hasPrefix:@"rep"]){
	return YES;
    }
    return NO;
}
#pragma mark UI glues
-(NSWindow*)mainWindow
{
    return window;
}
-(void)checkOSVersion
{
    SInt32 major=10,minor=5,bugFix=6;
    Gestalt(gestaltSystemVersionMajor, &major);
    Gestalt(gestaltSystemVersionMinor, &minor);
    Gestalt(gestaltSystemVersionBugFix, &bugFix);
    NSLog(@"OS version:%d.%d.%d",major,minor,bugFix);
    if(minor == 5 && bugFix<7){
	NSLog(@"OS update should be available...");
	[[NSWorkspace sharedWorkspace] launchApplication:@"Software Update"];
    }
}
-(void)awakeFromNib
{
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"UpdaterWillFollowUnstableVersions"]){
	[[SUUpdater sharedUpdater] setFeedURL:[NSURL URLWithString:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"SUFeedURL-Unstable"]]];	
    }
    activityMonitorController=[[ActivityMonitorController alloc] init];
//    NSLog(@"awake");
//    [[NSExceptionHandler defaultExceptionHandler] setDelegate:self];
//    [[NSExceptionHandler defaultExceptionHandler] setExceptionHandlingMask:NSHandleTopLevelExceptionMask|NSHandleOtherExceptionMask];
    
    
/*    if([[[NSUserDefaults standardUserDefaults] stringForKey:@"pdfDir"] isEqualToString:@"~/Desktop"]){
	[self setFolderForPDF:self];
    }*/
    
//    [resizer setHasThumb:YES];
    for(NSToolbarItem*ti in [tb items]){
	if([[ti  label] isEqualToString:@"Search Field"]){
	    NSSize s=[ti minSize];
	    s.width=1000;
	    [ti setMaxSize:s];
	}
    }
    allArticleList=[AllArticleList allArticleListInMOC:[self managedObjectContext]];

    [ac addObserver:self
	 forKeyPath:@"selection"
	    options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionInitial
	    context:nil];

    [ac addObserver:self
	 forKeyPath:@"arrangedObjects"
	    options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionInitial
	    context:nil];
    
    
    [NSTimer scheduledTimerWithTimeInterval:TICK target:self selector:@selector(timerFired:) userInfo:nil repeats:YES];
    countDown=0;
    [self checkOSVersion];
    [searchField setProgressQuitAction:@selector(progressQuit:)];
    // the following two lines are to go around a Leopard bug (?)
    // where the textfield in the toolbar sometimes doesn't receive the mouse down, which is instead thought of as initiating drag.
/*    [tb setVisible:NO];
    [self performSelector:@selector(showToolBar:) withObject:self afterDelay:.1];
 // seems to be unnecessary once mouseDownCanMoveWindow is overriden Mar/31/2009
 */
    
    if(!prefController){
	prefController=[[PrefController alloc]init];
    }
    
  
 //   [historyController performSelector:@selector(mark:) withObject:self afterDelay:1];
//    [[self managedObjectContext] processPendingChanges];
//    [[[self managedObjectContext] undoManager] disableUndoRegistration];
  //  [self disableUndo];  
}

/*-(void)showToolBar:(id)sender
{
    [tb setVisible:YES];
}*/
-(void)applicationDidFinishLaunching:(NSNotification*)notification
{
//    NSLog(@"didLaunch");
    
/*    if([self syncEnabled]){
	[self syncSetupAtStartup];
    }
*/    
    [self crashCheck:self];
//    [self updateFormatForAIfNeeded:self];
}
-(void)clearUnreadFlagOfArticle:(NSTimer*)timer
{
    Article*a=[timer userInfo];
    a.flag=AFRead;
    unreadTimer=nil;
}
-(void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if([keyPath isEqualToString:@"selection"]){
	NSArray*a=[ac selectedObjects];
	if(!a || [a count]==0){
//	    NSLog(@"no selection");
	    [wv setArticle:NSNoSelectionMarker];
	}else if([a count]>1){
	    [wv setArticle:NSMultipleValuesMarker];
	}else{
//	    NSLog(@"selection:%a",a);
	    Article*ar=[a objectAtIndex:0];
	    [wv setArticle:ar];
	    if(ar.flag==AFUnread){
		if(unreadTimer){
		    [unreadTimer invalidate];
		}
		unreadTimer=[NSTimer scheduledTimerWithTimeInterval:1
							     target:self 
							   selector:@selector(clearUnreadFlagOfArticle:) 
							   userInfo:ar 
							    repeats:NO];
		    
	    }
	}
    }else if([keyPath isEqualToString:@"arrangedObjects"]){
	int num=[[ac arrangedObjects] count];
	NSString*head=@"spires";
//	NSArray*a=[articleListController selectedObjects];
//    if(a && [a count]>0){
	ArticleList*al=[sideTableViewController currentArticleList];
	if(al){
	    head=al.name;
	}
//	}
	[window setTitle:[NSString stringWithFormat:@"%@ (%d %@)",head,num,(num==1?@"entry":@"entries")]];
    }
}

#pragma mark SPIRES XML 
-(void)querySPIRES:(NSString*)search
{
    [[DumbOperationQueue spiresQueue] addOperation:[[SpiresQueryOperation alloc] initWithQuery:search
											andMOC:[self managedObjectContext]]];
}
-(void)startUpdatingMainView:(id)sender
{
    ac.refuseFiltering=NO;
}
-(void)stopUpdatingMainView:(id)sender
{
    ac.refuseFiltering=YES;
}
-(void)clearingUp:(id)sender
{
//    [self saveAction:self];
//    [[MOC moc] refreshObject:allArticleList mergeChanges:YES];
//    citedByTarget=nil;
//    refersToTarget=nil;
    if([[ac arrangedObjects] count]>0 && [[ac selectedObjects] count]==0){
	[ac setSelectionIndex:0];
    }
    
    [ac didChangeArrangementCriteria];    
}
#pragma mark Importer
-(IBAction)importSpiresXML:(id)sender
{
    NSOpenPanel*op=[NSOpenPanel openPanel];
    [op setCanChooseFiles:YES];
    [op setCanChooseDirectories:NO];
    [op setMessage:@"Choose the SPIRES XML files to import..."];
    [op setPrompt:@"Choose"];
    [op setAllowsMultipleSelection:YES];
    int res=[op runModalForDirectory:nil file:nil types:[NSArray arrayWithObjects:@"spires_xml",nil]];
    if(res==NSOKButton){
	if(!importerController){
	    importerController=[[ImporterController alloc] init];//WithAppDelegate:self];
	}
	[importerController import:[op filenames]];
    }
    
}
#pragma mark Timers

-(void)loadAbstractUsingDOI:(Article*)a
{
    if(!a.doi || [a.doi isEqualToString:@""]) return;
    NSArray* elsevierJournals=[[NSUserDefaults standardUserDefaults] arrayForKey:@"ElsevierJournals"];
    NSArray* apsJournals=[[NSUserDefaults standardUserDefaults] arrayForKey:@"APSJournals"];
    NSArray* aipJournals=[[NSUserDefaults standardUserDefaults] arrayForKey:@"AIPJournals"];
    NSArray* springerJournals=[[NSUserDefaults standardUserDefaults] arrayForKey:@"SpringerJournals"];
    NSMutableArray* knownJournals=[NSMutableArray arrayWithObjects:@"Prog.Theor.Phys.",nil];
    [knownJournals addObjectsFromArray:elsevierJournals];
    [knownJournals addObjectsFromArray:apsJournals];
    [knownJournals addObjectsFromArray:aipJournals];
    [knownJournals addObjectsFromArray:springerJournals];
    if(![knownJournals containsObject:a.journal.name]){
	return;
    }
    [[DumbOperationQueue sharedQueue] addOperation:[[LoadAbstractDOIOperation alloc] initWithArticle:a]];
}

-(void)timerFired:(NSTimer*)t
{
    if(countDown>0){
	countDown--;
//	[bar setDoubleValue:countDown];
	return;
    }
    NSArray*arr=[ac selectedObjects];
    if(!arr)return;
    if([arr count]==0)return;
    Article*a=[arr objectAtIndex:0];
    
    
    if(a.abstract && ![a.abstract isEqualToString:@""]){
	NSArray* aaa=[ac arrangedObjects];
	if(!aaa || [aaa count]==0) return;
	int threshold=[[NSUserDefaults standardUserDefaults] integerForKey:@"eagerMetadataQueryThreshold"];
	int j=[aaa indexOfObject:a];
	int i;
	for(i=j;i<[aaa count] && i<j+threshold ;i++){
	    a=[aaa objectAtIndex:i];
	    if(!a.eprint && !a.doi)
		continue;
	    if(!a.abstract || [a.abstract isEqualToString:@""])
		break;
	}
	if(i==[aaa count]||i==j+threshold)
	    return;
	if(!a)
	    return;
    }
    
    if(a.eprint && ![a.eprint isEqualToString:@""]){
	[[DumbOperationQueue arxivQueue] addOperation:[[ArxivMetadataFetchOperation alloc] initWithArticle:a]];
    }else if(a.doi && ![a.doi isEqualToString:@""]){
	[self loadAbstractUsingDOI:a];
    }
    if(!a.texKey || [a.texKey isEqualToString:@""]){
	[[DumbOperationQueue spiresQueue] addOperation:[[BatchBibQueryOperation alloc]initWithArray:[NSArray arrayWithObject:a]]];
//	[self getBibEntriesWithoutDisplay:self];
    }
    countDown=(int)GRACE;
    if(countDown<GRACEMIN){
	countDown=GRACEMIN;
    }
}
//#pragma mark Split View Delegates
/*-(NSRect)splitView:(NSSplitView *)splitView additionalEffectiveRectOfDividerAtIndex:(NSInteger)dividerIndex {
    return [resizer convertRect:[resizer thumbRect] toView:splitView]; 
}*/

#pragma mark Actions
-(IBAction)progressQuit:(id)sender
{
    [[DumbOperationQueue spiresQueue] cancelCurrentOperation];
}
-(IBAction)changeFont:(id)sender;
{
    [prefController changeFont:sender];
}
-(void)setFontSize:(float)size
{
    if(size<8 || size>20) return;
    [[NSUserDefaults standardUserDefaults] setFloat:(float)size forKey:@"articleViewFontSize"];
}
-(IBAction)zoomIn:(id)sender;
{
    float fontSize=[[NSUserDefaults standardUserDefaults] floatForKey:@"articleViewFontSize"];
    [self setFontSize:fontSize+1];
}
-(IBAction)zoomOut:(id)sender;
{
    float fontSize=[[NSUserDefaults standardUserDefaults] floatForKey:@"articleViewFontSize"];
    [self setFontSize:fontSize-1];
}
-(IBAction)showhideActivityMonitor:(id)sender;
{
    [activityMonitorController showhide:sender];
}
-(IBAction)showPreferences:(id)sender;
{
    [prefController showWindow:sender];
}
-(IBAction)showUsage:(id)sender;
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://www.sns.ias.edu/~yujitach/spires/usage.html"]];
}

-(IBAction)openHomePage:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://www.sns.ias.edu/~yujitach/spires/"]];
}
-(IBAction)showReleaseNotes:(id)sender
{
    [[NSWorkspace sharedWorkspace] openFile:[[NSBundle mainBundle] pathForResource:@"Release Notes" ofType:@"html"]];    
}
-(IBAction)showAcknowledgments:(id)sender;
{
    [[NSWorkspace sharedWorkspace] openFile:[[NSBundle mainBundle] pathForResource:@"Acknowledgments" ofType:@"html"]];    
}
/*-(IBAction)undo:(id)sender
{
    [self enableUndo];
    [[self managedObjectContext] undo];
    [self disableUndo];
}
-(IBAction)redo:(id)sender
{
    [self enableUndo];
    [[self managedObjectContext] redo];
    [self disableUndo];
}*/
-(void)dumpDebugInfo:(id)sender
{
    Article*a=[[ac selectedObjects] objectAtIndex:0];
    NSLog(@"%@",a);
/*    for(Article*b in a.citedBy){
	NSLog(@"citedByEntry:%@",b);
    }*/
//    NSLog(@"%@",a.abstract);
}
-(void)addArticleList:(id)sender
{
//    [self enableUndo];
    NSEntityDescription*entityDesc=[NSEntityDescription entityForName:@"SimpleArticleList" inManagedObjectContext:[self managedObjectContext]];
    SimpleArticleList* al=[[SimpleArticleList alloc] initWithEntity:entityDesc insertIntoManagedObjectContext:[self managedObjectContext]];
    al.name=@"untitled";
    //    al.positionInView=[NSNumber numberWithInt:[[articleListController arrangedObjects] count]*2];
//    [articleListController insertObject:al atArrangedObjectIndex:[[articleListController arrangedObjects] count]];
    [sideTableViewController addArticleList:al];
//    [articleListController insertObject:al atArrangedObjectIndexPath:[NSIndexPath indexPathWithIndex:[[articleListController arrangedObjects] count]]];
    [sideTableViewController rearrangePositionInViewForArticleLists];
//    [self disableUndo];
}

-(void)addArxivArticleList:(id)sender
{
    //    NSLog(@"not implemented");
    ArxivNewArticleList* al=[ArxivNewArticleList arXivNewArticleListWithName:@"untitled/new" inMOC:[self managedObjectContext]];
//    [articleListController insertObject:al atArrangedObjectIndex:[[articleListController arrangedObjects] count]];
//    [articleListController insertObject:al atArrangedObjectIndexPath:[NSIndexPath indexPathWithIndex:[[articleListController arrangedObjects] count]]];
    [sideTableViewController addArticleList:al];
    [sideTableViewController rearrangePositionInViewForArticleLists];
    //    [articleListController insertObject:al atArrangedObjectIndex:[articleLists count]];
}
-(void)addArticleFolder:(id)sender
{
    ArticleFolder* al=[ArticleFolder articleFolderWithName:@"untitled" inMOC:[self managedObjectContext]];
    [sideTableViewController addArticleList:al];
    [sideTableViewController rearrangePositionInViewForArticleLists];
}
-(void)addCannedSearch:(id)sender
{
    NSString*name=[[sideTableViewController currentArticleList] searchString];
    if(!name || [name isEqualToString:@""]){
	name=@"untitled";
    }
    CannedSearch* al=[CannedSearch cannedSearchWithName:name inMOC:[self managedObjectContext]];
    al.searchString=[[sideTableViewController currentArticleList] searchString];
    [sideTableViewController addArticleList:al];
    [sideTableViewController rearrangePositionInViewForArticleLists];
}

-(void)deleteArticleList:(id)sender
{
 /*   ArticleList* al=[sideTableViewController currentArticleList];
    if(!al){
	return;
    }
    [sideTableViewController removeArticleList:al];*/
    [sideTableViewController removeCurrentArticleList];
    /*    if([[articleListController selectedObjects] count]==0)
     return;
     ArticleList* al=[[articleListController selectedObjects] objectAtIndex:0];*/
    /*    NSAlert*alert=[NSAlert alertWithMessageText:@"Delete a list"
     defaultButton:@"Delete" 
     alternateButton:@"Cancel"
     otherButton:nil
     informativeTextWithFormat:@"This operation cannot be undone. Do you really want to delete the list \"%@\"?",al.name];
     [alert beginSheetModalForWindow:[tv window]
     modalDelegate:self 
     didEndSelector:@selector(articleListDeleteAlertDidEnd:code:context:)
     contextInfo:al];	    
     }
     -(void)articleListDeleteAlertDidEnd:(NSAlert*)alert code:(int)choice context:(ArticleList*)al
     {
     if(choice==NSAlertDefaultReturn){*/
//    [articleListController removeObject:al];
//    [self saveArticleLists];
    //    }
}

-(void)sendBugReport:(id)sender
{
    NSString* version=[[[NSBundle mainBundle] infoDictionary] valueForKey:@"CFBundleVersion"];
    int entries=[[allArticleList articles] count];
    NSDictionary* dict=[[NSFileManager defaultManager] fileAttributesAtPath:[[MOC sharedMOCManager] dataFilePath] traverseLink:YES];
    NSNumber* size=[dict valueForKey:NSFileSize];
    [[NSWorkspace sharedWorkspace]
     openURL:[NSURL URLWithString:
	      [[NSString stringWithFormat:
		@"mailto:yujitach@ias.edu?subject=spires.app Bugs/Suggestions for v.%@ (%d entries, %@ bytes)",
		version,entries,size]
	       stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]]];
}    

-(IBAction)installHook:(id)sender
{
    NSString*pkg=[[NSBundle mainBundle] pathForResource:@"spiresHook" ofType:@"pkg"];
  //  NSLog(@"%@",pkg);
    [[NSWorkspace sharedWorkspace] openFile:pkg];
}
-(IBAction)deleteEntry:(id)sender
{
/*    if([[articleListController selectedObjects] count]!=1){
	NSBeep();
	return;
    }*/
//    ArticleList* al=[[articleListController selectedObjects]objectAtIndex:0];
    ArticleList* al=[sideTableViewController currentArticleList];
    if(!al){
	NSBeep(); 
	return;
    }
    NSArray*a=[ac selectedObjects];
    if([al isKindOfClass:[AllArticleList class]]){
	for(Article*x in a){
	    [[self managedObjectContext] deleteObject:x];
	}
    }else if([al isKindOfClass:[SimpleArticleList class]]){
	for(Article*x in a){
	    [al removeArticlesObject:x];
	}
    }
}
-(IBAction)openPDF:(id)sender
{
    Article*o=[[ac selectedObjects] objectAtIndex:0];
    if(!o)
	return;
//    int modifiers=GetCurrentKeyModifiers();
    if([[NSApp currentEvent] modifierFlags] & NSAlternateKeyMask){
	[[PDFHelper sharedHelper] openPDFforArticle:o usingViewer:openWithSecondaryViewer];
    }else{
	[[PDFHelper sharedHelper] openPDFforArticle:o usingViewer:openWithPrimaryViewer];
    }
}
-(IBAction) search:(id)sender
{
//    ArticleList*al= [[articleListController arrangedObjects] objectAtIndex:[articleListController selectionIndex]];
/*    NSArray *a=[articleListController selectedObjects];
    if([a count]==0){
	return;
    }
    ArticleList* al=[a objectAtIndex:0];*/
    ArticleList* al=[sideTableViewController currentArticleList];
    if(!al){
	return;
    }
    if([al isKindOfClass:[CannedSearch class]]){
	[al reload];
	return;
    }
    NSString*searchString=al.searchString;
    if(searchString==nil || [searchString isEqualToString:@""])return;
    [historyController mark:self];
    allArticleList.searchString=searchString;
    [sideTableViewController selectAllArticleList];
    [self querySPIRES: searchString];  // [self searchStringFromPredicate:filterPredicate]];
}
-(IBAction) reloadSelection:(id)sender
{
    Article*o=[ac selection];
    if(o==nil)return;
    [ProgressIndicatorController startAnimation:self];
    [historyController mark:self];
    NSString*eprint=[o valueForKey:@"eprint"];
    if(eprint && ![eprint isEqualToString:@""]){

	[self querySPIRES:[NSString stringWithFormat:@"eprint %@",[o valueForKey:@"eprint"]]]; 	
    }else{
     [self querySPIRES:[NSString stringWithFormat:@"spicite %@",[o valueForKey:@"spicite"]]];
    }
    [ProgressIndicatorController stopAnimation:self];
}
-(IBAction) reloadSelectedArticleList:(id)sender
{
    
/*    int i=[articleListController selectionIndex];
//    int i=[[articleListController selectionIndexPath] indexAtPosition:0];
    if(i==0){
	[self search:nil];
    }
    ArticleList* al=[[articleListController arrangedObjects] objectAtIndex:i];*/
    ArticleList* al=[sideTableViewController currentArticleList];
    if([al isKindOfClass:[AllArticleList class]]){
	[self search:nil];
    }else{
	[[DumbOperationQueue arxivQueue] addOperation:[[ArticleListReloadOperation alloc] initWithArticleList:al]];
    }
//    [al reload];
}
-(IBAction)reloadAllArticleList:(id)sender
{
    NSEntityDescription*authorEntity=[NSEntityDescription entityForName:@"ArxivNewArticleList" inManagedObjectContext:[self managedObjectContext]];
    NSFetchRequest*req=[[NSFetchRequest alloc]init];
    [req setEntity:authorEntity];
    NSPredicate*pred=[NSPredicate predicateWithValue:YES];
    [req setPredicate:pred];
    NSError*error=nil;
    NSArray*a=[[self managedObjectContext] executeFetchRequest:req error:&error];
    for(ArxivNewArticleList*l in a){
	[[DumbOperationQueue arxivQueue] addOperation:[[ArticleListReloadOperation alloc] initWithArticleList:l]];
    }
//    [NSThread detachNewThreadSelector:@selector(reloadAllArticleListMainWork:) toTarget:self withObject:a];
}
/*-(void)reloadAllArticleListMainWork:(NSArray*)a
{
    for(ArxivNewArticleList* al in a){
	[al performSelectorOnMainThread:@selector(reload) withObject:nil waitUntilDone:YES];
	[NSThread sleepForTimeInterval:1];
    }
}*/
-(IBAction)openSelectionInQuickLook:(id)sender
{
    if([[ac selectedObjects] count]==0)return;
    Article*a=[[ac selectedObjects] objectAtIndex:0];
    [[PDFHelper sharedHelper] openPDFforArticle:a usingViewer:openWithQuickLook];
}
-(IBAction)openSelectionInPDFViewer:(id)sender;
{
    if([[ac selectedObjects] count]==0)return;
    Article*a=[[ac selectedObjects] objectAtIndex:0];
    [[PDFHelper sharedHelper] openPDFforArticle:a usingViewer:openWithPrimaryViewer];
}
-(IBAction)openSelectionInSecondaryPDFViewer:(id)sender;
{
    if([[ac selectedObjects] count]==0)return;
    Article*a=[[ac selectedObjects] objectAtIndex:0];
    [[PDFHelper sharedHelper] openPDFforArticle:a usingViewer:openWithSecondaryViewer];
}

-(IBAction)openJournal:(id)sender
{
    if([[ac selectedObjects] count]==0)return;
    Article*a=[[ac selectedObjects] objectAtIndex:0];
//    NSString* univ=[[NSUserDefaults standardUserDefaults] objectForKey:@"universityLibraryToGetPDF"];
//    if(univ && ![univ isEqualToString:@""]){
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"tryToDownloadJournalPDF"]&& (!a.eprint || [a.eprint isEqualToString:@""])){
	if(a.hasPDFLocally){
	    [self openPDF:self];
	    return;
	}else if([[PDFHelper sharedHelper] downloadAndOpenPDFfromJournalForArticle:a]){ 
	    // this returns NO when it's immediately clear it can't be downloaded
	    return; 
	}
    }
    NSString* doiURL=[@"http://dx.doi.org/" stringByAppendingString:a.doi];
    [[NSWorkspace sharedWorkspace] openURL:[[NSURL URLWithString:doiURL] proxiedURLForELibrary]];
    [self showInfoOnAssociation];

}

-(IBAction)getBibEntriesWithoutDisplay:(id)sender
{
    NSArray*x=[ac selectedObjects];
//    [NSThread detachNewThreadSelector:@selector(getBibEntriesMainWork:) toTarget:self withObject:x];
    [[DumbOperationQueue spiresQueue] addOperation:[[BatchBibQueryOperation alloc]initWithArray:x]];
}
-(IBAction)getBibEntries:(id)sender
{
    [self getBibEntriesWithoutDisplay:sender];
    [bibViewController setArticles:[ac selectedObjects]];
    [bibViewController showWindow:sender];
}

-(IBAction)reloadFromSPIRES:(id)sender
{
    for(Article*article in [ac selectedObjects]){
	NSString* target=nil;
	if(article.articleType==ATEprint){
	    target=[@"eprint " stringByAppendingString:article.eprint];
	}else if(article.articleType==ATSpires){
	    target=[@"spicite " stringByAppendingString:article.spicite];	
	}else if(article.articleType==ATSpiresWithOnlyKey){
	    target=[@"key " stringByAppendingString:article.spiresKey];	
	}
	if(target){
	    [[DumbOperationQueue spiresQueue] addOperation:[[SpiresQueryOperation alloc]initWithQuery:target 
											       andMOC:[self managedObjectContext]]];
	}
    }
}
-(IBAction)toggleFlagged:(id)sender
{
    for(Article*article in [ac selectedObjects]){
	if(article.flag==AFFlagged){
	    article.flag=AFRead;
	}else{
	    article.flag=AFFlagged;
	}
    }
}
#pragma mark PDF Association
-(void)reassociationAlertWithPathGivenDidEnd:(NSAlert*)alert code:(int)choice context:(NSString*)path
{
    if(choice==NSAlertDefaultReturn){
	Article*o=[[ac selectedObjects]objectAtIndex:0];
	[o associatePDF:path];
    }
}

-(void)showInfoOnAssociation
{
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"alreadyShownInfoOnAssociation"])
	return;
    
    NSAlert*alert=[NSAlert alertWithMessageText:@"After you download a paper manually, "
				  defaultButton:@"OK" 
				alternateButton:nil
				    otherButton:nil
		      informativeTextWithFormat:@"register it to Spires.app by dropping the PDF into the lower pane. \nYou can move the PDF to anywhere afterwards, because Spires.app keeps track of it."];
    [alert setShowsSuppressionButton:YES];
    [alert beginSheetModalForWindow:window
		      modalDelegate:self
		     didEndSelector:@selector(infoAlertDidEnd:returnCode:contextInfo:)
			contextInfo:nil];    
}
- (void) infoAlertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo;
{
    if ([[alert suppressionButton] state] == NSOnState) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"alreadyShownInfoOnAssociation"];
    }
}


#pragma mark URL handling
-(NSString*)extractArXivID:(NSString*)x
{
    NSString*s=[x stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    if(s==nil)return @"";
    if([s isEqualToString:@""])return @"";
//    NSLog(@"%@",s);
    NSRange r=[s rangeOfString:@"/" options:NSBackwardsSearch];
    if(r.location!=NSNotFound){
	s=[s substringFromIndex:r.location+1];
    }
    if(s==nil)return @"";
    if([s isEqualToString:@""])return @"";
    
     NSScanner*scanner=[NSScanner scannerWithString:s];
    NSCharacterSet*set=[NSCharacterSet characterSetWithCharactersInString:@".0123456789"];
    [scanner scanUpToCharactersFromSet:set intoString:NULL];
    NSString* d=nil;
    [scanner scanCharactersFromSet:set intoString:&d];
    if(d){
	if([d hasSuffix:@"."]){
	    d=[d substringToIndex:[d length]-1];
	}
	for(NSString*cat in [NSArray arrayWithObjects:@"hep-th",@"hep-ph",@"hep-ex",@"astro-ph",@"math-ph",@"math",nil]){
	    if([x rangeOfString:cat].location!=NSNotFound){
		d=[NSString stringWithFormat:@"%@/%@",cat,d];
		break;
	    }
	}
	return d;
    }
    else return nil;
}

-(void)lookUpEprint:(NSURL*)url
{
    NSString*eprint=[self extractArXivID:[url absoluteString]];
    if(eprint){
	NSString*searchString=[@"eprint " stringByAppendingString:eprint];
//	[articleListController setSelectionIndex:0];
	[sideTableViewController selectAllArticleList];
//	[articleListController setSelectionIndexPath:[NSIndexPath indexPathWithIndex:0]];
	allArticleList.searchString=searchString;
//	[self querySPIRES:searchString];
	[self performSelector:@selector(querySPIRES:) 
		   withObject:searchString 
		   afterDelay:1];
    }
}
-(void)handleURL:(NSURL*) url
{
    NSLog(@"handles %@",url);
    if([[url scheme] isEqualTo:@"spires-search"]){
	NSString*searchString=[[[url absoluteString] substringFromIndex:[(NSString*)@"spires-search://" length]] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
//	NSLog(@"%@",searchString);
//	[articleListController setSelectionIndex:0];
//	[articleListController setSelectionIndexPath:[NSIndexPath indexPathWithIndex:0]];
	[sideTableViewController selectAllArticleList];
	allArticleList.searchString=searchString;
	[historyController mark:self];
	[self querySPIRES:searchString];
    }/*else if([[url scheme] isEqualTo:@"spires-download-and-open-pdf-internal"]){
	Article*o=[[ac selectedObjects] objectAtIndex:0];
	if(!o)
	    return;
	[pi startAnimation:self];
	[[ArxivHelper sharedHelper] startDownloadPDFforID:o.eprint
						 delegate:self 
					   didEndSelector:@selector(pdfDownloadDidEnd:)
						 userInfo:o];
    }*/else if([[url scheme] isEqualTo:@"spires-open-pdf-internal"]){
	[self openPDF:self];
    }else if([[url scheme] isEqualTo:@"spires-lookup-eprint"]){
	[self lookUpEprint:url];
    }else if([[url scheme] isEqualTo:@"spires-get-bib-entry"]){
	[self getBibEntries:self];
    }else if([[url scheme] isEqualTo:@"spires-open-journal"]){
	[self openJournal:self];
    }else if([[url scheme] isEqualTo:@"spires-quicklook-closed"]){
	[[PDFHelper sharedHelper] quickLookDidClose:self];
    }else if([[url scheme] isEqualTo:@"http"]){
	[[NSWorkspace sharedWorkspace] openURL:url];
	if([[url path] rangeOfString:@"spires"].location==NSNotFound){
	    [self showInfoOnAssociation];
	}
    }else if([[url scheme] isEqualTo:@"file"]){
	Article*o=[[ac selectedObjects] objectAtIndex:0];
	if(!o)
	    return;
	if(o.articleType==ATEprint){
	    NSAlert*alert=[NSAlert alertWithMessageText:@"PDF association to an eprint"
					  defaultButton:@"Yes" 
					alternateButton:@"Cancel"
					    otherButton:nil
			      informativeTextWithFormat:@"Do you prefer %@ instead of the eprint?", [[url path] stringByAbbreviatingWithTildeInPath]];
	    [alert beginSheetModalForWindow:window
			      modalDelegate:self 
			     didEndSelector:@selector(reassociationAlertWithPathGivenDidEnd:code:context:)
				contextInfo:[url path]];	    	    
	}else if(o.hasPDFLocally){
	    NSAlert*alert=[NSAlert alertWithMessageText:@"PDF already associated"
					  defaultButton:@"Change" 
					alternateButton:@"Cancel"
					    otherButton:nil
			      informativeTextWithFormat:@"PDF is already associated to this article. Do you want to change it with %@?", [[url path] stringByAbbreviatingWithTildeInPath]];
	    [alert beginSheetModalForWindow:window
			      modalDelegate:self 
			     didEndSelector:@selector(reassociationAlertWithPathGivenDidEnd:code:context:)
				contextInfo:[url path]];	    
	}else{
	    [o associatePDF:[url path]];
	}
    }
}
#pragma mark WebView Delegate
-(void)webView:(WebView*)sender decidePolicyForNavigationAction:(NSDictionary *)actionInformation request:(NSURLRequest *)request frame:(WebFrame *)frame decisionListener:(id < WebPolicyDecisionListener >)listener
{
    NSURL* url=[request URL];
    if([[url scheme] isEqualToString:@"about"]){
	[listener use];
    }else{
	[self handleURL:url];
	[listener ignore];
    }
}
- (NSArray *)webView:(WebView *)sender contextMenuItemsForElement:(NSDictionary *)element defaultMenuItems:(NSArray *)defaultMenuItems
{
    NSURL* url=[element objectForKey:WebElementLinkURLKey];
    if(url && [[url scheme] rangeOfString:@"open-pdf"].location!=NSNotFound){
	NSMenuItem* mi1=[[NSMenuItem alloc] initWithTitle:[@"Open in " stringByAppendingString:[[PDFHelper sharedHelper] displayNameForViewer:openWithPrimaryViewer]] action:@selector(openSelectionInPDFViewer:) keyEquivalent:@""];
	NSMenuItem* mi2=[[NSMenuItem alloc] initWithTitle:[@"Open in " stringByAppendingString:[[PDFHelper sharedHelper] displayNameForViewer:openWithSecondaryViewer]] action:@selector(openSelectionInSecondaryPDFViewer:) keyEquivalent:@""];
	return [NSArray arrayWithObjects: mi1, mi2, nil];
    }
    return defaultMenuItems;
}
- (void)webView:(WebView *)sender willPerformDragSourceAction:(WebDragSourceAction)action fromPoint:(NSPoint)point withPasteboard:(NSPasteboard *)pasteboard
{
    if([[pasteboard types] containsObject:NSURLPboardType]){
	NSURL* url=[NSURL URLFromPasteboard:pasteboard];
	if([[url scheme] isEqualToString:@"spires-get-bib-entry"]){
	    [pasteboard declareTypes:[NSArray arrayWithObject:NSStringPboardType]
			       owner:nil];
	    Article*a=[[ac selectedObjects] objectAtIndex:0];
	    [pasteboard setString:[a IdForCitation]
			  forType:NSStringPboardType];
	}
    }
}
#pragma mark Default provided by templates
-(NSManagedObjectContext*)managedObjectContext
{
    return [MOC moc];
}
/**
    Returns the support folder for the application, used to store the Core Data
    store file.  This code uses a folder named "spires" for
    the content, either in the NSApplicationSupportDirectory location or (if the
    former cannot be found), the system's temporary directory.
 */


/**
    Returns the NSUndoManager for the application.  In this case, the manager
    returned is that of the managed object context for the application.
 */
 
- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window {
    return [[self managedObjectContext] undoManager];
}


/**
    Performs the save action for the application, which is to send the save:
    message to the application's managed object context.  Any encountered errors
    are presented to the user.
 */
 
- (IBAction) saveAction:(id)sender {

    NSError *error = nil;
    if (![[self managedObjectContext] save:&error]) {
	[[MOC sharedMOCManager] presentMOCSaveError:error];
        [[NSApplication sharedApplication] presentError:error];
    }/*else if([self syncEnabled]){
	[self syncAction:self];
    }*/
}


/**
    Implementation of the applicationShouldTerminate: method, used here to
    handle the saving of changes in the application managed object context
    before the application terminates.
 */
 
- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {

    NSError *error=nil;
    int reply = NSTerminateNow;
    NSManagedObjectContext*managedObjectContext=[MOC moc];
    if (managedObjectContext != nil) {
        if ([managedObjectContext commitEditing]) {
            if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
				
                // This error handling simply presents error information in a panel with an 
                // "Ok" button, which does not include any attempt at error recovery (meaning, 
                // attempting to fix the error.)  As a result, this implementation will 
                // present the information to the user and then follow up with a panel asking 
                // if the user wishes to "Quit Anyway", without saving the changes.

                // Typically, this process should be altered to include application-specific 
                // recovery steps.  
		[[MOC sharedMOCManager] presentMOCSaveError:error];
                BOOL errorResult = [[NSApplication sharedApplication] presentError:error];
                if (errorResult == YES) {
                    reply = NSTerminateCancel;
                } 

                else {
					
                    int alertReturn = NSRunAlertPanel(nil, @"Could not save changes while quitting. Quit anyway?" , @"Quit anyway", @"Cancel", nil);
                    if (alertReturn == NSAlertAlternateReturn) {
                        reply = NSTerminateCancel;	
                    }
                }
            }
        } 
        
        else {
            reply = NSTerminateCancel;
        }
    }
//    [self saveArticleLists];
    return reply;
}

-(void)applicationWillTerminate:(NSNotification*)note
{
    system("killall SpiresQuickLookHelper");
}
#pragma mark exception
/*
- (void)printStackTrace:(NSException *)e
{
    NSString *stack = [[e userInfo] objectForKey:NSStackTraceKey];
    if (stack) {
        NSTask *ls = [[NSTask alloc] init];
        NSString *pid = [[NSNumber numberWithInt:[[NSProcessInfo processInfo] processIdentifier]] stringValue];
        NSMutableArray *args = [NSMutableArray arrayWithCapacity:20];
	
        [args addObject:@"-p"];
        [args addObject:pid];
        [args addObjectsFromArray:[stack componentsSeparatedByString:@"  "]];
        // Note: function addresses are separated by double spaces, not a single space.
	
        [ls setLaunchPath:@"/usr/bin/atos"];
        [ls setArguments:args];
        [ls launch];
        [ls release];
	
    } else {
        NSLog(@"No stack trace available.");
    }
}
- (BOOL)exceptionHandler:(id)sender shouldLogException:(NSException *)exception mask:(unsigned int)mask
{
    [self printStackTrace:exception];
    return YES;
}
*/
@end
