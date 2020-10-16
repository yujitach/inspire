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
#define NSAlertFirstButtonReturn 0
typedef NSUInteger NSModalResponse;
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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pdfDownloadProgress:) name:@"pdfDownloadProgress" object:nil];
    return self;
}

-(void)pdfDownloadProgress:(NSNotification*)n
{
    NSDictionary*dic=(NSDictionary*)n.object;
    NSNumber*num=dic[@"fractionCompleted"];
    int percent=100*(num.doubleValue);
    dispatch_async(dispatch_get_main_queue(),^{
        [[NSApp appDelegate] postMessage:[NSString stringWithFormat:@"Downloading PDF (%@%%)...",@(percent)]];
    });
}
-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
-(void)cancel
{
    [[ArxivHelper sharedHelper] cancelDownloadPDF];
    [super cancel];
    [self finish];
}
-(void)downloadAlertDidEnd:(NSAlert*)alert code:(NSModalResponse)choice
{
    if(choice==NSAlertFirstButtonReturn){
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
    [[NSApp appDelegate] postMessage:@"Downloading PDF from arXiv..."];
    [[ArxivHelper sharedHelper] startDownloadPDFforID:article.eprint
					     delegate:self ];
}
-(void)run
{
    self.isExecuting=YES;
#if TARGET_OS_IPHONE
    [self downloadAlertDidEnd:nil code:NSAlertFirstButtonReturn];
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
}
-(NSString*)description
{
    return [NSString stringWithFormat:@"arxiv download for %@",article.eprint];
}

@end
