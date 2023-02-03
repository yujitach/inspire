//
//  spires_AppDelegate.m
//  spires
//
//  Created by Yuji on 08/10/13.
//  Copyright Y. Tachikawa 2008 . All rights reserved.
//

#import "SpiresAppDelegate.h"
#import "SpiresAppDelegate_actions.h"
#import "AppDelegate.h"
#import "MOC.h"
#import "DumbOperation.h"
#import "ArticleFetchOperation.h"

#import "Article.h"
#import "ArticleData.h"
#import "JournalEntry.h"

#import "SpiresHelper.h"

#import "AllArticleList.h"
#import "ArxivNewArticleList.h"
#import "SimpleArticleList.h"

#import "ArticleView.h"

#import "SideOutlineViewController.h"
#import "MainTableViewController.h"

#import "HistoryController.h"

#import "MessageViewerController.h"
#import "ActivityMonitorController.h"
#import "TeXWatcherController.h"
#import "BibViewController.h"
#import "PrefController.h"

#import "PDFHelper.h"

#import "SpiresQueryOperation.h"
#import "TeXBibGenerationOperation.h"
#import "BatchBibQueryOperation.h"
#import "LoadAbstractDOIOperation.h"

#import "SPSearchFieldWithProgressIndicator.h"


#import <Quartz/Quartz.h>
#import "SyncManager.h"
#import "NSUserDefaults+defaults.h"
#import "AbstractRefreshManager.h"

#import "MOC.h"

#import "NSString+magic.h"

#import <sys/mount.h>

@interface SpiresAppDelegate (Timers)
-(void)clearUnreadFlagOfArticle:(NSTimer*)timer;
@end

@implementation SpiresAppDelegate
{
    SyncManager*syncManager;
    IBOutlet NSSplitView*sp;
    IBOutlet MainTableViewController*mainTableViewController;
    NSSplitViewController*splitVC;
    NSTimer*unreadTimer;
    ArticleView*wv;
    IBOutlet NSView*articleViewContainer;
}
+(void)initialize
{
    if(self!=[SpiresAppDelegate class]){
	return;
    }
    [NSUserDefaults loadInitialDefaults];
}
#pragma mark NSApplication delegates
- (void)applicationWillBecomeActive:(NSNotification *)notification
{
    [window makeKeyAndOrderFront:self];
}
- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)app
{
    [window makeKeyAndOrderFront:self];
    return NO;
}
-(void)handlePDF:(NSString*)path
{
    NSFileManager* fm=[NSFileManager defaultManager];
    NSString* pdfDir=[[NSUserDefaults standardUserDefaults] stringForKey:@"pdfDir"];
    NSString*fileName=[path lastPathComponent];
    NSString*destination=[[NSString stringWithFormat:@"%@/%@",pdfDir,fileName] stringByExpandingTildeInPath];
    NSLog(@"moves %@ to %@",path,destination);
    NSError*error=nil;
    BOOL success=[fm moveItemAtPath:path toPath:destination error:&error];
    if(!success){
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
            TeXBibGenerationOperation*op=[[TeXBibGenerationOperation alloc] initWithTeXFile:path
                                                                                     andMOC:[MOC moc]
                                                                             byLookingUpWeb:YES
                                                                           andRefreshingAll:NO];
            [[OperationQueues sharedQueue] addOperation:op];
	}
    }
}


#pragma mark Crash Detection

-(NSString*)recentlyCrashed
{
    NSFileManager*fm=[NSFileManager defaultManager];
    NSString*crashDir=[@"~/Library/Logs/DiagnosticReports" stringByExpandingTildeInPath];
    NSArray*a=[fm contentsOfDirectoryAtPath:crashDir error:NULL];
    NSDate*date=[NSDate distantPast];
    NSString*s=nil;
    for(NSString* path in a){
	if(![path hasPrefix:@"spires"])
	    continue;
	NSDictionary *fileAttributes = [fm attributesOfItemAtPath:[crashDir stringByAppendingFormat:@"/%@",path] error:NULL];
	NSDate* modDate=fileAttributes[NSFileModificationDate];
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
    [fm createDirectoryAtPath:@"/tmp/SpiresCrashReport" withIntermediateDirectories:YES attributes:nil error:NULL];
    [fm copyItemAtPath:path 
		toPath:[@"/tmp/SpiresCrashReport/" stringByAppendingString:[path lastPathComponent]] 
		 error:NULL];
    system("cp /tmp/spiresTemporary.xml /tmp/SpiresCrashReport/");
    system("grep spires /var/log/system.log | grep -v malloc  > /tmp/SpiresCrashReport/system.spires.log");
    system("bzip2 -dc /var/log/system.log.0.bz2 | grep spires | grep -v malloc  > /tmp/SpiresCrashReport/system.spires.0.log");
    system("rm /tmp/SpiresCrashReport/*.tar.bz2");
    NSString*line=[NSString stringWithFormat:@"cd /tmp/SpiresCrashReport; tar jcf SpiresCrashReport-%ld.tar.bz2 *.log *.crash *.xml",(unsigned long)time(NULL) ];
    system([line UTF8String]);
    system("rm /tmp/SpiresCrashReport/*.log");
    system("rm /tmp/SpiresCrashReport/*.crash");
    system("rm /tmp/SpiresCrashReport/*.xml");
    [[NSWorkspace sharedWorkspace] openFile:@"/tmp/SpiresCrashReport/" withApplication:@"Finder"];
}

-(IBAction)crashCheck:(id)sender
{
    static NSString*path=nil;
    path=[self recentlyCrashed];
    if(!path)
	return;
    NSAlert*alert=[[NSAlert alloc] init];
    alert.messageText=@"Sorry, spires.app recently crashed.\nPlease help develop this app by sending me the crash report.";
    [alert addButtonWithTitle:@"YES"];
    [alert addButtonWithTitle:@"No thanks"];
    alert.informativeText=@"Clicking Yes will bring up your email program and a Finder window containing the crash log.\n"
    @"Please attach the log file to the email and send it.\n"
    @"The log will contain the name of the articles which caused the crash, etc, which you can check by unzipping the file.";
//    [alert setShowsSuppressionButton:YES];
    NSInteger returnCode=[alert runModal];
    if(returnCode==NSAlertFirstButtonReturn){
	[self prepareCrashReport:path];
	[self sendBugReport:self];
    }

    // If the crash happened when displaying an entry,
    // clearing the searchString helps not repeating
    // the crash immediately after launch.
    [AllArticleList allArticleList].searchString=nil;
    
}


#pragma mark UI glues
-(void)upgradeSplitView
{
    if(@available(macOS 11,*)){
//        window.titleVisibility=NSWindowTitleHidden;
        window.toolbarStyle=NSWindowToolbarStyleUnifiedCompact;
//        window.titlebarSeparatorStyle=NSTitlebarSeparatorStyleShadow;
//        [tb insertItemWithItemIdentifier:NSToolbarSidebarTrackingSeparatorItemIdentifier atIndex:1];
    }
    if(@available(macOS 10.15,*)){
        window.styleMask|=NSWindowStyleMaskFullSizeContentView;
        splitVC=[[NSSplitViewController alloc] init];
        splitVC.splitView.vertical=YES;
        NSSplitViewItem*o=[NSSplitViewItem sidebarWithViewController:sideOutlineViewController];
        [splitVC addSplitViewItem:o];
        o.canCollapse=NO;
        NSSplitViewItem*m=[NSSplitViewItem splitViewItemWithViewController:mainTableViewController];
        [splitVC addSplitViewItem:m];
        splitVC.view.translatesAutoresizingMaskIntoConstraints=NO;
        splitVC.splitView.autosaveName=@"vsplit";
        [window.contentView replaceSubview:sp with:splitVC.view ];
        [splitVC.view.topAnchor constraintEqualToAnchor:window.contentView.topAnchor
                                               constant:0].active=YES;
        [splitVC.view.bottomAnchor constraintEqualToAnchor:((NSLayoutGuide*)window.contentLayoutGuide).bottomAnchor].active=YES;
        [splitVC.view.leftAnchor constraintEqualToAnchor:((NSLayoutGuide*)window.contentLayoutGuide).leftAnchor].active=YES;
        [splitVC.view.rightAnchor constraintEqualToAnchor:((NSLayoutGuide*)window.contentLayoutGuide).rightAnchor].active=YES;
    }
}
-(void)insertArticleView
{
    NSRect rect=NSZeroRect;
    rect.size=articleViewContainer.frame.size;
    wv=[[ArticleView alloc] initWithFrame:rect];
    wv.autoresizingMask=NSViewWidthSizable|NSViewHeightSizable;
    wv.navigationDelegate=self;
    [articleViewContainer addSubview:wv];
}
- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar
     itemForItemIdentifier:(NSToolbarItemIdentifier)itemIdentifier
 willBeInsertedIntoToolbar:(BOOL)flag;
{
//    if([itemIdentifier isEqualTo:@"SearchToolbarItem"]){
    if(@available(macOS 11,*)){
        NSToolbarItem*search=[tb items][3];
        NSSearchToolbarItem*ti=[[NSSearchToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
        ti.searchField=(NSSearchField*)search.view;
        return ti;
    }
    return nil;
}
-(void)awakeFromNib
{
    [self insertArticleView];
    [self upgradeSplitView];
    
    for(NSToolbarItem*ti in [tb items]){
        if([[ti  label] isEqualToString:@"Search Field"]){
            NSSize s=[ti minSize];
            s.width=10000;
            [ti setMaxSize:s];
        }else{
            if(@available(macOS 11,*)){
                ti.navigational=YES;
            }
        }
        if([[ti  label] isEqualToString:@"Flag"]){
            if(@available(macOS 11,*)){
                ti.image=[NSImage imageWithSystemSymbolName:@"flag.fill" accessibilityDescription:@"flag"];
            }
        }
    }
/*
    if(@available(macOS 11,*)){
        tb.delegate=self;
        [tb insertItemWithItemIdentifier:@"SearchToolbarItem" atIndex:3];
        [tb removeItemAtIndex:4];
    }
*/
    [ac addObserver:self
	 forKeyPath:@"selection"
	    options:NSKeyValueObservingOptionNew//|NSKeyValueObservingOptionInitial
	    context:nil];

    [ac addObserver:self
	 forKeyPath:@"arrangedObjects"
	    options:NSKeyValueObservingOptionNew//|NSKeyValueObservingOptionInitial
	    context:nil];

    [searchField setProgressQuitAction:@selector(progressQuit:)];

}

-(void)setupServices
{
    [NSApp setServicesProvider: self];
    NSUpdateDynamicServices();
    
}
-(BOOL)showWelcome
{
    NSString*welcome=@"v2.0.5alert";
    NSString*key=[welcome stringByAppendingString:@"ShownShown"];
    if(![[NSUserDefaults standardUserDefaults] boolForKey:key]){
	messageViewerController=[[MessageViewerController alloc] initWithRTF:[[NSBundle mainBundle] pathForResource:welcome ofType:@"rtf"]];
	// this window controller shows itself automatically!
	[[NSUserDefaults standardUserDefaults] setBool:YES forKey:key];
        return YES;
    }else{
        return NO;
    }
}

-(void)clearAllArticleList_
{
    NSEntityDescription*entity=[NSEntityDescription entityForName:@"Article" inManagedObjectContext:[MOC moc]];
    NSFetchRequest*req=[[NSFetchRequest alloc]init];
    [req setEntity:entity];
    [req setPredicate:[NSPredicate predicateWithValue:YES]];
    [req setFetchLimit:0];
    [req setResultType:NSManagedObjectResultType];
    [req setReturnsObjectsAsFaults:NO];
    [req setIncludesPropertyValues:YES];
    [req setRelationshipKeyPathsForPrefetching:@[@"inLists"]];
    NSError*error=nil;
    [[MOC moc] executeFetchRequest:req error:&error];
    [AllArticleList allArticleList].articles=nil;
    [[AllArticleList allArticleList] reload];
}
-(void)clearAllArticleList
{
    BOOL toShowAlert=NO;
    if([[self databaseSize] integerValue]>1024L*1024*10){
        toShowAlert=YES;
    }
    if(toShowAlert){
        NSAlert*alert=[[NSAlert alloc] init];
        alert.messageText=@"Optimizing database";
        [alert addButtonWithTitle:@"Start Optimization"];
        alert.informativeText=@"The app is going to optimize the database. Usually it's quick, but it might take a very long time. So please be patient. The app will not explicitly tell you when the optimization is done. Consider it done when the app becomes usable.";
        //[alert setAlertStyle:NSCriticalAlertStyle];
       // [alert beginSheetModalForWindow:window modalDelegate:nil didEndSelector:nil contextInfo:nil];
        [alert runModal];
    }
    [self clearAllArticleList_];
    [self saveAction:nil];
//    [searchField setEnabled:YES];
}
-(void)removeSpaceFromTexKey
{
    NSManagedObjectContext*moc=[[MOC sharedMOCManager] createSecondaryMOC];
    [moc performBlock:^{
        NSEntityDescription*articleDataEntity=[NSEntityDescription entityForName:@"ArticleData" inManagedObjectContext:moc];
        NSFetchRequest*req=[[NSFetchRequest alloc]init];
        [req setEntity:articleDataEntity];
        NSPredicate*pred=[NSPredicate predicateWithFormat:@"texKey contains ' '"];
        [req setPredicate:pred];
        
        [req setIncludesPropertyValues:YES];
        [req setRelationshipKeyPathsForPrefetching:@[@"article"]];
        [req setReturnsObjectsAsFaults:NO];
        NSError*error=nil;
        NSArray*a=[moc executeFetchRequest:req error:&error];
        NSLog(@"texKey containing space #:%@",@(a.count));
        for(ArticleData*ad in a){
            NSString*old=ad.texKey;
            NSLog(@"original key:%@",old);
            NSString*new=[old stringByReplacingOccurrencesOfString:@" " withString:@""];
            NSLog(@"new key:%@",new);
            ad.texKey=new;
        }
        [moc save:&error];
    }];
}
-(void)collaborationShowsOnlyCollaboration
{
    NSManagedObjectContext*moc=[[MOC sharedMOCManager] createSecondaryMOC];
    [moc performBlock:^{
        NSEntityDescription*articleDataEntity=[NSEntityDescription entityForName:@"ArticleData" inManagedObjectContext:moc];
        NSFetchRequest*req=[[NSFetchRequest alloc]init];
        [req setEntity:articleDataEntity];
        NSPredicate*pred=[NSPredicate predicateWithFormat:@"collaboration!=nil AND collaboration!=''"];
        [req setPredicate:pred];
        
        [req setIncludesPropertyValues:YES];
        [req setRelationshipKeyPathsForPrefetching:@[@"article"]];
        [req setReturnsObjectsAsFaults:NO];
        NSError*error=nil;
        NSArray*a=[moc executeFetchRequest:req error:&error];
        NSLog(@"entries for collaborations: %@",@(a.count));
        for(ArticleData*ad in a){
            [ad.article setAuthorNames:@[]];
        }
        [moc save:&error];
    }];
}
-(void)tweakTableView
{
    if(@available(macOS 10.11, *)){
        for(NSTableColumn*col in [articleListView tableColumns]){
            NSString*title=col.title;
            if([title isEqualToString:@"eprint"]||[title isEqualToString:@"cites"]){
                NSTextFieldCell*cell=(NSTextFieldCell*)col.dataCell;
                cell.font=[NSFont monospacedDigitSystemFontOfSize:[NSFont systemFontSize] weight:NSFontWeightRegular];                
            }
        }
    }
    if(@available(macOS 11, *)){
        articleListView.style=NSTableViewStylePlain;
        [articleListView tableColumnWithIdentifier:@"flag"].width=25;
    }
}

- (BOOL)isRunningOnReadOnlyVolume {
    // taken from https://github.com/Squirrel/Squirrel.Mac/pull/186/files
    struct statfs statfsInfo;
    NSURL *bundleURL = NSRunningApplication.currentApplication.bundleURL;
    int result = statfs(bundleURL.fileSystemRepresentation, &statfsInfo);
    if (result == 0) {
        return (statfsInfo.f_flags & MNT_RDONLY) != 0;
    } else {
        // If we can't even check if the volume is read-only, assume it is.
        return YES;
    }
}

-(void)alertConcerningAppTranslocation{
    NSAlert*alert=[[NSAlert alloc] init];
    alert.messageText=@"Please move the app after downloading it";
    [alert addButtonWithTitle:@"OK, I quit the app and move it"];
    alert.informativeText=@"Please move the app to, say, /Applications, using your mouse/trackpad, not from the command line. \n\nApple decided that they don't allow the app to auto-update otherwise. \n\nI am sorry for the inconvenience.";
    [alert runModal];
    [NSApp terminate:nil];
}
-(void)mirrorCheck
{
    NSString*mirrorToUse=[[NSUserDefaults standardUserDefaults] stringForKey:@"mirrorToUse"];
    if(![mirrorToUse isEqualToString:@""]){
        [[NSUserDefaults standardUserDefaults] setObject:@"" forKey:@"mirrorToUse"];
        NSAlert*alert=[[NSAlert alloc] init];
        alert.messageText=@"This app no longer uses arXiv mirrors";
        [alert addButtonWithTitle:@"OK"];
        [alert addButtonWithTitle:@"Write to Yuji"];
        alert.informativeText=[NSString stringWithFormat:@"You set up this app to use %@arxiv.org long time ago. But arXiv mirrors are slowly taken down due to arXiv policy. This app no longer use the mirrors. If you think using mirror servers are essentiall, please do email to me.",mirrorToUse];
        if([alert runModal]==NSAlertSecondButtonReturn){
            [self sendBugReport:self];
        };
    }
}
-(void)applicationDidFinishLaunching:(NSNotification*)notification
{
    if([self isRunningOnReadOnlyVolume]){
        [self alertConcerningAppTranslocation];
    }
    [self setupServices];
    [self crashCheck:self];
    [self showWelcome];
    [self mirrorCheck];

    [sideOutlineViewController loadArticleLists];
    [sideOutlineViewController attachToMOC];
    
    [self tweakTableView];
    
    if([NSEvent modifierFlags]&NSEventModifierFlagOption){
	[AllArticleList allArticleList].searchString=nil;
    }
    [window makeKeyAndOrderFront:self];
    
    if(![[NSUserDefaults standardUserDefaults] boolForKey:@"AllArticleListArticlesCleared"]){
//    if(YES){
        [self performSelector:@selector(clearAllArticleList) withObject:nil afterDelay:0];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"AllArticleListArticlesCleared"];
    }

    if(![[NSUserDefaults standardUserDefaults] boolForKey:@"texKeySpaceRemoved"]){
//    if(YES){
        [self removeSpaceFromTexKey];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"texKeySpaceRemoved"];
    }

    if(![[NSUserDefaults standardUserDefaults] boolForKey:@"collaborationShowsOnlyCollaboration"]){
        //    if(YES){
        [self collaborationShowsOnlyCollaboration];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"collaborationShowsOnlyCollaboration"];
    }

    
    [sideOutlineViewController performSelector:@selector(selectAllArticleList) withObject:nil afterDelay:0];
    [self performSelector:@selector(makeTableViewFirstResponder) withObject:nil afterDelay:0];
    prefController=[[PrefController alloc]init];
    activityMonitorController=[[ActivityMonitorController alloc] init];
    texWatcherController=[[TeXWatcherController alloc]init];
    bibViewController=[[BibViewController alloc] init];
    syncManager=[[SyncManager alloc] init];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mocMerged:) name:UIMOCDidMergeNotification object:nil];
}
-(void)mocMerged:(NSNotification*)n
{
    [ac didChangeArrangementCriteria];
}
-(BOOL)busyUpdating
{
    NSArray*a=[[OperationQueues sharedQueue] operations];
    int i=0;
    for(NSOperation *op in a){
        if([op isKindOfClass:[ArticleFetchOperation class]]){
            i++;
        }
    }
    if(i>=2){
        return YES;
    }else{
        return NO;
    }
}
-(void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if([keyPath isEqualToString:@"selection"]){
	NSArray*a=[ac selectedObjects];
	if(!a || [a count]==0){
//	    NSLog(@"no selection");
	    [wv setArticle:(Article*)NSNoSelectionMarker];
	}else if([a count]>1){
	    [wv setArticle:(Article*)NSMultipleValuesMarker];
	}else{
//	    NSLog(@"selection:%a",a);
            if([self busyUpdating]){
                return;
            }
	    Article*ar=a[0];
	    [wv setArticle:ar];
	    if(ar.flag & AFIsUnread){
		if(unreadTimer){
		    [unreadTimer invalidate];
		}
                NSTimeInterval delay=[[NSUserDefaults standardUserDefaults] floatForKey:@"unreadTimerDelay"];
                if(delay<0.01)delay=1;
		unreadTimer=[NSTimer scheduledTimerWithTimeInterval:delay
							     target:self 
							   selector:@selector(clearUnreadFlagOfArticle:) 
							   userInfo:ar 
							    repeats:NO];
            if([unreadTimer respondsToSelector:@selector(setTolerance:)]){
                [unreadTimer setTolerance:0.1*delay];
            }
            
		    
	    }
        [self prefetchAbstract];
	}
    }else if([keyPath isEqualToString:@"arrangedObjects"]){
	NSInteger num=[[ac arrangedObjects] count];
	NSString*head=@"spires";
	ArticleList*al=[sideOutlineViewController currentArticleList];
	if(al){
	    head=al.name;
	}
        NSString*howmany=[NSString stringWithFormat:@"%d %@",(int)num,(num==1?@"entry":@"entries") ];
        if(num>=LOADED_ENTRIES_MAX){
            howmany=[NSString stringWithFormat:@"more than %d entries", (int)LOADED_ENTRIES_MAX];
        }
        if(@available(macOS 11,*)){
            window.title=head;
            window.subtitle=howmany;
        }else{
            [window setTitle:[NSString stringWithFormat:@"%@ (%@)",head,howmany]];
        }
    }
}

#pragma mark Timers
-(void)clearUnreadFlagOfArticle:(NSTimer*)timer
{
    Article*a=[timer userInfo];
    [a setFlag:[a flag]&(~AFIsUnread)];
    unreadTimer=nil;
}


-(void)prefetchAbstract
{
    NSArray*arr=[ac selectedObjects];
    if(!arr)return;
    if([arr count]==0)return;
    Article*a=arr[0];

    NSArray* aaa=[ac arrangedObjects];
    if(!aaa || [aaa count]==0) return;
    int threshold=(int)[[NSUserDefaults standardUserDefaults] integerForKey:@"eagerMetadataQueryThreshold"];
    int j=(int)[aaa indexOfObject:a];
    int i;
    for(i=j;i<(int)[aaa count] && i<j+threshold ;i++){
        Article*b=aaa[i];
        if(!b.eprint && !b.doi)
            continue;
        if(!b.abstract || [b.abstract isEqualToString:@""]){
            [[AbstractRefreshManager sharedAbstractRefreshManager] refreshAbstractOfArticle:b whenRefreshed:nil];
        }
    }
}


#pragma mark Public Interfaces


-(BOOL)currentListIsArxivReplaced
{
    ArticleList*al=[sideOutlineViewController currentArticleList];
    if(![al isKindOfClass:[ArxivNewArticleList class]]){
	return NO;
    }
    NSArray* a=[al.name componentsSeparatedByString:@"/"];
    if([a count]>1 && [a[1] hasPrefix:@"rep"]){
	return YES;
    }
    return NO;
}
-(void)addSimpleArticleListWithName:(NSString*)name
{
    SimpleArticleList* al=[SimpleArticleList createSimpleArticleListWithName:name inMOC:[MOC moc]];
    [sideOutlineViewController addArticleList:al];
}
-(void)addArxivArticleListWithName:(NSString*)name
{
    ArxivNewArticleList* al=[ArxivNewArticleList createArXivNewArticleListWithName:name inMOC:[MOC moc]];
    [sideOutlineViewController addArticleList:al];
}

-(NSWindow*)mainWindow
{
    return window;
}
-(void)querySPIRES:(NSString*)search
{
        [[OperationQueues spiresQueue] addOperation:[[SpiresQueryOperation alloc] initWithQuery:search andMOC:[MOC moc]]];
}


-(void)postMessage:(NSString*)message
{
    wv.message=message;
}
-(void)makeTableViewFirstResponder
{
    [window makeFirstResponder:articleListView];
}
-(void)makeSideViewFirstResponder
{
    [window makeFirstResponder:sideOutlineView];
}
-(void)addToTeXLog:(NSString*)s
{
    [texWatcherController addToLog:s];
}

-(void)presentFileSaveError
{
    NSAlert*alert=[[NSAlert alloc] init];
    alert.messageText=@"PDF Downloaded, but can't be saved???";
    [alert addButtonWithTitle:@"OK"];
    alert.informativeText=@"can't save the file. Please check if the folder to save PDFs is correctly set up.";
    [alert runModal];
    [self showPreferences:self];
}
#pragma mark PDF Association

-(void)showInfoOnAssociation
{
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"alreadyShownInfoOnAssociation"])
	return;
    
    NSAlert*alert=[[NSAlert alloc] init];
    alert.messageText=@"After you download a paper manually, ";
    [alert addButtonWithTitle:@"OK" ];
    alert.informativeText=@"register it to Spires.app by dropping the PDF into the lower pane. \nYou can move the PDF to anywhere afterwards, because Spires.app keeps track of it.";
    [alert setShowsSuppressionButton:YES];
    [alert beginSheetModalForWindow:window
                  completionHandler:^(NSModalResponse returnCode) {
        if ([[alert suppressionButton] state] == NSControlStateValueOn) {
                          [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"alreadyShownInfoOnAssociation"];
                      }
                  }
     ];
}


#pragma mark URL handling


-(void)handleURL:(NSURL*) url
{
//    NSLog(@"handles %@",url);
    if([[url scheme] isEqualTo:@"spires-search"]){
        NSString*searchString=[[[url absoluteString] substringFromIndex:[(NSString*)@"spires-search://" length]] stringByRemovingPercentEncoding];
	[sideOutlineViewController selectAllArticleList];
	AllArticleList*allArticleList=[AllArticleList allArticleList];
	if(![allArticleList.searchString isEqualToString:searchString]){
	    [historyController mark:self];
	}
	allArticleList.searchString=searchString;
	[historyController mark:self];
	[self querySPIRES:searchString];
    }else if([[url scheme] isEqualTo:@"spires-cancel"]){
        [self progressQuit:self];
    }else if([[url scheme] isEqualTo:@"spires-open-pdf-internal"]){
	[self openPDF:self];
    }else if([[url scheme] isEqualTo:@"spires-lookup-eprint"]){
	NSString*eprint=[[url absoluteString] extractArXivID];
	if(eprint){
	    NSString*searchString=[@"spires-search://eprint%20" stringByAppendingString:eprint];
	    [self performSelector:@selector(handleURL:) 
		       withObject:[NSURL URLWithString:searchString]
		       afterDelay:1];
	}	    
    }else if([[url scheme] isEqualTo:@"spires-get-bib-entry"]){
	[self getBibEntries:self];
    }else if([[url scheme] isEqualTo:@"spires-open-journal"]){
	[self openJournal:self];
    }else if([[url scheme] isEqualTo:@"http"] || [[url scheme] isEqualTo:@"https"]){
	[[NSWorkspace sharedWorkspace] openURL:url];
	if([[url path] rangeOfString:@"spires"].location==NSNotFound){
	    [self showInfoOnAssociation];
	}
    }else if([[url scheme] isEqualTo:@"file"]){
	Article*o=[ac selectedObjects][0];
	if(!o)
	    return;
	if([o isEprint]){
            NSAlert*alert=[[NSAlert alloc] init];
            alert.messageText=@"PDF association to an eprint";
            [alert addButtonWithTitle:@"Yes" ];
            [alert addButtonWithTitle:@"Cancel"];
            alert.informativeText=[NSString stringWithFormat:@"Do you prefer %@ instead of the eprint?", [[url path] stringByAbbreviatingWithTildeInPath]];
	    [alert beginSheetModalForWindow:window
                          completionHandler:^(NSModalResponse choice) {
                              if(choice==NSAlertFirstButtonReturn){
                                  [o associatePDF:url.path];
                                  [wv setArticle:o];
                              }
                          }
             ];
	}else if(o.hasPDFLocally){
            NSAlert*alert=[[NSAlert alloc] init];
            alert.messageText=@"PDF already associated";
            [alert addButtonWithTitle:@"Change" ];
            [alert addButtonWithTitle:@"Cancel"];
            alert.informativeText=[NSString stringWithFormat:@"PDF is already associated to this article. Do you want to change it with %@?", [[url path] stringByAbbreviatingWithTildeInPath]];
	    [alert beginSheetModalForWindow:window
                          completionHandler:^(NSModalResponse choice) {
                              if(choice==NSAlertFirstButtonReturn){
                                  [o associatePDF:url.path];
                                  [wv setArticle:o];
                              }
                          }
             ];
	}else{
	    [o associatePDF:[url path]];
            [wv setArticle:o];
	}
    }
}


#pragma mark QuickLook handling
- (BOOL)acceptsPreviewPanelControl:(QLPreviewPanel *)panel
{
    return YES;
}
- (void)beginPreviewPanelControl:(QLPreviewPanel *)panel
{
    [panel setDataSource:(id<QLPreviewPanelDataSource>)[PDFHelper sharedHelper]];
}
- (void)endPreviewPanelControl:(QLPreviewPanel *)panel
{
}
#pragma mark Service handling
-(void)handleServicesLookupSpires:(NSPasteboard*)pboard
			 userData:(NSString*)userData
			    error:(NSString**)error
{
    if([[pboard types] containsObject:NSPasteboardTypeString]){
        NSString* source=[pboard stringForType:NSPasteboardTypeString];
	[self handleURL:[NSURL URLWithString:[@"spires-lookup-eprint://PreviewHook/" stringByAppendingString:source]]];
    }
}
#pragma mark split view delegate
-(CGFloat)splitView:(NSSplitView *)splitView constrainMinCoordinate:(CGFloat)proposedMinimumPosition ofSubviewAt:(NSInteger)dividerIndex
{
    // I know I should get the height of the toolbar height dynamically, but I'm lazy today.
#define MIN_HEIGHT 100
    if(proposedMinimumPosition < MIN_HEIGHT)
        proposedMinimumPosition=MIN_HEIGHT;
    return proposedMinimumPosition;
}
#pragma mark WebView Delegate
-(void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    NSURL* url=navigationAction.request.URL;
    if([[url scheme] isEqualToString:@"about"]){
        decisionHandler(WKNavigationActionPolicyAllow);
    }else{
        if([[url absoluteString] hasPrefix:@"spires-search://c%20key%20"]
           ||
           [[url absoluteString] hasPrefix:@"spires-search://r%20key%20"]){
            NSString*query=[[[url absoluteString] stringByRemovingPercentEncoding] substringFromIndex:[@"spires-search://" length]];
            Article*a=[Article articleForQuery:query inMOC:[MOC moc]];
            // somehow somtimes a becomes nil at this point for a very old entry obtained from SPIRES long time ago. refreshing seems to do the job at the next query ...
            if(!a){
                NSLog(@"this entry %@ is too old for lookup refreshing...",query);
                [self reloadFromSPIRES:self];
            }
        }
	[self handleURL:url];
        decisionHandler(WKNavigationActionPolicyCancel);
    }
}
/*
- (NSArray *)webView:(WebView *)sender contextMenuItemsForElement:(NSDictionary *)element defaultMenuItems:(NSArray *)defaultMenuItems
{
    NSURL* url=element[WebElementLinkURLKey];
    if(url && [[url scheme] rangeOfString:@"open-pdf"].location!=NSNotFound){
	NSMenuItem* mi1=[[NSMenuItem alloc] initWithTitle:[@"Open in " stringByAppendingString:[[PDFHelper sharedHelper] displayNameForViewer:openWithPrimaryViewer]] action:@selector(openSelectionInPDFViewer:) keyEquivalent:@""];
	NSMenuItem* mi2=[[NSMenuItem alloc] initWithTitle:[@"Open in " stringByAppendingString:[[PDFHelper sharedHelper] displayNameForViewer:openWithSecondaryViewer]] action:@selector(openSelectionInSecondaryPDFViewer:) keyEquivalent:@""];
	return @[mi1, mi2];
    }
    return defaultMenuItems;
}
- (void)webView:(WebView *)sender willPerformDragSourceAction:(WebDragSourceAction)action fromPoint:(NSPoint)point withPasteboard:(NSPasteboard *)pasteboard
{
    if([[pasteboard types] containsObject:NSURLPboardType]){
	NSURL* url=[NSURL URLFromPasteboard:pasteboard];
	if([[url scheme] isEqualToString:@"spires-get-bib-entry"]){
	    [pasteboard declareTypes:@[NSStringPboardType]
			       owner:nil];
	    Article*a=[ac selectedObjects][0];
	    [pasteboard setString:[a IdForCitation]
			  forType:NSStringPboardType];
	}
    }
}

-(NSUInteger)webView:(WebView *)webView dragDestinationActionMaskForDraggingInfo:(id<NSDraggingInfo>)draggingInfo
{
    return WebDragDestinationActionAny;
}
 */
#pragma mark Default provided by templates


/**
    Returns the NSUndoManager for the application.  In this case, the manager
    returned is that of the managed object context for the application.
 */
 
- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window {
    return [[MOC moc] undoManager];
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
    [sideOutlineViewController detachFromMOC];


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
/*
                    NSInteger alertReturn = NSRunAlertPanel(nil, @"Could not save changes while quitting. Quit anyway?" , @"Quit anyway", @"Cancel", nil);
                    if (alertReturn == NSAlertAlternateReturn) {
                        reply = NSTerminateCancel;	
                    }
 */
                }
            }
        } 
        
        else {
            reply = NSTerminateCancel;
        }
    }
    return reply;
}

@end
