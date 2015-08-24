//
//  PDFHelper.h
//  spires
//
//  Created by Yuji on 09/01/31.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

@import Foundation;

@class Article;

typedef enum _PDFViewerType{
    openWithPrimaryViewer,
    openWithSecondaryViewer,
    openWithQuickLook
} PDFViewerType;

@interface PDFHelper : NSObject {
}
+(PDFHelper*)sharedHelper;
-(void)openPDFFile:(NSString*)path usingViewer:(PDFViewerType)type;
-(void)openPDFforArticle:(Article*)o usingViewer:(PDFViewerType)type;
-(BOOL)downloadAndOpenPDFfromJournalForArticle:(Article*)o ;
-(NSString*)displayNameForViewer:(PDFViewerType)type;
-(int)tryToDetermineVersionFromPDF:(NSString*)pdfPath;
//-(void)quickLookDidClose:(id)sender;
//-(void)activateQuickLookIfNecessary;
@end
