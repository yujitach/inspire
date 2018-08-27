//
//  ArxivPDFDownloadOperation.m
//  spires
//
//  Created by Yuji on 09/02/07.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import "ArxivPDFDownloadOperation.h"
#import "Article.h"
#import "PDFHelper.h"
#import "ArxivHelper.h"
#import "AppDelegate.h"

#if TARGET_OS_IPHONE
#define NSAlert NSString
#define NSAlertDefaultReturn 0
#endif

@interface ArxivPDFDownloadOperation ()
-(void)pdfDownloadDidEnd:(NSDictionary*)dict;
-(void)retryAlertDidEnd:(NSAlert*)alert code:(NSModalResponse)choice;
-(void)retry;
@end

@implementation ArxivPDFDownloadOperation

-(ArxivPDFDownloadOperation*)initWithArticle:(Article*)a shouldAsk:(BOOL)ask;
{
    self=[super init];
    article=a;
    shouldAsk=ask;
    return self;
}

-(void)downloadAlertDidEnd:(NSAlert*)alert code:(NSModalResponse)choice
{
    if(choice==NSAlertFirstButtonReturn){
	[[NSApp appDelegate] startProgressIndicator];
	[[NSApp appDelegate] postMessage:@"Downloading PDF from arXiv..."]; 
	[[ArxivHelper sharedHelper] startDownloadPDFforID:article.eprint
						 delegate:self ];
    }else{
	[self finish];
    }
}

-(void)pdfDownloadDidEnd:(NSDictionary*)dict
{
    BOOL success=[[dict valueForKey:@"success"] boolValue];
    [[NSApp appDelegate] postMessage:nil]; 
    [[NSApp appDelegate] stopProgressIndicator];
    
    if(success){
	NSData* data=[dict valueForKey:@"pdfData"];
	if(![data writeToFile:article.pdfPath atomically:NO]){
#if !TARGET_OS_IPHONE
	    [[NSApp appDelegate] presentFileSaveError];
#endif
	}else{
	    [article associatePDF:article.pdfPath];
	}
	[self finish];
    }else if(dict[@"shouldReloadAfter"]){
	reloadDelay=dict[@"shouldReloadAfter"];
#if TARGET_OS_IPHONE
    [self retryAlertDidEnd:nil code:NSAlertFirstButtonReturn];
#else
        NSAlert*alert=[[NSAlert alloc] init];
        alert.messageText=@"PDF Download";
        [alert addButtonWithTitle:@"OK"];
        [alert addButtonWithTitle:@"Cancel downloading"];
        alert.informativeText=[NSString stringWithFormat:@"arXiv is now generating %@. Retrying in %@ seconds.", article.eprint,reloadDelay];
	[alert beginSheetModalForWindow:[[NSApp appDelegate] mainWindow]
                      completionHandler:^(NSModalResponse returnCode) {
                          [self retryAlertDidEnd:alert code:returnCode];
                      }
        ];
#endif
    }else{//failure
	[self finish];
    }
}
-(void)retryAlertDidEnd:(NSAlert*)alert code:(NSModalResponse)choice
{
    if(choice==NSAlertFirstButtonReturn){
//	NSLog(@"OK, retry in %@ seconds",reloadDelay);
	[[NSApp appDelegate] postMessage:@"Waiting for arXiv to generate PDF..."]; 
	[self performSelector:@selector(retry) withObject:nil afterDelay:[reloadDelay intValue]];
    }else{
	[self finish];
    }
}

-(void)retry
{
    //    NSLog(@"retry timer fired");
    [[NSApp appDelegate] startProgressIndicator];
    [[NSApp appDelegate] postMessage:@"Downloading PDF from arXiv..."]; 
    [[ArxivHelper sharedHelper] startDownloadPDFforID:article.eprint
					     delegate:self ];
}
-(void)run
{
    self.isExecuting=YES;
#if TARGET_OS_IPHONE
    [self downloadAlertDidEnd:nil code:NSAlertDefaultReturn context:nil];
#else
    if(shouldAsk && [[NSUserDefaults standardUserDefaults] boolForKey:@"askBeforeDownloadingPDF"]){
        NSAlert*alert=[[NSAlert alloc] init];
        alert.messageText=@"PDF Download";
        [alert addButtonWithTitle:@"Download" ];
        [alert addButtonWithTitle:@"Cancel"];
        alert.informativeText=[NSString stringWithFormat:@"%@v%@ is not yet downloaded ...", article.eprint,article.version];
	[alert beginSheetModalForWindow:[[NSApp appDelegate] mainWindow]
                      completionHandler:^(NSModalResponse returnCode) {
                          [self downloadAlertDidEnd:alert code:returnCode];
                      }
         ];
    }else{
	[self downloadAlertDidEnd:nil code:NSAlertFirstButtonReturn];
    }
#endif
}
-(void)cleanupToCancel
{
    [[NSApp appDelegate] postMessage:nil]; 
    [[NSApp appDelegate] stopProgressIndicator];
}
-(NSString*)description
{
    return [NSString stringWithFormat:@"arxiv download for %@",article.eprint];
}

@end
