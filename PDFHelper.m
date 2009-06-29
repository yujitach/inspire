//
//  PDFHelper.m
//  spires
//
//  Created by Yuji on 09/01/31.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import "PDFHelper.h"
#import "Article.h"
#import "JournalEntry.h"
#import "spires_AppDelegate.h"
#import "ArxivHelper.h"
#import "SpiresHelper.h"
#import "ProgressIndicatorController.h"
#import "RegExKitLite.h"
#import "NSString+XMLEntityDecoding.h"
#import "JournalPDFDownloadOperation.h"
#import "ArxivPDFDownloadOperation.h"
#import "ArxivVersionCheckingOperation.h"
#import "DeferredPDFOpenOperation.h"

// QuickLooking is off-loaded to QuickLookHelper... It tends to crash in 64bit mode.
// It seems to be a bug in PDFKit under GC.
// 0902.4674v1.pdf causes this. Maybe I should report it to Apple.

//#define QLPreviewPanel NSClassFromString(@"QLPreviewPanel")

/*
 @interface SomeKindOfPanel : NSObject{
}
-(void)setURLs:(NSArray*)a currentIndex:(NSInteger)i preservingDisplayState:(BOOL)b;
-(void)makeKeyAndOrderFrontWithEffect:(NSInteger)i;
@end
@interface NSObject (toShutUpWarningFromGCCaboutQuickLook)
-(SomeKindOfPanel*)sharedPreviewPanel;
@end
*/
static PDFHelper*_helper;
static NSMutableArray*shownPDFs;
static BOOL quickLookIsOpen=NO;
@implementation PDFHelper
/*-(BOOL)respondsToSelector:(SEL)selector
{
    NSLog(@"%@",NSStringFromSelector(selector));
    return NO;
}*/
+(PDFHelper*)sharedHelper
{
    if(!_helper){
	_helper=[[PDFHelper alloc]init];
	shownPDFs=[NSMutableArray array];
    }
    return _helper;
}
-init
{
    self=[super init];
    [[NSDistributedNotificationCenter defaultCenter] addObserver:self 
							selector:@selector(quickLookHelperDidClose:) 
							    name:@"QuickLookHelperDidClose" 
							  object:nil];
    return self;
}
+(void)initialize
{
//    if([[NSBundle bundleWithPath:@"/System/Library/PrivateFrameworks/QuickLookUI.framework"] load]){
//	NSLog(@"Quick Look loaded!"); 
	//[[[QLPreviewPanel sharedPreviewPanel] windowController] setDelegate:self];
//    }
}
-(NSString*)displayNameForApp:(NSString*)bundleId
{
    NSWorkspace* ws=[NSWorkspace sharedWorkspace];
    NSFileManager* fm=[NSFileManager defaultManager];
    NSString*path=[ws absolutePathForAppBundleWithIdentifier:bundleId];
    NSString* s=[fm displayNameAtPath:path];
    if([s hasSuffix:@".app"]){
	s=[s stringByDeletingPathExtension];
    }
    return s;
}
-(NSString*)displayNameForViewer:(PDFViewerType)type;
{
    NSString*bundleId;
    switch(type){
	case openWithPrimaryViewer:
	    bundleId=[[NSUserDefaults standardUserDefaults] stringForKey:@"primaryPDFViewer"];
	    return [self displayNameForApp:bundleId];
	case openWithSecondaryViewer:
	    bundleId=[[NSUserDefaults standardUserDefaults] stringForKey:@"secondaryPDFViewer"];
	    return [self displayNameForApp:bundleId];
	case openWithQuickLook:
	    return @"QuickLook";
    }
    return nil;
}
-(void)openPDFFile:(NSString*)path usingApp:(NSString*)bundleId
{
    if(!path ||[path isEqualToString:@""]){
	return;
    }
    [[NSWorkspace sharedWorkspace] openURLs:[NSArray arrayWithObject:[NSURL fileURLWithPath:path]]
		    withAppBundleIdentifier:bundleId
				    options:NSWorkspaceLaunchDefault
	     additionalEventParamDescriptor:nil
			  launchIdentifiers:nil];
}    
-(void)openPDFFile:(NSString*)path usingViewer:(PDFViewerType)type
{
    NSString*bundleId;
    switch(type){
	case openWithPrimaryViewer:
	    bundleId=[[NSUserDefaults standardUserDefaults] stringForKey:@"primaryPDFViewer"];
	    [self openPDFFile:path usingApp:bundleId];
	    break;
	case openWithSecondaryViewer:
	    bundleId=[[NSUserDefaults standardUserDefaults] stringForKey:@"secondaryPDFViewer"];
	    [self openPDFFile:path usingApp:bundleId];
	    break;
	case openWithQuickLook:
/*	    [[QLPreviewPanel sharedPreviewPanel] setURLs:[NSArray arrayWithObject:[NSURL fileURLWithPath:path]] 
					    currentIndex:0 
				  preservingDisplayState:YES];
	    
	    [[QLPreviewPanel sharedPreviewPanel] makeKeyAndOrderFrontWithEffect:1]; 
*/
	    if([shownPDFs containsObject:path]){
		system("killall SpiresQuickLookHelper");
	    }
	    [[NSWorkspace sharedWorkspace] openFile:path withApplication:[[NSBundle mainBundle] pathForResource:@"SpiresQuickLookHelper" ofType:@"app"]];
	    quickLookIsOpen=YES;
	    [shownPDFs addObject:path];
	    break;
    }
}

#pragma mark QuickLook management
-(void)quickLookDidClose:(id)sender;
{
    quickLookIsOpen=NO;
}
-(void)activateQuickLookIfNecessary;
{
    if(quickLookIsOpen){
	[[NSWorkspace sharedWorkspace] openFile:[[NSBundle mainBundle] pathForResource:@"SpiresQuickLookHelper" ofType:@"app"]];
    }
}

#pragma mark arXiv article Version Checking



-(void)openPDFforArticle:(Article*)o usingViewer:(PDFViewerType)viewerType
{

    if(o.hasPDFLocally&&![[[NSApplication sharedApplication] delegate] currentListIsArxivReplaced]){
	[self openPDFFile:o.pdfPath usingViewer:viewerType];
	if(o.articleType==ATEprint){
	    if([[SpiresHelper sharedHelper] isOnline])
		[[DumbOperationQueue arxivQueue] addOperation:[[ArxivVersionCheckingOperation alloc] initWithArticle:o
												      usingViewer:viewerType]];
	}
    }else if(o.articleType==ATEprint){
	if([[SpiresHelper sharedHelper] isOnline]){
	[[DumbOperationQueue arxivQueue] addOperation:[[ArxivPDFDownloadOperation alloc] initWithArticle:o]];
	[[DumbOperationQueue arxivQueue] addOperation:[[DeferredPDFOpenOperation alloc] initWithArticle:o 
											     usingViewer:viewerType]];
	}
    }else{
	NSAlert*alert=[NSAlert alertWithMessageText:@"No PDF associated"
				      defaultButton:@"OK" 
				    alternateButton:nil
					otherButton:nil
			  informativeTextWithFormat:@"PDF can be associated by dropping into the lower pane."];
	[alert beginSheetModalForWindow:[[[NSApplication sharedApplication] delegate] mainWindow]
			  modalDelegate:nil
			 didEndSelector:nil
			    contextInfo:nil];
    }
}

-(BOOL)downloadAndOpenPDFfromJournalForArticle:(Article*)o ;
{
    NSString* journalName=o.journal.name;
    if(![[SpiresHelper sharedHelper] isOnline])
	return NO;

    if(!journalName || [journalName isEqualToString:@""])
	return NO;
    NSUserDefaults*defaults=[NSUserDefaults standardUserDefaults];
    if([[defaults arrayForKey:@"ElsevierJournals"] containsObject:journalName]
     ||[[defaults arrayForKey:@"APSJournals"] containsObject:journalName]
       ||[[defaults arrayForKey:@"SpringerJournals"] containsObject:journalName]
       ||[[defaults arrayForKey:@"AIPJournals"] containsObject:journalName]
	){
	[[DumbOperationQueue spiresQueue] addOperation:[[JournalPDFDownloadOperation alloc] initWithArticle:o]];
	PDFViewerType type=openWithPrimaryViewer;
	if([[NSApp currentEvent] modifierFlags]&NSAlternateKeyMask){
	    type=openWithSecondaryViewer;
	}
	[[DumbOperationQueue spiresQueue] addOperation:[[DeferredPDFOpenOperation alloc] initWithArticle:o usingViewer:type]];
	return YES;
    }
    return NO;
}
@end
