//
//  spires_AppDelegate_actions.m
//  spires
//
//  Created by Yuji on 12/8/09.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import "SpiresAppDelegate.h"
#import "AppDelegate.h"
#import "SpiresAppDelegate_actions.h"

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
#import "BatchBibQueryOperation.h"
#import "BibTeXKeyCopyOperation.h"
#import "SpiresQueryOperation.h"

#import "NSURL+libraryProxy.h"

#import "NSString+magic.h"


@implementation SpiresAppDelegate (actions)
-(NSNumber*)databaseSize
{
    NSDictionary* dict=[[NSFileManager defaultManager] attributesOfItemAtPath:[[MOC sharedMOCManager] dataFilePath] error:NULL];
    return [dict valueForKey:NSFileSize];
}

#pragma mark Actions
-(IBAction)installSafariExtension:(id)sender;
{
    if(![[OperationQueues arxivQueue] isOnline]){
        NSAlert*alert=[NSAlert alertWithMessageText:@"You can't install the extension off-line."
				      defaultButton:@"OK"
				    alternateButton:nil
					otherButton:nil
			  informativeTextWithFormat:nil];
	[alert runModal];
        return;
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0),^{
        NSData*extz=[NSData dataWithContentsOfURL:[NSURL URLWithString:@"http://member.ipmu.jp/yuji.tachikawa/spires/arXivTeXifier.safariextz"]];
        [extz writeToFile:@"/tmp/arXivTeXifier.safariextz" atomically:YES];
        dispatch_async(dispatch_get_main_queue(),^{
            [[NSWorkspace sharedWorkspace] openFile:@"/tmp/arXivTeXifier.safariextz"];
        });
    });
}


-(IBAction)progressQuit:(id)sender
{
    [OperationQueues cancelCurrentOperations];
}
-(IBAction)changeFont:(id)sender;
{
    [prefController changeFont:sender];
}
-(IBAction)zoomIn:(id)sender;
{
    prefController.fontSize=prefController.fontSize+1;
}
-(IBAction)zoomOut:(id)sender;
{
    prefController.fontSize=prefController.fontSize-1;
}
-(IBAction)showPreferences:(id)sender;
{
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

-(IBAction)openHomePage:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://member.ipmu.jp/yuji.tachikawa/spires/"]];
}
-(IBAction)showReleaseNotes:(id)sender
{
    [[NSWorkspace sharedWorkspace] openFile:[[NSBundle mainBundle] pathForResource:@"Release Notes" ofType:@"html"]];    
}
-(IBAction)showAcknowledgments:(id)sender;
{
    [[NSWorkspace sharedWorkspace] openFile:[[NSBundle mainBundle] pathForResource:@"Acknowledgments" ofType:@"html"]];    
}
-(IBAction)dumpDebugInfo:(id)sender
{
    Article*a=[ac selectedObjects][0];
    NSLog(@"%@",a);
    NSLog(@"%@",a.data);
    /*    for(Article*b in a.citedBy){
     NSLog(@"citedByEntry:%@",b);
     }*/
    //    NSLog(@"%@",a.abstract);
}
-(IBAction)addArticleList:(id)sender
{
    [self addSimpleArticleListWithName:@"untitled"];
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
    ArticleFolder* al=[ArticleFolder createArticleFolderWithName:@"untitled" inMOC:[MOC moc]];
    [sideOutlineViewController addArticleList:al];
}
-(void)addCannedSearch:(id)sender
{
    NSString*name=[[AllArticleList allArticleList] searchString];
    if(!name || [name isEqualToString:@""]){
	NSAlert*alert=[NSAlert alertWithMessageText:@"Sorry..."
				      defaultButton:@"OK"
				    alternateButton:nil
					otherButton:nil
			  informativeTextWithFormat:@"To save search, please first specify the query at the search box!"];	
	[alert runModal];
	return;
    }
    CannedSearch* al=[CannedSearch createCannedSearchWithName:name inMOC:[MOC moc]];
    al.searchString=[[sideOutlineViewController currentArticleList] searchString];
    al.sortDescriptors=[[sideOutlineViewController currentArticleList] sortDescriptors];
    [sideOutlineViewController addArticleList:al];
}

-(void)deleteArticleList:(id)sender
{
    [sideOutlineViewController removeCurrentArticleList];
}

-(IBAction)sendBugReport:(id)sender
{
    NSString* version=[[[NSBundle mainBundle] infoDictionary] valueForKey:@"CFBundleVersion"];
    NSInteger entries=[[[AllArticleList allArticleList] articles] count];
    NSNumber* size=[self databaseSize];
    [[NSWorkspace sharedWorkspace]
     openURL:[NSURL URLWithString:
	      [[NSString stringWithFormat:
		@"mailto:yuji.tachikawa@ipmu.jp?subject=spires.app Bugs/Suggestions for v.%@ (%d entries, %@ bytes)",
		version,(int)entries,size]
	       stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]]];
}    

-(IBAction)deletePDFForEntry:(id)sender
{
    Article*a=[ac selectedObjects][0];
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
    [[NSWorkspace sharedWorkspace] recycleURLs:@[[NSURL fileURLWithPath:path]]
			     completionHandler:nil];
    [a setFlag:a.flag &(~AFHasPDF)];
    
}
-(IBAction)deleteEntry:(id)sender
{
    ArticleList* al=[sideOutlineViewController currentArticleList];
    if(!al){
	NSBeep(); 
	return;
    }
    NSArray*a=[ac selectedObjects];
    if([al isKindOfClass:[AllArticleList class]]){
	for(Article*x in a){
	    [al removeArticlesObject:x];
	    [[MOC moc] deleteObject:x];
	}
	[self saveAction:self]; 
	// otherwise, the to-be-deleted but not-really-deleted-on-disk entries haunt
	// us in the CoreData queries
    }else if([al isKindOfClass:[SimpleArticleList class]]){
	for(Article*x in a){
	    [al removeArticlesObject:x];
	}
    }
}
-(IBAction) search:(NSSearchField*)sender
{
/*    ArticleList* al=[sideOutlineViewController currentArticleList];
    if(!al){
	return;
    }
    if([al isKindOfClass:[CannedSearch class]]){
	[al reload];
	return;
    }*/
    NSString*searchString=[sender stringValue];
    if(searchString==nil || [searchString isEqualToString:@""])return;
    ArticleList*al=[sideOutlineViewController currentArticleList];
    if(![al isKindOfClass:[AllArticleList class]]){
        return;
    }
    [historyController mark:self];
    [AllArticleList allArticleList].searchString=searchString;
    [[AllArticleList allArticleList] reload];
    [sideOutlineViewController selectAllArticleList];
    if(!([[[NSApplication sharedApplication] currentEvent] modifierFlags]&NSShiftKeyMask)){
        [self querySPIRES: searchString];
    }// [self searchStringFromPredicate:filterPredicate]];
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
//	[self querySPIRES:[NSString stringWithFormat:@"spicite %@",[o valueForKey:@"spicite"]]];
    }
    [[NSApp appDelegate] stopProgressIndicator];
}
-(IBAction) reloadSelectedArticleList:(id)sender
{
    ArticleList* al=[sideOutlineViewController currentArticleList];
    if([al isKindOfClass:[AllArticleList class]]){
	[self search:nil];
    }else{
//	[[OperationQueues arxivQueue] addOperation:[[ArticleListReloadOperation alloc] initWithArticleList:al]];
        [al reload];
//	[[OperationQueues arxivQueue] addOperation:[[WaitOperation alloc] initWithTimeInterval:1]];
    }
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
//	[[OperationQueues arxivQueue] addOperation:[[ArticleListReloadOperation alloc] initWithArticleList:l]];
        [l reload];
//	[[OperationQueues arxivQueue] addOperation:[[WaitOperation alloc] initWithTimeInterval:1]];
    }
}
-(IBAction)openSelectionInQuickLook:(id)sender
{
    if([[ac selectedObjects] count]==0)return;
    Article*a=[ac selectedObjects][0];
    [[PDFHelper sharedHelper] openPDFforArticle:a usingViewer:openWithQuickLook];
}
-(IBAction)openSelectionInPDFViewer:(id)sender;
{
    if([[ac selectedObjects] count]==0)return;
    Article*a=[ac selectedObjects][0];
    [[PDFHelper sharedHelper] openPDFforArticle:a usingViewer:openWithPrimaryViewer];
}
-(IBAction)openSelectionInSecondaryPDFViewer:(id)sender;
{
    if([[ac selectedObjects] count]==0)return;
    Article*a=[ac selectedObjects][0];
    [[PDFHelper sharedHelper] openPDFforArticle:a usingViewer:openWithSecondaryViewer];
}

-(IBAction)openPDF:(id)sender
{
    Article*o=[ac selectedObjects][0];
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
    Article*a=[ac selectedObjects][0];
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
    Article*a=[ac selectedObjects][0];
    if(a.hasPDFLocally || (a.eprint && ![a.eprint isEqualToString:@""]) ){
	[self openPDF:sender];
    }else{
	[self openJournal:sender];
    }
}

-(IBAction)getBibEntriesWithoutDisplay:(id)sender
{
    NSArray*x=[ac selectedObjects];
    [[OperationQueues spiresQueue] addOperation:[[BatchBibQueryOperation alloc]initWithArray:x]];
}
-(IBAction)getBibEntries:(id)sender
{
    [self getBibEntriesWithoutDisplay:sender];
    [bibViewController showWindow:sender];
    [bibViewController setArticles:[ac selectedObjects]];
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
    [[OperationQueues sharedQueue] addOperation:op];
}
-(void)reloadFromSPIRESmainwork:(NSArray*)articles
{
    NSMutableArray*queries=[NSMutableArray array];
    for(Article*article in articles){
        NSString* query=[article uniqueSpiresQueryString];
        if(query){
            [queries addObject:query];
        }
    }
    if([queries count]>0){
        NSString* realQuery=[queries componentsJoinedByString:@" or "];
        [[OperationQueues spiresQueue] addOperation:[[SpiresQueryOperation alloc]initWithQuery:realQuery andMOC:[MOC moc]]];
    }
    
}
-(IBAction)reloadFromSPIRES:(id)sender
{
    NSMutableArray*articles=[[ac selectedObjects] mutableCopy];
    {
        NSUInteger count = [articles count];
        for (NSUInteger i = 0; i < count; ++i) {
            // Select a random element between i and end of array to swap with.
            NSInteger nElements = count - i;
            NSInteger n = (arc4random() % nElements) + i;
            [articles exchangeObjectAtIndex:i withObjectAtIndex:n];
        }
    }
    NSMutableArray*a=[NSMutableArray array];
    for(Article*article in articles){
	[a addObject:article];
	if([a count]>16){
	    [self reloadFromSPIRESmainwork:a];
	    a=[NSMutableArray array];
	}
    }
    if([a count]>0){
        [self reloadFromSPIRESmainwork:a];
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

@end
