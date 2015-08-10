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

#import "HistoryController.h"

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


#import <Quartz/Quartz.h>


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
    
    NSArray* annualReviewJournals=defaultDict[@"AnnualReviewJournals"];
    NSArray* elsevierJournals=defaultDict[@"ElsevierJournals"];
    NSArray* apsJournals=defaultDict[@"APSJournals"];
    NSArray* aipJournals=defaultDict[@"AIPJournals"];
    NSArray* iopJournals=defaultDict[@"IOPJournals"];
    NSArray* springerJournals=defaultDict[@"SpringerJournals"];
    NSArray* wsJournals=defaultDict[@"WSJournals"];
    NSArray* ptpJournals=defaultDict[@"PTPJournals"];
    NSMutableArray* knownJournals=[NSMutableArray array ];
    [knownJournals addObjectsFromArray:annualReviewJournals];
    [knownJournals addObjectsFromArray:elsevierJournals];
    [knownJournals addObjectsFromArray:apsJournals];
    [knownJournals addObjectsFromArray:aipJournals];
    [knownJournals addObjectsFromArray:iopJournals];
    [knownJournals addObjectsFromArray:springerJournals];
    [knownJournals addObjectsFromArray:wsJournals];
    [knownJournals addObjectsFromArray:ptpJournals];
    defaultDict[@"KnownJournals"] = knownJournals;
    
    
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
	    [[OperationQueues sharedQueue] addOperation:[[TeXBibGenerationOperation alloc] initWithTeXFile:path
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


#pragma mark UI glues

-(void)awakeFromNib
{
    
    
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
    
    NSTimeInterval grace=[[NSUserDefaults standardUserDefaults] floatForKey:@"arXivAutoQueryWaitInSeconds"];
    if(grace<3.0)
        grace=3.0;
    
    [NSTimer scheduledTimerWithTimeInterval:grace target:self selector:@selector(timerForAbstractFired:) userInfo:nil repeats:YES];
    [searchField setProgressQuitAction:@selector(progressQuit:)];

}

-(void)setupServices
{
    [NSApp setServicesProvider: self];
    NSUpdateDynamicServices();
    
}
-(BOOL)showWelcome
{
    NSString*welcome=@"v1.6.0alert";
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
-(void)safariExtensionRecommendation
{
    NSString*defaultBrowserBundleID=(__bridge_transfer NSString*)LSCopyDefaultHandlerForURLScheme((__bridge CFStringRef)@"http");
    if(![[defaultBrowserBundleID lowercaseString] isEqualToString:@"com.apple.safari"]){
        return;
    }
    if(![[OperationQueues arxivQueue] isOnline]){
        return;
    }
    NSString*key=@"safariExtensionRecommendationShown3";
    if(![[NSUserDefaults standardUserDefaults] boolForKey:key]){
	[[NSUserDefaults standardUserDefaults] setBool:YES forKey:key];
	NSAlert*alert=[NSAlert alertWithMessageText:@"Do you want to install a Safari Extension?"
				      defaultButton:@"Yes" 
				    alternateButton:@"No"
					otherButton:nil
			  informativeTextWithFormat:@"This extension makes Safari typeset the pseudo-TeX code in the abstract of the arxiv pages just as this app does. You can install it later from the menu spires→Install Safari extension.\nIf you have already installed it before 2013, please do it again. It should automatically update afterwards."];
	NSUInteger result=[alert runModal];
	if(result!=NSAlertDefaultReturn)
	    return;
	[self installSafariExtension:self];
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
        NSAlert*alert=[NSAlert alertWithMessageText:@"Optimizing database"
                                      defaultButton:@"Start Optimization"
                                    alternateButton:nil
                                        otherButton:nil informativeTextWithFormat:
                       @"The app is going to optimize the database. Usually it's quick, but it might take a very long time. So please be patient. The app will not explicitly tell you when the optimization is done. Consider it done when the app becomes usable."];
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
        [[MOC moc] performBlock:^{
            NSError*e;
            [[MOC moc] save:&e];
        }];
    }];
}
-(void)tweakTableViewFonts
{
    if([NSFont respondsToSelector:@selector(monospacedDigitSystemFontOfSize:weight:)]){
        for(NSTableColumn*col in [articleListView tableColumns]){
            NSString*title=col.title;
            if([title isEqualToString:@"eprint"]||[title isEqualToString:@"cites"]){
                NSTextFieldCell*cell=(NSTextFieldCell*)col.dataCell;
                cell.font=[NSFont monospacedDigitSystemFontOfSize:[NSFont systemFontSize] weight:NSFontWeightRegular];                
            }
        }
    }
}
-(void)applicationDidFinishLaunching:(NSNotification*)notification
{
    
    [self setupServices];
    [self crashCheck:self];
    if(![self showWelcome]){
        [self safariExtensionRecommendation];
    }

    [sideOutlineViewController loadArticleLists];
    [sideOutlineViewController attachToMOC];
    
    [self tweakTableViewFonts];
    
    if([NSEvent modifierFlags]&NSAlternateKeyMask){
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
    
    [sideOutlineViewController performSelector:@selector(selectAllArticleList) withObject:nil afterDelay:0];
    [self performSelector:@selector(makeTableViewFirstResponder) withObject:nil afterDelay:0];
    prefController=[[PrefController alloc]init];
    activityMonitorController=[[ActivityMonitorController alloc] init];
    texWatcherController=[[TeXWatcherController alloc]init];
    bibViewController=[[BibViewController alloc] init];

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
	    [wv setArticle:NSNoSelectionMarker];
	}else if([a count]>1){
	    [wv setArticle:NSMultipleValuesMarker];
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
		    
	    }
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
	[window setTitle:[NSString stringWithFormat:@"%@ (%@)",head,howmany]];
    }
}

#pragma mark Timers
-(void)clearUnreadFlagOfArticle:(NSTimer*)timer
{
    Article*a=[timer userInfo];
    [a setFlag:[a flag]&(~AFIsUnread)];
    unreadTimer=nil;
}


-(void)timerForAbstractFired:(NSTimer*)t
{
    NSArray*arr=[ac selectedObjects];
    if(!arr)return;
    if([arr count]==0)return;
    Article*a=arr[0];

    
    if(a.abstract && ![a.abstract isEqualToString:@""]){
	NSArray* aaa=[ac arrangedObjects];
	if(!aaa || [aaa count]==0) return;
	int threshold=(int)[[NSUserDefaults standardUserDefaults] integerForKey:@"eagerMetadataQueryThreshold"];
	int j=(int)[aaa indexOfObject:a];
	int i;
	for(i=j;i<(int)[aaa count] && i<j+threshold ;i++){
	    a=aaa[i];
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
   
        if(a.abstract && ![a.abstract isEqualToString:@""]){
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

    
	if(a.eprint && ![a.eprint isEqualToString:@""]){
	    [[OperationQueues arxivQueue] addOperation:[[ArxivMetadataFetchOperation alloc] initWithArticle:a]];
	}else if(a.doi && ![a.doi isEqualToString:@""]){
            if(!a.doi || [a.doi isEqualToString:@""]) return;
            NSArray* knownJournals=[[NSUserDefaults standardUserDefaults] arrayForKey:@"KnownJournals"];
            if(![knownJournals containsObject:a.journal.name]){
                return;
            }
            [[OperationQueues spiresQueue] addOperation:[[LoadAbstractDOIOperation alloc] initWithArticle:a]];
	}
	
	if(!a.texKey || [a.texKey isEqualToString:@""]){
	    //	[[DumbOperationQueue spiresQueue] addOperation:[[BatchBibQueryOperation alloc]initWithArray:[NSArray arrayWithObject:a]]];
	    //	[self getBibEntriesWithoutDisplay:self];
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

-(void)clearingUpAfterRegistration:(id)sender
{
    if([[ac arrangedObjects] count]>0 && [[ac selectedObjects] count]==0){
//	[ac setSelectionIndex:0];
    }
    
//    [ac didChangeArrangementCriteria];
//    [self makeTableViewFirstResponder];
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
-(void)reassociationAlertWithPathGivenDidEnd:(NSAlert*)alert code:(int)choice context:(CFStringRef)cfpath
{
    NSString*path=(__bridge_transfer NSString*)cfpath;
    if(choice==NSAlertDefaultReturn){
	Article*o=[ac selectedObjects][0];
	[o associatePDF:path];
    }
}

- (void) infoAlertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo
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
	for(NSString*cat in @[@"hep-th",@"hep-ph",@"hep-ex",@"hep-lat",@"astro-ph",@"math-ph",@"math"]){
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
	[[NSWorkspace sharedWorkspace] openURL:url];
	if([[url path] rangeOfString:@"spires"].location==NSNotFound){
	    [self showInfoOnAssociation];
	}
    }else if([[url scheme] isEqualTo:@"file"]){
	Article*o=[ac selectedObjects][0];
	if(!o)
	    return;
	if([o isEprint]){
	    NSAlert*alert=[NSAlert alertWithMessageText:@"PDF association to an eprint"
					  defaultButton:@"Yes" 
					alternateButton:@"Cancel"
					    otherButton:nil
			      informativeTextWithFormat:@"Do you prefer %@ instead of the eprint?", [[url path] stringByAbbreviatingWithTildeInPath]];
	    [alert beginSheetModalForWindow:window
			      modalDelegate:self 
			     didEndSelector:@selector(reassociationAlertWithPathGivenDidEnd:code:context:)
				contextInfo:(void*)(__bridge_retained CFStringRef)([url path])];
	}else if(o.hasPDFLocally){
	    NSAlert*alert=[NSAlert alertWithMessageText:@"PDF already associated"
					  defaultButton:@"Change" 
					alternateButton:@"Cancel"
					    otherButton:nil
			      informativeTextWithFormat:@"PDF is already associated to this article. Do you want to change it with %@?", [[url path] stringByAbbreviatingWithTildeInPath]];
	    [alert beginSheetModalForWindow:window
			      modalDelegate:self 
			     didEndSelector:@selector(reassociationAlertWithPathGivenDidEnd:code:context:)
				contextInfo:(void*)(__bridge_retained CFStringRef)([url path])];
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
	[listener ignore];
    }
}
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

@end
