//
//  ArxivVersionCheckingOperation.m
//  spires
//
//  Created by Yuji on 09/02/07.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import "ArxivVersionCheckingOperation.h"
#import "Article.h"
#import "ArxivHelper.h"
#import "ArxivPDFDownloadOperation.h"
#import "DeferredPDFOpenOperation.h"
#import "RegexKitLite.h"
#import "NSString+magic.h"
#import "AppDelegate.h"
// #import <Quartz/Quartz.h>


@implementation ArxivVersionCheckingOperation
-(ArxivVersionCheckingOperation*)initWithArticle:(Article*)a usingViewer:(PDFViewerType)t;
{
    [super init];
    article=a;
    type=t;
    return self;
}
-(NSString*)description
{
    return [NSString stringWithFormat:@"version checking: %@", article.eprint];
}
-(void)run
{
    self.isExecuting=YES;
    [[ArxivHelper sharedHelper] onlineMetaDataForID:article.eprint delegate:self didEndSelector:@selector(info:) ];

}

-(int)tryToDetermineVersionFromPDF:(NSString*)pdfPath
{
/*    NSLog(@"scanning PDF:%@",pdfPath);
    PDFDocument* d=[[PDFDocument alloc] initWithURL:[NSURL fileURLWithPath:pdfPath]];
    PDFPage* p=[d pageAtIndex:0];
    NSString* s=[p string];*/
//    d=nil;
//    p=nil;
    // This is off-loaded to an external helper because PDFKit sometimes crashes,
    // in particular in 64 bit mode.
    NSString*tmpFile=[NSString stringWithFormat:@"/tmp/spiresPDFScannerTemporary-%d",getuid()];
    NSString*script=[[NSBundle mainBundle] pathForResource:@"pdfScanHelper" ofType:@""];
    NSString* command=[NSString stringWithFormat:@"%@ %@ %@" ,[script quotedForShell], [pdfPath quotedForShell], tmpFile];
    system([command UTF8String]);
    NSString*s=[NSString stringWithContentsOfFile:tmpFile encoding:NSUTF8StringEncoding error:nil];
    s=[s stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    s=[s stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    if(!s)
	return 0;
    if(![s hasPrefix:@"arXiv:"] && ([s rangeOfString:@"arXiv:"].location==NSNotFound)){
	return 0;
    }
//    NSLog(@"%@",s);
    s=[s stringByReplacingOccurrencesOfString:@" " withString:@""];
/*    NSScanner* scanner=[NSScanner scannerWithString:s];
    [scanner scanUpToString:@"arXiv:" intoString:NULL];
    [scanner scanString:@"arXiv:" intoString:NULL];
    [scanner scanUpToString:@"v" intoString:NULL];
    [scanner scanString:@"v" intoString:NULL];
    NSString*tmp;
    [scanner scanCharactersFromSet:[NSCharacterSet decimalDigitCharacterSet] intoString:&tmp];
 int version=[[tmp substringToIndex:1] intValue];

 */
    NSString* versionString=[s stringByMatching:@"arXiv:.{9}v(.)" capture:1];
    if(!versionString){
	versionString=[s stringByMatching:@"arXiv:.+?/.{7}v(.)" capture:1];
	if(!versionString)
	    return 0;
    }
    int version=[versionString intValue];
    NSLog(@"version %d detected",version);
    return version;
}



-(void)info:(NSDictionary*)dict
{
//    NSLog(@"???");
    if(!dict){
	[self finish];
	return;
    }
    
    article.abstract=[dict objectForKey:@"abstract"];
    article.version=[dict objectForKey:@"version"];  
    article.comments=[dict objectForKey:@"comments"];
    
    
    if(article.version==nil || [article.version intValue]==0 || !article.hasPDFLocally){
	[self finish];
	return;
    }
    int v=[self tryToDetermineVersionFromPDF:article.pdfPath];
    if(v==[article.version intValue] || v==0){
	[self finish];
	return;
    }
    NSString*commentsLine=@"";
    if(article.comments && ![article.comments isEqualToString:@""]){
	commentsLine=[NSString stringWithFormat:@"Comments: %@",article.comments];
    }
    NSAlert *alert = [NSAlert alertWithMessageText:[NSString stringWithFormat:@"A new version of %@ has been found.",article.eprint]
				     defaultButton:@"Download" 
				   alternateButton:@"Cancel"
				       otherButton:nil
			 informativeTextWithFormat: @"Your PDF is version %d, which is older than the latest version %d on the web.\n%@",
		      v,[article.version intValue],commentsLine];
    [alert setAlertStyle:NSWarningAlertStyle];
    //   [NSApp unhide:self];
    
    [alert beginSheetModalForWindow:[(id<AppDelegate>)[NSApp delegate] mainWindow]
		      modalDelegate:self 
		     didEndSelector:@selector(downloadAlertDidEnd:code:context:)
			contextInfo:nil];
    
}
-(void)downloadAlertDidEnd:(NSAlert*)alert code:(int)choice context:(id)ignore
{
    if(choice==NSAlertDefaultReturn){
	[[OperationQueues arxivQueue] addOperation:[[ArxivPDFDownloadOperation alloc] initWithArticle:article shouldAsk:NO]];
	[[OperationQueues arxivQueue] addOperation:[[DeferredPDFOpenOperation alloc] initWithArticle:article
											     usingViewer:type]];

    }
    [self finish];
}
    

@end
