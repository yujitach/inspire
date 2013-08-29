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
#import "ArticleListReloadOperation.h"
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
#define SafariExtension @"arXivTeXifier"
#define SafariExtensionExtension @"safariextz"
-(IBAction)installSafariExtension:(id)sender;
{
    NSString*tildedPath=@"~/Library/Safari/Extensions/" SafariExtension @"." SafariExtensionExtension;
    NSString*path=[tildedPath stringByExpandingTildeInPath];
    if([[NSFileManager defaultManager] fileExistsAtPath:path]){
	NSAlert*alert=[NSAlert alertWithMessageText:@"Safari extension already installed."
				      defaultButton:@"OK" 
				    alternateButton:nil
					otherButton:nil
			  informativeTextWithFormat:@"Thank you, you already have my Safari extension installed."];
	[alert runModal];
    }else{
	NSString*extension=[[NSBundle mainBundle] pathForResource:SafariExtension ofType:SafariExtensionExtension];
	NSString*tmpLocation=@"/tmp/SafariExtensionExtension" SafariExtension @"." SafariExtensionExtension;
	[[NSFileManager defaultManager] copyItemAtPath:extension toPath:tmpLocation error:NULL];
	[[NSWorkspace sharedWorkspace] openFile:tmpLocation];
    }
}

-(IBAction)dumpBibtexFile:(id)sender;
{
    NSLog(@"start dumping");
    NSString*bibFilePath=[@"~/Desktop/all.bib" stringByExpandingTildeInPath];
    NSSet*articles=[[AllArticleList allArticleList] articles];
    NSMutableString*appendix=[NSMutableString string];
    for(Article*a in articles){
        NSString*key=[a texKey];
        if(!key)
            continue;
        if([key isEqualToString:@""])
            continue;
        NSString* bib=[a extraForKey:@"bibtex"];
        if(!bib)
            continue;
        if([bib isEqualToString:@""])
            continue;
        bib=[bib stringByReplacingOccurrencesOfString:[a texKey] withString:@"*#*#*#"];
	bib=[bib magicTeXed];
	bib=[bib stringByReplacingOccurrencesOfString:@"*#*#*#" withString:key];
	[appendix appendString:bib];
	[appendix appendString:@"\n\n"];
    }
    [appendix writeToFile:bibFilePath atomically:YES encoding:NSUTF8StringEncoding error:NULL];
    NSLog(@"finished dumping");
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
-(IBAction) search:(id)sender
{
    ArticleList* al=[sideOutlineViewController currentArticleList];
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
    [[AllArticleList allArticleList] reload];
    [sideOutlineViewController selectAllArticleList];
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
	[[OperationQueues arxivQueue] addOperation:[[ArticleListReloadOperation alloc] initWithArticleList:al]];
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
	[[OperationQueues arxivQueue] addOperation:[[ArticleListReloadOperation alloc] initWithArticleList:l]];
//	[[OperationQueues arxivQueue] addOperation:[[WaitOperation alloc] initWithTimeInterval:1]];
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
    [[OperationQueues spiresQueue] addOperation:op];
}
-(IBAction)reloadFromSPIRES:(id)sender
{
    for(Article*article in [ac selectedObjects]){
	NSString* target=[article uniqueSpiresQueryString];
	if(target){
	    [[OperationQueues spiresQueue] addOperation:[[SpiresQueryOperation alloc]initWithQuery:target andMOC:[MOC moc]]];
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

#pragma mark check consistency
/*-(NSArray*)managedObjectsOfEntityNamed:(NSString*)entityName matchingPredicate:(NSPredicate*)predicate
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


-(void)dealWithError:(NSError*)e
{
    NSLog(@"dealing with error:%@",e);
    NSDictionary*info=[e userInfo];
    NSManagedObject*mo=[info objectForKey:NSValidationObjectErrorKey];
    if(mo){
	@try {
	    [[MOC moc] deleteObject:mo];
	}
	@catch (NSException * ex) {
	}
	@finally {
	}
    }
}
-(void)dealWithPossiblyMultipleErrors:(NSError*)error
{
    NSDictionary*info=[error userInfo];
    NSArray*errors=[info objectForKey:NSDetailedErrorsKey];
    if(errors){
	for(NSError*err in errors){
	    [self dealWithError:err];
	}
    }else{
	[self dealWithError:error];
    }    
}
-(BOOL)saveAndDeleteInvalidObjects
{
    NSError*error;
    BOOL b=NO;
    @try{
	b=[[MOC moc] save:&error];
    }
    @catch(NSException*e){
    }
    @finally{
    }
    if(!b){
	[self dealWithPossiblyMultipleErrors:error];
	return NO;
    }else{
	return YES;
    }
}
-(NSString*)fixDataInconsistencyMainWork
{
    NSString*message=nil;
    NSMutableArray*badGuys=[NSMutableArray array];
    
    [badGuys addObjectsFromArray:[self managedObjectsOfEntityNamed:@"Article" 
				  //						 matchingPredicate:[NSPredicate predicateWithFormat:@"(not (self in %@)) || data == nil",[AllArticleList allArticleList].articles]]];
						 matchingPredicate:[NSPredicate predicateWithFormat:@"data == nil"]]];
    [badGuys addObjectsFromArray:[self managedObjectsOfEntityNamed:@"ArticleData"
						 matchingPredicate:[NSPredicate predicateWithFormat:@"article == nil"]]];
    [badGuys addObjectsFromArray:[self managedObjectsOfEntityNamed:@"JournalEntry"
						 matchingPredicate:[NSPredicate predicateWithFormat:@"article == nil"]]];
    
    if([badGuys count]>0){
	// "fixed" in the message below is a euphemism for "just deleted".
	for(NSManagedObject*obj in badGuys){
	    [[MOC moc] deleteObject:obj];
	}
	[self saveAndDeleteInvalidObjects];
	message=[NSString stringWithFormat:@"%d problematic entries were fixed.",(int)[badGuys count]];
    }else{
	message=@"No problem found.";
    }
    return message;
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
    NSString*message=[self fixDataInconsistencyMainWork];
    {
	NSAlert*alert=[NSAlert alertWithMessageText:@"Consistency checked."
				      defaultButton:@"Vacuum" 
				    alternateButton:@"Relaunch"
					otherButton:nil
			  informativeTextWithFormat:@"%@",[message stringByAppendingString:
						     @" Do you proceed to vacuum-clean the database before the relaunch?" 
						     @" It will again take some time and you need to wait patiently."
						     ]];
	NSInteger result=[alert runModal];
	if(result==NSAlertDefaultReturn){
	    [self saveAction:self];
	    NSNumber*before=[self databaseSize];
	    [[MOC sharedMOCManager] vacuum];
	    [sideOutlineViewController selectAllArticleList];
	    NSNumber*after=[self databaseSize];
	    alert=[NSAlert alertWithMessageText:@"Done."
				  defaultButton:@"Relaunch" 
				alternateButton:nil
				    otherButton:nil
		      informativeTextWithFormat:@"%@",[NSString stringWithFormat:@"%@ bytes --> %@ bytes",before,after]];
	    [alert runModal];
	}
	[self relaunch];
    }
}
*/


/*-(void)listAndCull
{
    NSArray*x;
    x=[self managedObjectsOfEntityNamed:@"Article"
			      matchingPredicate:[NSPredicate predicateWithValue:YES]];
    for(Article*a in x){
	@try {
	    NSError*error;
	    if(![a validateForUpdate:&error]){
		NSLog(@"validation error found for: %@",a);
		[self dealWithPossiblyMultipleErrors:error];
	    }
	    if(![a.data validateForUpdate:&error]){
		NSLog(@"validation error found for: %@",a.data);
		[self dealWithPossiblyMultipleErrors:error];
	    }
	}
	@catch (NSException * e) {
	    NSLog(@"name:%@ reason:%@ userInfo:%@",e.name, e.reason, e.userInfo);
	    [[MOC moc] deleteObject:a.data];
	    [[MOC moc] deleteObject:a];
	    if([e.reason hasPrefix:@"CoreData could not fulfill a fault"]){
		NSArray*affected=[e.userInfo objectForKey:NSAffectedObjectsErrorKey];
		for(NSManagedObject*mo in affected){
		    [[MOC moc] deleteObject:mo];
		}
	    }    
	}
    }
    for(int i=0;i<10;i++){
	NSLog(@"tries to save...");
	if([self saveAndDeleteInvalidObjects])
	    break;
    }    
}
-(IBAction)regenerateMainList:(id)sender;
{
    for(int i=0;i<4;i++){
	NSLog(@"list and cull: trial %d",i);
	[self listAndCull];
	NSArray*x=[self managedObjectsOfEntityNamed:@"Article"
				  matchingPredicate:[NSPredicate predicateWithValue:YES]];
	@try{
	    [AllArticleList allArticleList].articles=[NSSet setWithArray:x];
	}
	@finally{
	}
	[self fixDataInconsistencyMainWork];
    }
    {
	NSAlert*alert=[NSAlert alertWithMessageText:@"Done"
				      defaultButton:@"OK" 
				    alternateButton:nil
					otherButton:nil
			  informativeTextWithFormat:@"You might want to repeat this process, by quitting and relaunching, etc."];
	[alert runModal];
    }    
}*/
@end
