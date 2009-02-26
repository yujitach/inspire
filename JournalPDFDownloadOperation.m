//
//  JournalPDFDownloadOperation.m
//  spires
//
//  Created by Yuji on 09/02/07.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import "JournalPDFDownloadOperation.h"
#import "SecureDownloader.h"
#import "ProgressIndicatorController.h"
#import "RegexKitLite.h"
#import "Article.h"
#import "JournalEntry.h"
#import "NSString+XMLEntityDecoding.h"
#import "PDFHelper.h"
#import "NSURL+libraryProxy.h"
#import "spires_AppDelegate.h"

@implementation JournalPDFDownloadOperation
-(JournalPDFDownloadOperation*)initWithArticle:(Article*)a
{
    [super init];
    article=a;
    return self;
}

-(NSString*)description
{
    return [NSString stringWithFormat:@"journal pdf download for \'%@\'",article.title];
}
-(void)main
{
    
    
    NSString*doiURL=[@"http://dx.doi.org/" stringByAppendingString:article.doi];
 //   NSLog(@"url:%@",url);
    [ProgressIndicatorController startAnimation:self];
    downloader=[[SecureDownloader alloc] initWithURL:[[NSURL URLWithString:doiURL] proxiedURLForELibrary]
				      didEndSelector:@selector(journalHTMLDownloadDidEnd:) 
					    delegate:self ];
    [downloader download];
}
-(void)journalHTMLDownloadDidEnd:(NSString*)path
{
    [ProgressIndicatorController stopAnimation:self];
    if(path){
	[self performSelector:@selector(continuation:)
		   withObject: path
		   afterDelay:.5];
    }
}
-(void)continuation:(NSString*)path
{
    NSString*html=[NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    NSString*pdf=nil;
    if(!pdf){ //APS
	NSString*s=[html stringByMatching:@"trackPageview\\(.(/pdf/.+?).\\)" capture:1];
	if(s){
	    pdf=[@"http://prola.aps.org" stringByAppendingString:s];
	}
    }
    if(!pdf){ //AIP
	NSString*s=[html stringByMatching:@"(/getpdf/servlet.+?)\"" capture:1];
	if(s){
	    pdf=[@"http://scitation.aip.org" stringByAppendingString:s];
	}	
    }
    if(!pdf){ //Springer
	NSString*s=[html stringByMatching:@"(/content/.+?fulltext.pdf)\"" capture:1];
	if(s){
	    pdf=[@"http://www.springerlink.com" stringByAppendingString:s];
	}	
    }
    if(!pdf){ // Elsevier
	NSString*s=[html stringByMatching:@"(/science.+?sdarticle.pdf)\"" capture:1];
	if(s){
	    pdf=[@"http://www.sciencedirect.com" stringByAppendingString:s];
	}		
    }
    if(!pdf){
	NSLog(@"failed to download PDF. instead opens the journal webpage");
	NSString* doiURL=[@"http://dx.doi.org/" stringByAppendingString:article.doi];
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:doiURL]];
	[(spires_AppDelegate*)[NSApp delegate] showInfoOnAssociation]; //cheating here...
	[self finish];
	return;
    }
    pdf=[pdf stringByExpandingAmpersandEscapes];
    NSLog(@"pdf detected at:%@",pdf);
    downloader=[[SecureDownloader alloc] initWithURL:[[NSURL URLWithString:pdf] proxiedURLForELibrary]
				      didEndSelector:@selector(journalPDFDownloadDidEnd:) 
					    delegate:self ];
    [ProgressIndicatorController startAnimation:self];
    [downloader download];	
}
-(void)journalPDFDownloadDidEnd:(NSString*)path
{
    [ProgressIndicatorController stopAnimation:self];
    if(path){
	NSData*data=[[NSData dataWithContentsOfFile:path] subdataWithRange:NSMakeRange(0,4)];
	NSString*head=[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	if(![head hasPrefix:@"%PDF"]){
	    NSLog(@"failed to download PDF. instead opens the journal webpage");
	    NSString* doiURL=[@"http://dx.doi.org/" stringByAppendingString:article.doi];
	    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:doiURL]];
	    [(spires_AppDelegate*)[NSApp delegate] showInfoOnAssociation]; //cheating here...
	}else{
	    NSString*dir=[[NSUserDefaults standardUserDefaults] objectForKey:@"pdfDir"];
	    JournalEntry*j=article.journal;
	    NSString*file=[NSString stringWithFormat:@"%@ %@ (%@) %@.pdf",j.name,j.volume,j.year,j.page];
	    NSString*dest=[[NSString stringWithFormat:@"%@/%@",dir,file] stringByExpandingTildeInPath];
	    if([[NSFileManager defaultManager] movePath:path toPath:dest handler:nil]){
		[article associatePDF:dest];
	    }
	}
    }
    self.finished=YES;
}    

@end
