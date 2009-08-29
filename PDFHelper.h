//
//  PDFHelper.h
//  spires
//
//  Created by Yuji on 09/01/31.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class Article;
//@class spires_AppDelegate;

typedef enum _PDFViewerType{
    openWithPrimaryViewer,
    openWithSecondaryViewer,
    openWithQuickLook
} PDFViewerType;

@interface PDFHelper : NSObject {
//    IBOutlet NSWindow*window;
//    IBOutlet spires_AppDelegate*appDelegate;
}
+(PDFHelper*)sharedHelper;
-(void)openPDFFile:(NSString*)path usingViewer:(PDFViewerType)type;
-(void)openPDFforArticle:(Article*)o usingViewer:(PDFViewerType)type;
-(BOOL)downloadAndOpenPDFfromJournalForArticle:(Article*)o ;
-(NSString*)displayNameForViewer:(PDFViewerType)type;
//-(void)quickLookDidClose:(id)sender;
//-(void)activateQuickLookIfNecessary;
@end
