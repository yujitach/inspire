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
#import "NSString+magic.h"
#import "JournalPDFDownloadOperation.h"
#import "ArxivPDFDownloadOperation.h"
#import "ArxivVersionCheckingOperation.h"
#import "ArxivMetadataFetchOperation.h"
#import "DeferredPDFOpenOperation.h"
#import "AppDelegate.h"


static PDFHelper*_helper=nil;
NSString* pathShownWithQuickLook=nil;

#if TARGET_OS_IPHONE
@interface PDFHelper (Delegate) <UIDocumentInteractionControllerDelegate>
@end

#else
#import <Quartz/Quartz.h>
@interface PDFHelper (QuickLookDelegate) <QLPreviewPanelDataSource>
@end




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
#endif

@implementation PDFHelper
#if TARGET_OS_IPHONE
{
    UIDocumentInteractionController*documentInteractionContoller;
}
#endif
+(PDFHelper*)sharedHelper
{
    if(!_helper){
	_helper=[[PDFHelper alloc]init];
//	shownPDFs=[NSMutableArray array];
    }
    return _helper;
}
-(id)init
{
    self=[super init];
    return self;
}
#if TARGET_OS_IPHONE
#pragma mark interaction with PDF viewer
- (UIViewController *)documentInteractionControllerViewControllerForPreview:(UIDocumentInteractionController *)controller
{
    return [NSApp appDelegate].presentingViewController;
}
- (UIView *) documentInteractionControllerViewForPreview: (UIDocumentInteractionController *) controller
{
    return  [UIApplication sharedApplication].keyWindow.rootViewController.view;

}

-(void)openPDFFile:(NSString*)path usingViewer:(PDFViewerType)type
{
    documentInteractionContoller=nil;
    documentInteractionContoller=[UIDocumentInteractionController interactionControllerWithURL:[NSURL fileURLWithPath:path]];
    documentInteractionContoller.delegate=self;
    documentInteractionContoller.UTI=@"com.adobe.pdf";
    [documentInteractionContoller presentPreviewAnimated:YES];
}
-(NSString*)displayNameForViewer:(PDFViewerType)type;
{
    return @"iOS-builtin viewer";
}
#else
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
    [[NSWorkspace sharedWorkspace] openURLs:@[[NSURL fileURLWithPath:path]]
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
#endif

#pragma mark arXiv article Version Checking



-(void)openPDFforArticle:(Article*)o usingViewer:(PDFViewerType)viewerType
{

    if(o.hasPDFLocally&&![[NSApp appDelegate] currentListIsArxivReplaced]){
	[self openPDFFile:o.pdfPath usingViewer:viewerType];
	if([o isEprint]){
		NSOperation*op1=[[ArxivMetadataFetchOperation alloc] initWithArticle:o];
		NSOperation*op2=[[ArxivVersionCheckingOperation alloc] initWithArticle:o
									  usingViewer:viewerType];
		[op2 addDependency:op1];
		[[OperationQueues arxivQueue] addOperation:op1];
		[[OperationQueues sharedQueue] addOperation:op2];
	}
    }else if([o isEprint]){
        NSOperation*downloadOp=[[ArxivPDFDownloadOperation alloc] initWithArticle:o shouldAsk:YES];
        NSOperation*openOp=[[DeferredPDFOpenOperation alloc] initWithArticle:o
                                                                 usingViewer:viewerType];
        [openOp addDependency:downloadOp];
	[[OperationQueues arxivQueue] addOperation:downloadOp];
        [[OperationQueues sharedQueue] addOperation:openOp];
    }else{
#if !TARGET_OS_IPHONE
	NSAlert*alert=[NSAlert alertWithMessageText:@"No PDF associated"
				      defaultButton:@"OK" 
				    alternateButton:nil
					otherButton:nil
			  informativeTextWithFormat:@"PDF can be associated by dropping into the lower pane."];
	[alert beginSheetModalForWindow:[[NSApp appDelegate] mainWindow]
			  modalDelegate:nil
			 didEndSelector:nil
			    contextInfo:nil];
#endif
    }
}
-(BOOL)downloadAndOpenPDFfromJournalForArticle:(Article*)o ;
{
#if TARGET_OS_IPHONE
    return NO;
#else
    NSString* doi=o.doi;
    if(!doi || [doi isEqualToString:@""])
	return NO;
    
    NSString* journalName=o.journal.name;
    if(!journalName || [journalName isEqualToString:@""])
	return NO;
    
    NSUserDefaults*defaults=[NSUserDefaults standardUserDefaults];
    if([[defaults arrayForKey:@"KnownJournals"] containsObject:journalName]){
	PDFViewerType type=openWithPrimaryViewer;
	if([[NSApp currentEvent] modifierFlags]&NSAlternateKeyMask){
	    type=openWithSecondaryViewer;
	}
        
        
        NSOperation*downloadOp=[[JournalPDFDownloadOperation alloc] initWithArticle:o];
        NSOperation*openOp=[[DeferredPDFOpenOperation alloc] initWithArticle:o
                                                                 usingViewer:type];
        [openOp addDependency:downloadOp];
	[[OperationQueues sharedQueue] addOperation:downloadOp];
        [[OperationQueues sharedQueue] addOperation:openOp];
	return YES;
    }
    return NO;
#endif
}
-(int)tryToDetermineVersionFromPDF:(NSString*)pdfPath
{
    NSURL*url=[NSURL fileURLWithPath:pdfPath];
    CGPDFDocumentRef doc=CGPDFDocumentCreateWithURL((__bridge CFURLRef)url);
    CGPDFDictionaryRef dic=CGPDFDocumentGetInfo(doc);
    CGPDFStringRef pdfStringRef;
    NSString* s=nil;
    if(CGPDFDictionaryGetString(dic, "Title", &pdfStringRef)){
        s=(NSString*)CFBridgingRelease(CGPDFStringCopyTextString(pdfStringRef));
    }
    CFRelease(doc);
    
    s=[s stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    s=[s stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    if(!s)
	return 0;
    if(![s hasPrefix:@"arXiv:"] && ([s rangeOfString:@"arXiv:"].location==NSNotFound)){
	return 0;
    }
    s=[s stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    NSString* versionString=[s stringByMatching:@"arXiv:.{9}v(.)" capture:1];
    if(!versionString){
	versionString=[s stringByMatching:@"arXiv:.+?/.{7}v(.)" capture:1];
	if(!versionString)
	    return 0;
    }
    int version=[versionString intValue];
    return version;
}
@end
