//
//  spires_AppDelegate_actions.m
//  spires
//
//  Created by Yuji on 12/8/09.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import "spires_AppDelegate.h"
#import "AppDelegate.h"
#import "spires_AppDelegate_actions.h"

#import "SpiresHelper.h"
#import "PDFHelper.h"
#import "ArxivNewCreateSheetHelper.h"

#import "ActivityMonitorController.h"
#import "PrefController.h"
#import "TeXWatcherController.h"
#import "HistoryController.h"
#import "SideOutlineViewController.h"
#import "BibViewController.h"
#import "ImporterController.h"

#import "MOC.h"
#import "Article.h"
#import "ArticleData.h"
#import "JournalEntry.h"
#import "ArticleList.h"
#import "SimpleArticleList.h"
#import "AllArticleList.h"
#import "ArxivNewArticleList.h"
#import "ArticleFolder.h"
#import "CannedSearch.h"

#import "DumbOperation.h"
#import "ArticleListReloadOperation.h"
#import "BatchBibQueryOperation.h"
#import "BibTeXKeyCopyOperation.h"
#import "SpiresQueryOperation.h"

#import "NSURL+libraryProxy.h"

@implementation spires_AppDelegate (actions)
-(NSNumber*)databaseSize
{
    NSDictionary* dict=[[NSFileManager defaultManager] attributesOfItemAtPath:[[MOC sharedMOCManager] dataFilePath] error:NULL];
    return [dict valueForKey:NSFileSize];
}
#pragma mark Binding
-(NSManagedObjectContext*)managedObjectContext
{
    return [MOC moc];
}

#pragma mark Actions
-(IBAction)turnOnOffLine:(id)sender
{
    BOOL state=[self isOnline];
    if(state){
	NSAlert*alert=[NSAlert alertWithMessageText:@"Do you want to go offline?"
				      defaultButton:@"Yes" 
				    alternateButton:@"No"
					otherButton:nil
			  informativeTextWithFormat:@"You can go online again from\n the menu spires:Turn online."];
	NSUInteger result=[alert runModal];
	if(result!=NSAlertDefaultReturn)
	    return;
    }
    [self setIsOnline:!state];
    
}

-(IBAction)progressQuit:(id)sender
{
    [OperationQueues cancelCurrentOperations];
}
-(IBAction)changeFont:(id)sender;
{
    [prefController changeFont:sender];
}
-(IBAction)setFontSize:(float)size
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
-(IBAction)showPreferences:(id)sender;
{
    if(!prefController){
	prefController=[[PrefController alloc]init];
    }    
    [prefController showWindow:sender];
}
-(IBAction)showhideActivityMonitor:(id)sender;
{
    [activityMonitorController showhide:sender];
}
-(IBAction)showTeXWatcher:(id)sender;
{
    [texWatcherController showhide:sender];
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
 [[MOC moc] undo];
 [self disableUndo];
 }
 -(IBAction)redo:(id)sender
 {
 [self enableUndo];
 [[MOC moc] redo];
 [self disableUndo];
 }*/
-(IBAction)dumpDebugInfo:(id)sender
{
    Article*a=[[ac selectedObjects] objectAtIndex:0];
    NSLog(@"%@",a);
    NSLog(@"%@",a.data);
    /*    for(Article*b in a.citedBy){
     NSLog(@"citedByEntry:%@",b);
     }*/
    //    NSLog(@"%@",a.abstract);
}
-(IBAction)addArticleList:(id)sender
{
    //    [self enableUndo];
    NSEntityDescription*entityDesc=[NSEntityDescription entityForName:@"SimpleArticleList" inManagedObjectContext:[MOC moc]];
    SimpleArticleList* al=[[SimpleArticleList alloc] initWithEntity:entityDesc insertIntoManagedObjectContext:[MOC moc]];
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
    if(!arxivNewCreateSheetHelper){
	arxivNewCreateSheetHelper=[[ArxivNewCreateSheetHelper alloc] init];
    }
    [arxivNewCreateSheetHelper run];
}
-(void)addArticleFolder:(id)sender
{
    ArticleFolder* al=[ArticleFolder articleFolderWithName:@"untitled" inMOC:[MOC moc]];
    [sideTableViewController addArticleList:al];
    [sideTableViewController rearrangePositionInViewForArticleLists];
}
-(void)addCannedSearch:(id)sender
{
    NSString*name=[[sideTableViewController currentArticleList] searchString];
    if(!name || [name isEqualToString:@""]){
	name=@"untitled";
    }
    CannedSearch* al=[CannedSearch cannedSearchWithName:name inMOC:[MOC moc]];
    al.searchString=[[sideTableViewController currentArticleList] searchString];
    al.sortDescriptors=[[sideTableViewController currentArticleList] sortDescriptors];
    [sideTableViewController addArticleList:al];
    [sideTableViewController rearrangePositionInViewForArticleLists];
}

-(void)deleteArticleList:(id)sender
{
    [sideTableViewController removeCurrentArticleList];
}

-(IBAction)sendBugReport:(id)sender
{
    NSString* version=[[[NSBundle mainBundle] infoDictionary] valueForKey:@"CFBundleVersion"];
    NSInteger entries=[[[AllArticleList allArticleList] articles] count];
    NSNumber* size=[self databaseSize];
    [[NSWorkspace sharedWorkspace]
     openURL:[NSURL URLWithString:
	      [[NSString stringWithFormat:
		@"mailto:yujitach@ias.edu?subject=spires.app Bugs/Suggestions for v.%@ (%d entries, %@ bytes)",
		version,entries,size]
	       stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]]];
}    

/*-(IBAction)installHook:(id)sender
 {
 NSString*pkg=[[NSBundle mainBundle] pathForResource:@"spiresHook" ofType:@"pkg"];
 //  NSLog(@"%@",pkg);
 [[NSWorkspace sharedWorkspace] openFile:pkg];
 }*/
-(IBAction)deletePDFForEntry:(id)sender
{
    Article*a=[[ac selectedObjects] objectAtIndex:0];
    if(!a.hasPDFLocally)
	return;
    NSAlert*alert=[NSAlert alertWithMessageText:@"Do you really want to remove PDF?"
				  defaultButton:@"Yes" 
				alternateButton:@"No"
				    otherButton:nil
		      informativeTextWithFormat:@"PDF will be moved to the trash."];
    NSUInteger result=[alert runModal];
    if(result!=NSAlertDefaultReturn)
	return;
    NSString*path=a.pdfPath;
    [[NSWorkspace sharedWorkspace] recycleURLs:[NSArray arrayWithObject:[NSURL fileURLWithPath:path]]
			     completionHandler:nil];
    [a setFlag:a.flag &(~AFHasPDF)];
    
}
-(IBAction)deleteEntry:(id)sender
{
    ArticleList* al=[sideTableViewController currentArticleList];
    if(!al){
	NSBeep(); 
	return;
    }
    NSArray*a=[ac selectedObjects];
    if([al isKindOfClass:[AllArticleList class]]){
	for(Article*x in a){
	    // deleting x should be enough when the delete rules are correctly set up in mom,
	    // but somehow it doesn't work! so I manually delete 'em...
	    [al removeArticlesObject:x];
	    ArticleData*d=x.data;
	    JournalEntry*j=x.journal;
	    [[MOC moc] deleteObject:d];
	    [[MOC moc] deleteObject:x];
	    [[MOC moc] deleteObject:j];
	}
    }else if([al isKindOfClass:[SimpleArticleList class]]){
	for(Article*x in a){
	    [al removeArticlesObject:x];
	}
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
    if(![self isOnline])
	return;
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
    [AllArticleList allArticleList].searchString=searchString;
    [sideTableViewController selectAllArticleList];
    [self querySPIRES: searchString];  // [self searchStringFromPredicate:filterPredicate]];
}
-(IBAction) reloadSelection:(id)sender
{
    Article*o=[ac selection];
    if(o==nil)return;
    [[NSApp appDelegate] startProgressIndicator];
    [historyController mark:self];
    NSString*eprint=[o valueForKey:@"eprint"];
    if(eprint && ![eprint isEqualToString:@""]){
	
	[self querySPIRES:[NSString stringWithFormat:@"eprint %@",[o valueForKey:@"eprint"]]]; 	
    }else{
	[self querySPIRES:[NSString stringWithFormat:@"spicite %@",[o valueForKey:@"spicite"]]];
    }
    [[NSApp appDelegate] stopProgressIndicator];
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
	[[OperationQueues arxivQueue] addOperation:[[ArticleListReloadOperation alloc] initWithArticleList:al]];
    }
    //    [al reload];
}
-(IBAction)reloadAllArticleList:(id)sender
{
    NSEntityDescription*authorEntity=[NSEntityDescription entityForName:@"ArxivNewArticleList" inManagedObjectContext:[MOC moc]];
    NSFetchRequest*req=[[NSFetchRequest alloc]init];
    [req setEntity:authorEntity];
    NSPredicate*pred=[NSPredicate predicateWithValue:YES];
    [req setPredicate:pred];
    NSError*error=nil;
    NSArray*a=[[MOC moc] executeFetchRequest:req error:&error];
    for(ArxivNewArticleList*l in a){
	[[OperationQueues arxivQueue] addOperation:[[ArticleListReloadOperation alloc] initWithArticleList:l]];
    }
}
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

-(IBAction)openPDForJournal:(id)sender
{
    if([[ac selectedObjects] count]==0)return;
    Article*a=[[ac selectedObjects] objectAtIndex:0];
    if(a.hasPDFLocally || (a.eprint && ![a.eprint isEqualToString:@""]) ){
	[self openPDF:sender];
    }else{
	[self openJournal:sender];
    }
}

-(IBAction)getBibEntriesWithoutDisplay:(id)sender
{
    NSArray*x=[ac selectedObjects];
    //    [NSThread detachNewThreadSelector:@selector(getBibEntriesMainWork:) toTarget:self withObject:x];
    [[OperationQueues spiresQueue] addOperation:[[BatchBibQueryOperation alloc]initWithArray:x]];
}
-(IBAction)getBibEntries:(id)sender
{
    [self getBibEntriesWithoutDisplay:sender];
    [bibViewController setArticles:[ac selectedObjects]];
    [bibViewController showWindow:sender];
}
-(IBAction)copyBibKeyToPasteboard:(id)sender
{
    NSMutableArray*notReady=[NSMutableArray array];
    NSOperation*op=[[BibTeXKeyCopyOperation alloc] initWithArticles:[ac selectedObjects]];
    for(Article*a in [ac selectedObjects]){
	if(!a.texKey || [a.texKey isEqualToString:@""]){
	    [notReady addObject:a];	    
	}
    }
    if([notReady count]>0){
	NSOperation*bb=[[BatchBibQueryOperation alloc]initWithArray:notReady];
	[[OperationQueues spiresQueue] addOperation:bb];
	[op addDependency:bb];
    }
    [[OperationQueues spiresQueue] addOperation:op];
}
-(IBAction)reloadFromSPIRES:(id)sender
{
    for(Article*article in [ac selectedObjects]){
	NSString* target=nil;
	if(article.articleType==ATEprint){
	    target=[@"eprint " stringByAppendingString:article.eprint];
	    //	    [[OperationQueues arxivQueue] addOperation:[[ArxivMetadataFetchOperation alloc] initWithArticle:article]];
	}else if(article.articleType==ATSpires){
	    target=[@"spicite " stringByAppendingString:article.spicite];	
	}else if(article.articleType==ATSpiresWithOnlyKey){
	    target=[@"key " stringByAppendingString:[article.spiresKey stringValue]];	
	}
	if(target){
	    [[OperationQueues spiresQueue] addOperation:[[SpiresQueryOperation alloc]initWithQuery:target 
											    andMOC:[MOC moc]]];
	}
    }
}
-(IBAction)toggleFlagged:(id)sender
{
    for(Article*article in [ac selectedObjects]){
	if(article.flag & AFIsFlagged){
	    [article setFlag:article.flag&~AFIsFlagged];
	}else{
	    [article setFlag:article.flag|AFIsFlagged];
	}
    }
}

/**
 Performs the save action for the application, which is to send the save:
 message to the application's managed object context.  Any encountered errors
 are presented to the user.
 */

- (IBAction) saveAction:(id)sender {
    
    NSError *error = nil;
    if (![[MOC moc] save:&error]) {
	[[MOC sharedMOCManager] presentMOCSaveError:error];
        [[NSApplication sharedApplication] presentError:error];
    }/*else if([self syncEnabled]){
      [self syncAction:self];
      }*/
}


#pragma mark Importer
/*-(IBAction)importSpiresXML:(id)sender
{
    NSOpenPanel*op=[NSOpenPanel openPanel];
    [op setCanChooseFiles:YES];
    [op setCanChooseDirectories:NO];
    [op setMessage:@"Choose the SPIRES XML files to import..."];
    [op setPrompt:@"Choose"];
    [op setAllowsMultipleSelection:YES];
    [op setAllowedFileTypes:[NSArray arrayWithObjects:@"spires_xml",nil]];
    NSInteger res=[op runModal];
    if(res==NSOKButton){
	if(!importerController){
	    importerController=[[ImporterController alloc] init];//WithAppDelegate:self];
	}
	[importerController import:[op filenames]];
    }
    
}*/

#pragma mark check consistency
-(NSArray*)managedObjectsOfEntityNamed:(NSString*)entityName matchingPredicate:(NSPredicate*)predicate
{
    NSEntityDescription*entity=[NSEntityDescription entityForName:entityName inManagedObjectContext:[MOC moc]];
    NSFetchRequest*req=[[NSFetchRequest alloc] init];
    [req setEntity:entity];
    [req setPredicate:predicate];
    NSError*error=nil;
    NSArray*a=[[MOC moc] executeFetchRequest:req error:&error];
    NSLog(@"%d %@(s) found",(int)[a count],entityName);
    return a;
}
-(IBAction)fixDataInconsistency:(id)sender;
{
    {
	NSAlert*alert=[NSAlert alertWithMessageText:@"Check consistency and fix"
				      defaultButton:@"OK" 
				    alternateButton:@"Cancel"
					otherButton:nil
			  informativeTextWithFormat:@"The check and fix will take some time (~1min). Do you want to proceed?"];
	NSInteger result=[alert runModal];
	if(result!=NSAlertDefaultReturn)
	    return;
    }
    
    NSMutableArray*badGuys=[NSMutableArray array];

    [badGuys addObjectsFromArray:[self managedObjectsOfEntityNamed:@"Article" 
						 matchingPredicate:[NSPredicate predicateWithFormat:@"(not (self in %@)) || data == nil",[AllArticleList allArticleList].articles]]];
    [badGuys addObjectsFromArray:[self managedObjectsOfEntityNamed:@"ArticleData"
						 matchingPredicate:[NSPredicate predicateWithFormat:@"article == nil"]]];
    [badGuys addObjectsFromArray:[self managedObjectsOfEntityNamed:@"JournalEntry"
						 matchingPredicate:[NSPredicate predicateWithFormat:@"article == nil"]]];
    
    NSString*message=nil;
    if([badGuys count]>0){
	// "fixed" in the message below is a euphemism for "just deleted".
	message=[NSString stringWithFormat:@"%d problematic entries were fixed.",(int)[badGuys count]];
	for(NSManagedObject*obj in badGuys){
	    [[MOC moc] deleteObject:obj];
	}
	[self saveAction:self];
    }else{
	message=@"No problem found.";
    }
    {
	NSAlert*alert=[NSAlert alertWithMessageText:@"Consistency checked."
				      defaultButton:@"Vacuum" 
				    alternateButton:@"Cancel"
					otherButton:nil
			  informativeTextWithFormat:[message stringByAppendingString:
						     @" Do you proceed to vacuum-clean the database?" 
						     @" It will again take some time and you need to wait patiently."
						     @" The app relaunches itself after the cleanup."]];
	NSInteger result=[alert runModal];
	if(result==NSAlertDefaultReturn){
	    [self saveAction:self];
	    NSNumber*before=[self databaseSize];
	    [[MOC sharedMOCManager] vacuum];
	    [sideTableViewController selectAllArticleList];
	    NSNumber*after=[self databaseSize];
	    alert=[NSAlert alertWithMessageText:@"Done."
				  defaultButton:@"Relaunch" 
				alternateButton:nil
				    otherButton:nil
		      informativeTextWithFormat:[NSString stringWithFormat:@"%@ bytes --> %@ bytes",before,after]];
	    [alert runModal];
	    [self relaunch];
	}
    }
}



@end
