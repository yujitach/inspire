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
#import "SpiresHelper.h"
#import "RegExKitLite.h"
#import "NSString+magic.h"
#import "JournalPDFDownloadOperation.h"
#import "ArxivPDFDownloadOperation.h"
#import "ArxivVersionCheckingOperation.h"
#import "ArxivMetadataFetchOperation.h"
#import "DeferredPDFOpenOperation.h"
#import "AppDelegate.h"

#import <Quartz/Quartz.h>

@interface PDFHelper (QuickLookDelegate) <QLPreviewPanelDataSource>
@end


static PDFHelper*_helper=nil;
NSString* pathShownWithQuickLook=nil;


@interface QuickLookPDFItem : NSObject<QLPreviewItem>
{
}
@property (readonly) NSURL *previewItemURL;
@end
@implementation QuickLookPDFItem
-(NSURL*) previewItemURL
{
    return [NSURL fileURLWithPath:pathShownWithQuickLook];
}
@end

@implementation PDFHelper

+(PDFHelper*)sharedHelper
{
    if(!_helper){
	_helper=[[PDFHelper alloc]init];
//	shownPDFs=[NSMutableArray array];
    }
    return _helper;
}
-init
{
    self=[super init];
    return self;
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
	    pathShownWithQuickLook=path;
	    [[QLPreviewPanel sharedPreviewPanel] makeKeyAndOrderFront:self];
	    [[QLPreviewPanel sharedPreviewPanel] reloadData];
	    break;
    }
}


#pragma mark QuickLook management
- (NSInteger)numberOfPreviewItemsInPreviewPanel:(QLPreviewPanel *)panel

{
    return pathShownWithQuickLook?1:0;
}
- (id <QLPreviewItem>)previewPanel:(QLPreviewPanel *)panel previewItemAtIndex:(NSInteger)i
{
    return [[QuickLookPDFItem alloc] init];
}


#pragma mark arXiv article Version Checking



-(void)openPDFforArticle:(Article*)o usingViewer:(PDFViewerType)viewerType
{

    if(o.hasPDFLocally&&![[NSApp appDelegate] currentListIsArxivReplaced]){
	[self openPDFFile:o.pdfPath usingViewer:viewerType];
	if(o.articleType==ATEprint){
	    if([[NSApp appDelegate] isOnline]){
		NSOperation*op1=[[ArxivMetadataFetchOperation alloc] initWithArticle:o];
		NSOperation*op2=[[ArxivVersionCheckingOperation alloc] initWithArticle:o
									  usingViewer:viewerType];
		[op2 addDependency:op1];
		[[OperationQueues arxivQueue] addOperation:op1];
		[[OperationQueues arxivQueue] addOperation:op2];
	    }
	}
    }else if(o.articleType==ATEprint){
	if([[NSApp appDelegate] isOnline]){
	    [[OperationQueues arxivQueue] addOperation:[[ArxivPDFDownloadOperation alloc] initWithArticle:o shouldAsk:YES]];
	    [[OperationQueues arxivQueue] addOperation:[[DeferredPDFOpenOperation alloc] initWithArticle:o 
											     usingViewer:viewerType]];
	}
    }else{
	NSAlert*alert=[NSAlert alertWithMessageText:@"No PDF associated"
				      defaultButton:@"OK" 
				    alternateButton:nil
					otherButton:nil
			  informativeTextWithFormat:@"PDF can be associated by dropping into the lower pane."];
	[alert beginSheetModalForWindow:[[NSApp appDelegate] mainWindow]
			  modalDelegate:nil
			 didEndSelector:nil
			    contextInfo:nil];
    }
}

-(BOOL)downloadAndOpenPDFfromJournalForArticle:(Article*)o ;
{
    if(![[NSApp appDelegate] isOnline])
	return NO;

    NSString* doi=o.doi;
    if(!doi || [doi isEqualToString:@""])
	return NO;
    
    NSString* journalName=o.journal.name;
    if(!journalName || [journalName isEqualToString:@""])
	return NO;
    
    NSUserDefaults*defaults=[NSUserDefaults standardUserDefaults];
    if([[defaults arrayForKey:@"KnownJournals"] containsObject:journalName]){
	[[OperationQueues spiresQueue] addOperation:[[JournalPDFDownloadOperation alloc] initWithArticle:o]];
	PDFViewerType type=openWithPrimaryViewer;
	if([[NSApp currentEvent] modifierFlags]&NSAlternateKeyMask){
	    type=openWithSecondaryViewer;
	}
	[[OperationQueues spiresQueue] addOperation:[[DeferredPDFOpenOperation alloc] initWithArticle:o usingViewer:type]];
	return YES;
    }
    return NO;
}
@end
