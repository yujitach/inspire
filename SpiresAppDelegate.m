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

#import "Article.h"
#import "JournalEntry.h"

#import "SpiresHelper.h"

#import "AllArticleList.h"
#import "ArxivNewArticleList.h"
#import "SimpleArticleList.h"

#import "ArticleView.h"

#import "SideOutlineViewController.h"

#import "HistoryController.h"

#import "IncrementalArrayController.h"
#import "MessageViewerController.h"
#import "ActivityMonitorController.h"
#import "TeXWatcherController.h"
#import "BibViewController.h"
#import "PrefController.h"

#import "PDFHelper.h"
#import "ProgressIndicatorController.h"

#import "SpiresQueryOperation.h"
#import "TeXBibGenerationOperation.h"
#import "BatchBibQueryOperation.h"
#import "LoadAbstractDOIOperation.h"
#import "ArxivMetadataFetchOperation.h"

#import "SPSearchFieldWithProgressIndicator.h"

#import <Sparkle/SUUpdater.h>
#import <Quartz/Quartz.h>
//#import <ExceptionHandling/NSExceptionHandler.h>

#define TICK (.5)
#define GRACEMIN (3.0/TICK)
#define GRACE ([[NSUserDefaults standardUserDefaults] floatForKey:@"arXivWaitInSeconds"]/TICK)

@interface SpiresAppDelegate (Timers)
-(void)timerForAbstractFired:(NSTimer*)t;
-(void)clearUnreadFlagOfArticle:(NSTimer*)timer;
@end

@implementation SpiresAppDelegate
+(void)initialize
{
    if(self!=[SpiresAppDelegate class]){
	return;
    }
    NSData* data=[NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"defaults" ofType:@"plist"]];
    NSError* error=nil;
    NSPropertyListFormat format;
    NSMutableDictionary* defaultDict=[NSPropertyListSerialization propertyListWithData:data options:NSPropertyListMutableContainersAndLeaves format:&format error:&error];

    //sythesize the list of all known journals
    
    NSArray* annualReviewJournals=[defaultDict objectForKey:@"AnnualReviewJournals"];
    NSArray* elsevierJournals=[defaultDict objectForKey:@"ElsevierJournals"];
    NSArray* apsJournals=[defaultDict objectForKey:@"APSJournals"];
    NSArray* aipJournals=[defaultDict objectForKey:@"AIPJournals"];
    NSArray* iopJournals=[defaultDict objectForKey:@"IOPJournals"];
    NSArray* springerJournals=[defaultDict objectForKey:@"SpringerJournals"];
    NSArray* wsJournals=[defaultDict objectForKey:@"WSJournals"];
    NSArray* ptpJournals=[defaultDict objectForKey:@"PTPJournals"];
    NSMutableArray* knownJournals=[NSMutableArray array ];
    [knownJournals addObjectsFromArray:annualReviewJournals];
    [knownJournals addObjectsFromArray:elsevierJournals];
    [knownJournals addObjectsFromArray:apsJournals];
    [knownJournals addObjectsFromArray:aipJournals];
    [knownJournals addObjectsFromArray:iopJournals];
    [knownJournals addObjectsFromArray:springerJournals];
    [knownJournals addObjectsFromArray:wsJournals];
    [knownJournals addObjectsFromArray:ptpJournals];
    [defaultDict setObject:knownJournals forKey:@"KnownJournals"];
    
    
    [[NSUserDefaults standardUserDefaults] registerDefaults: defaultDict];
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
	    [[OperationQueues spiresQueue] addOperation:[[TeXBibGenerationOperation alloc] initWithTeXFile:path
												    andMOC:[MOC moc] byLookingUpWeb:YES]];
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
    [fm createDirectoryAtPath:@"/tmp/SpiresCrashReport" withIntermediateDirectories:YES attributes:nil error:NULL];
    [fm copyItemAtPath:path 
		toPath:[@"/tmp/SpiresCrashReport/" stringByAppendingString:[path lastPathComponent]] 
		 error:NULL];
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

#pragma mark UI glues
-(void)checkOSVersion
{   // This routine was to urge update to 10.5.7 which fixed NSOperationQueue bug
    // but is used to urge users whenever a new minor version of OS X comes out!
    SInt32 major=10,minor=5,bugFix=6;
    Gestalt(gestaltSystemVersionMajor, &major);
    Gestalt(gestaltSystemVersionMinor, &minor);
    Gestalt(gestaltSystemVersionBugFix, &bugFix);
    NSLog(@"OS version:%d.%d.%d",(int)major,(int)minor,(int)bugFix);
    if(minor == 6 && bugFix<5){
	NSLog(@"OS update should be available...");
	[[NSWorkspace sharedWorkspace] launchApplicationAtURL:[NSURL fileURLWithPath:@"/System/Library/CoreServices/Software Update.app"]
						      options:NSWorkspaceLaunchWithoutActivation
						configuration:nil
							error:NULL];
    }
}
-(void)awakeFromNib
{
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"UpdaterWillFollowUnstableVersions"]){
	[[SUUpdater sharedUpdater] setFeedURL:[NSURL URLWithString:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"SUFeedURL-Unstable"]]];	
    }

//    [[NSExceptionHandler defaultExceptionHandler] setDelegate:self];
//    [[NSExceptionHandler defaultExceptionHandler] setExceptionHandlingMask:NSHandleTopLevelExceptionMask|NSHandleOtherExceptionMask];
    
    
    for(NSToolbarItem*ti in [tb items]){
	if([[ti  label] isEqualToString:@"Search Field"]){
	    NSSize s=[ti minSize];
	    s.width=10000;
	    [ti setMaxSize:s];
	}
    }
    
    
    [ac addObserver:self
	 forKeyPath:@"selection"
	    options:NSKeyValueObservingOptionNew//|NSKeyValueObservingOptionInitial
	    context:nil];

    [ac addObserver:self
	 forKeyPath:@"arrangedObjects"
	    options:NSKeyValueObservingOptionNew//|NSKeyValueObservingOptionInitial
	    context:nil];
    
    
    [NSTimer scheduledTimerWithTimeInterval:TICK target:self selector:@selector(timerForAbstractFired:) userInfo:nil repeats:YES];
    countDown=0;
    [searchField setProgressQuitAction:@selector(progressQuit:)];

    prefController=[[PrefController alloc]init];
    activityMonitorController=[[ActivityMonitorController alloc] init];
    texWatcherController=[[TeXWatcherController alloc]init];
    bibViewController=[[BibViewController alloc] init];
}

-(void)setupServices
{
    [NSApp setServicesProvider: self];
    NSUpdateDynamicServices();
    
//    Now it's done in an Apple approved way, see Snow Leopard AppKit Release Notes and look for NSRequiredContext.
//    But for "safety" I keep the following code intact... 
    // Force enable the Spires... entry in the Services menu and the context menu.
    // This is not morally right, and uses implementation details not public, but whatever...
    // when someone complains, I would implement an opt-out button in the Preferences.
    NSString*pbsPlistPath=[@"~/Library/Preferences/pbs.plist" stringByExpandingTildeInPath];
    NSMutableDictionary*dict=[NSPropertyListSerialization propertyListFromData:[NSData dataWithContentsOfFile:pbsPlistPath]
							      mutabilityOption:NSPropertyListMutableContainers
									format:NULL
							      errorDescription:NULL];
    NSMutableDictionary*status=[dict objectForKey:@"NSServicesStatus"];
    if(!status){
	status=[NSMutableDictionary dictionary];
	[dict setObject:status forKey:@"NSServicesStatus"];
    }
    if(status){
	NSMutableDictionary*m=[NSMutableDictionary dictionary];
	[m setObject:[NSNumber numberWithBool:YES] forKey:@"enabled_context_menu"];
	[m setObject:[NSNumber numberWithBool:YES] forKey:@"enabled_services_menu"];
	[status setObject:m
		   forKey:@"com.yujitach.spires - Look Up using Spires - handleServicesLookupSpires"];
    }
    NSData* data=[NSPropertyListSerialization dataWithPropertyList:dict
							    format:NSPropertyListBinaryFormat_v1_0
							   options:0
							     error:NULL];
    [data writeToFile:pbsPlistPath
	   atomically:YES];
    system("/System/Library/CoreServices/pbs -flush");
    system("/System/Library/CoreServices/pbs -flush_userdefs");
    
}
-(void)showWelcome
{
    NSString*welcome=@"v1.4alert";
    NSString*key=[welcome stringByAppendingString:@"Shown"];
    if(![[NSUserDefaults standardUserDefaults] boolForKey:key]){
	messageViewerController=[[MessageViewerController alloc] initWithRTF:[[NSBundle mainBundle] pathForResource:welcome ofType:@"rtf"]];
	// this window controller shows itself automatically!
	[[NSUserDefaults standardUserDefaults] setBool:YES forKey:key];
    }    
}
-(void)safariExtensionRecommendation
{
    NSString*key=@"safariExtensionRecommendationShown";
    if(![[NSUserDefaults standardUserDefaults] boolForKey:key]){
	[[NSUserDefaults standardUserDefaults] setBool:YES forKey:key];	
	NSAlert*alert=[NSAlert alertWithMessageText:@"Do you want to install a Safari Extension?"
				      defaultButton:@"Yes" 
				    alternateButton:@"No"
					otherButton:nil
			  informativeTextWithFormat:@"This extension makes Safari typeset the pseudo-TeX code in the abstract of the arxiv pages just as this app does. You can install it later from the menu spires→Install Safari extension."];
	NSUInteger result=[alert runModal];
	if(result!=NSAlertDefaultReturn)
	    return;
	[self installSafariExtension:self];
    }    
}
-(void)applicationDidFinishLaunching:(NSNotification*)notification
{
    
    [self setupServices];
    [self checkOSVersion];

    [self crashCheck:self];
    if(![self isOnline]){
	NSAlert*alert=[NSAlert alertWithMessageText:@"You're in the Offline mode."
				      defaultButton:@"OK" 
				    alternateButton:nil
					otherButton:nil
			  informativeTextWithFormat:@"You can go online again from\n the menu spires:Turn online."];
	[alert runModal];
    }
    [self showWelcome];
    [self safariExtensionRecommendation];
    // This lock is to wait until the warm-up in the background is done.
    [[MOC moc] lock];
    [MOC sharedMOCManager].isUIready=YES;
    [[MOC moc] unlock];

    // attachToMOC attaches the MOC to the UI.
//    if(!([NSEvent modifierFlags]&NSAlternateKeyMask)){
    [sideOutlineViewController attachToMOC];
//   }
    [sideOutlineViewController loadArticleLists];
    if([NSEvent modifierFlags]&NSAlternateKeyMask){
	[AllArticleList allArticleList].searchString=nil;
    }
    [window makeKeyAndOrderFront:self];
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
	    if(ar.flag & AFIsUnread){
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
	NSInteger num=[[ac arrangedObjects] count];
	NSString*head=@"spires";
	ArticleList*al=[sideOutlineViewController currentArticleList];
	if(al){
	    head=al.name;
	}
	[window setTitle:[NSString stringWithFormat:@"%@ (%d %@)",head,num,(num==1?@"entry":@"entries")]];
    }
}

#pragma mark Timers
-(void)clearUnreadFlagOfArticle:(NSTimer*)timer
{
    Article*a=[timer userInfo];
    [a setFlag:[a flag]&(~AFIsUnread)];
    unreadTimer=nil;
}

-(void)loadAbstractUsingDOI:(Article*)a
{
    if(!a.doi || [a.doi isEqualToString:@""]) return;
    NSArray* knownJournals=[[NSUserDefaults standardUserDefaults] arrayForKey:@"KnownJournals"];
    if(![knownJournals containsObject:a.journal.name]){
	return;
    }
    // prevent lots of access to the same article when the abstract loading fails 
    {
	if(!articlesAlreadyAccessedViaDOI){
	    articlesAlreadyAccessedViaDOI=[NSMutableArray array];
	}
	if([articlesAlreadyAccessedViaDOI count]>1000){
	    articlesAlreadyAccessedViaDOI=[NSMutableArray array];	
	}
	if([articlesAlreadyAccessedViaDOI containsObject:a]){
	    return;
	}
	[articlesAlreadyAccessedViaDOI addObject:a];
    }
    [[OperationQueues sharedQueue] addOperation:[[LoadAbstractDOIOperation alloc] initWithArticle:a]];
}

-(void)timerForAbstractFired:(NSTimer*)t
{
    if(countDown>0){
	countDown--;
	return;
    }
    NSArray*arr=[ac selectedObjects];
    if(!arr)return;
    if([arr count]==0)return;
    Article*a=[arr objectAtIndex:0];
    
    
    if(a.abstract && ![a.abstract isEqualToString:@""]){
	NSArray* aaa=[ac arrangedObjects];
	if(!aaa || [aaa count]==0) return;
	int threshold=(int)[[NSUserDefaults standardUserDefaults] integerForKey:@"eagerMetadataQueryThreshold"];
	int j=(int)[aaa indexOfObject:a];
	int i;
	for(i=j;i<(int)[aaa count] && i<j+threshold ;i++){
	    a=[aaa objectAtIndex:i];
	    if(!a.eprint && !a.doi)
		continue;
	    if(!a.abstract || [a.abstract isEqualToString:@""])
		break;
	}
	if(i==(int)[aaa count]||i==j+threshold)
	    return;
	if(!a)
	    return;
    }
    
    if([self isOnline]){
	if(a.eprint && ![a.eprint isEqualToString:@""]){
	    [[OperationQueues arxivQueue] addOperation:[[ArxivMetadataFetchOperation alloc] initWithArticle:a]];
	}else if(a.doi && ![a.doi isEqualToString:@""]){
	    [self loadAbstractUsingDOI:a];
	}
	
	if(!a.texKey || [a.texKey isEqualToString:@""]){
	    //	[[DumbOperationQueue spiresQueue] addOperation:[[BatchBibQueryOperation alloc]initWithArray:[NSArray arrayWithObject:a]]];
	    //	[self getBibEntriesWithoutDisplay:self];
	}
    }
    countDown=(int)GRACE;
    if(countDown<GRACEMIN){
	countDown=(int)GRACEMIN;
    }
}


#pragma mark Public Interfaces

-(BOOL)useInspire
{
    NSString*database=[[NSUserDefaults standardUserDefaults] stringForKey:@"databaseToUse"];
    return [database isEqualToString:@"inspire"];
}

-(BOOL)currentListIsArxivReplaced
{
    ArticleList*al=[sideOutlineViewController currentArticleList];
    if(![al isKindOfClass:[ArxivNewArticleList class]]){
	return NO;
    }
    NSArray* a=[al.name componentsSeparatedByString:@"/"];
    if([a count]>1 && [[a objectAtIndex:1] hasPrefix:@"rep"]){
	return YES;
    }
    return NO;
}
-(void)addSimpleArticleListWithName:(NSString*)name;
{
    SimpleArticleList* al=[SimpleArticleList createSimpleArticleListWithName:name inMOC:[MOC moc]];
    [sideOutlineViewController addArticleList:al];
}
-(void)addArxivArticleListWithName:(NSString*)name;
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
    if([self isOnline]){
	[[OperationQueues spiresQueue] addOperation:[[SpiresQueryOperation alloc] initWithQuery:search
											 andMOC:[MOC moc]]];
    }else{
	NSLog(@"it's offline!");
    }
}
/*-(void)startUpdatingMainView:(id)sender
 {
 ac.refuseFiltering=NO;
 }
 -(void)stopUpdatingMainView:(id)sender
 {
 ac.refuseFiltering=YES;
 }*/
-(void)clearingUpAfterRegistration:(id)sender
{
    if([[ac arrangedObjects] count]>0 && [[ac selectedObjects] count]==0){
	[ac setSelectionIndex:0];
    }
    
    [ac didChangeArrangementCriteria];    
}

-(void)postMessage:(NSString*)message
{
    wv.message=message;
}
-(void)makeTableViewFirstResponder
{
    [window makeFirstResponder:articleListView];
}
-(void)startProgressIndicator
{
    [[ProgressIndicatorController sharedController] startAnimation:self];
}
-(void)stopProgressIndicator
{
    [[ProgressIndicatorController sharedController] stopAnimation:self];
}
-(void)addToTeXLog:(NSString*)s
{
    [texWatcherController addToLog:s];
}
-(void)relaunch
{
    NSString*path=[[NSBundle mainBundle] pathForResource:@"SpiresRelaunchHelper" 
						  ofType:@""];
    NSArray*arguments=[NSArray arrayWithObjects:
		       @"spires",
		       [NSString stringWithFormat:@"%d",[[NSProcessInfo processInfo] processIdentifier]],
		       nil];
    [NSTask launchedTaskWithLaunchPath:path arguments:arguments];
    [NSApp terminate:self];
}
@dynamic isOnline;
-(void)setIsOnline:(BOOL)b
{
    [[NSUserDefaults standardUserDefaults] setBool:b forKey:@"isOnline"];
    if(b){
	[[NSUserDefaults standardUserDefaults] setValue:NSLocalizedString(@"Turn Offline",@"Turn Offline")
						 forKey:@"turnOnOfflineMenuItem"];
    }else{
	[[NSUserDefaults standardUserDefaults] setValue:NSLocalizedString(@"Turn Online",@"Turn Online")
						 forKey:@"turnOnOfflineMenuItem"];	
    }
}
-(BOOL)isOnline
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"isOnline"];
}
-(void)presentFileSaveError
{
    NSAlert*alert=[NSAlert alertWithMessageText:@"PDF Downloaded, but can't be saved???"
				  defaultButton:@"OK" 
				alternateButton:nil
				    otherButton:nil
		      informativeTextWithFormat:@"can't save the file. Please check if the folder to save PDFs is correctly set up."];
    [alert runModal];
    [self showPreferences:self];
}
#pragma mark PDF Association
-(void)reassociationAlertWithPathGivenDidEnd:(NSAlert*)alert code:(int)choice context:(NSString*)path
{
    if(choice==NSAlertDefaultReturn){
	Article*o=[[ac selectedObjects]objectAtIndex:0];
	[o associatePDF:path];
    }
}

- (void) infoAlertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo;
{
    if ([[alert suppressionButton] state] == NSOnState) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"alreadyShownInfoOnAssociation"];
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
	for(NSString*cat in [NSArray arrayWithObjects:@"hep-th",@"hep-ph",@"hep-ex",@"hep-lat",@"astro-ph",@"math-ph",@"math",nil]){
	    if([x rangeOfString:cat].location!=NSNotFound){
		d=[NSString stringWithFormat:@"%@/%@",cat,d];
		break;
	    }
	}
	return d;
    }
    else return nil;
}

-(void)handleURL:(NSURL*) url
{
//    NSLog(@"handles %@",url);
    if([[url scheme] isEqualTo:@"spires-search"]){
	NSString*searchString=[[[url absoluteString] substringFromIndex:[(NSString*)@"spires-search://" length]] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	[sideOutlineViewController selectAllArticleList];
	AllArticleList*allArticleList=[AllArticleList allArticleList];
	if(![allArticleList.searchString isEqualToString:searchString]){
	    [historyController mark:self];
	}
	allArticleList.searchString=searchString;
	[historyController mark:self];
	[self querySPIRES:searchString];
    }else if([[url scheme] isEqualTo:@"spires-open-pdf-internal"]){
	[self openPDF:self];
    }else if([[url scheme] isEqualTo:@"spires-lookup-eprint"]){
	NSString*eprint=[self extractArXivID:[url absoluteString]];
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
    }else if([[url scheme] isEqualTo:@"http"]){
	/*
	if([[url host] hasSuffix:@"arxiv.org"]||[[url host] hasSuffix:@"arXiv.org"]){
	    if([[NSFileManager defaultManager] fileExistsAtPath:@"/Library/InputManagers/spiresHook"]){
		url=[NSURL URLWithString:[[url absoluteString] stringByAppendingString:@"?doNotCallSpiresHook"]];
	    }
	}
	 */
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
    if([[pboard types] containsObject:NSStringPboardType]){
	NSString* source=[pboard stringForType:NSStringPboardType];
	[self handleURL:[NSURL URLWithString:[@"spires-lookup-eprint://PreviewHook/" stringByAppendingString:source]]];
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
					
                    NSInteger alertReturn = NSRunAlertPanel(nil, @"Could not save changes while quitting. Quit anyway?" , @"Quit anyway", @"Cancel", nil);
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
    return reply;
}

/* #pragma mark exception

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
