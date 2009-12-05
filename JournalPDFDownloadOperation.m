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
#import "AppDelegate.h"
#import "RegexKitLite.h"
#import "Article.h"
#import "JournalEntry.h"
#import "NSString+XMLEntityDecoding.h"
#import "PDFHelper.h"
#import "NSURL+libraryProxy.h"

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
-(NSString*)destinationPath
{
    // this method should belong, more properly, either to Article or to JournalEntry...
    NSString*dir=[[NSUserDefaults standardUserDefaults] objectForKey:@"pdfDir"];
    JournalEntry*j=article.journal;
    NSString*file=[NSString stringWithFormat:@"%@ %@ (%@) %@.pdf",j.name,j.volume,j.year,j.page];
    NSString*dest=[[NSString stringWithFormat:@"%@/%@",dir,file] stringByExpandingTildeInPath];
    return dest;
}
-(void)run
{
    
    
    NSString*doiURL=[@"http://dx.doi.org/" stringByAppendingString:article.doi];
 //   NSLog(@"url:%@",url);
    self.isExecuting=YES;
    NSString*dest=[self destinationPath];
    if([[NSFileManager defaultManager] fileExistsAtPath:dest]){
	[article associatePDF:dest];
	[self finish];
	return;
    }
    [ProgressIndicatorController startAnimation:self];
    [(id<AppDelegate>)[NSApp delegate] postMessage:@"Looking up journal webpage..."]; 
    downloader=[[SecureDownloader alloc] initWithURL:[[NSURL URLWithString:doiURL] proxiedURLForELibrary]
				      didEndSelector:@selector(journalHTMLDownloadDidEnd:) 
					    delegate:self ];
    [downloader download];
}
-(void)journalHTMLDownloadDidEnd:(NSString*)path
{
    [(id<AppDelegate>)[NSApp delegate] postMessage:nil]; 
    [ProgressIndicatorController stopAnimation:self];
    if(path){
	[self performSelector:@selector(continuation:)
		   withObject: path
		   afterDelay:.5];
    }else{
	[self finish];
	return;
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
    if(!pdf){ //IOP
	NSString*s=[html stringByMatching:@"<meta name=\"citation_pdf_url\"(.+?)/>" capture:1];
	if(s){
	    pdf=[s stringByMatching:@"content=\"(.+pdf)\"" capture:1];
	}
    }
    if(!pdf){ // World Scientific
	NSArray*a=[html componentsSeparatedByString:@"<td class=\"jntitle\">"];
	if([a count]>1){
	    NSString*j=[[a objectAtIndex:1]
			stringByMatching:@"\\((.+?)\\)" capture:1];
	    j=[j lowercaseString];
	    NSString*s=[html stringByMatching:@"preserved-docs/(.+?\\.pdf)\"" capture:1];
	    NSString*t=[s substringToIndex:2];
	    if(s&&j&&t){
		pdf=[NSString stringWithFormat:@"http://worldscinet.com/%@/%@/preserved-docs/%@",j,t,s];
	    }
	}
    }
    if(!pdf){// PTP, PTPS
	NSString*s=[html stringByMatching:@"PTP(S*/.+?)/pdf\"" capture:1];
	if(s){
	    pdf=[NSString stringWithFormat:@"http://ptp.ipap.jp/link?PTP%@/pdf",s];
	}
    }
    if(!pdf){
	NSLog(@"failed to download PDF. instead opens the journal webpage");
	NSString* doiURL=[@"http://dx.doi.org/" stringByAppendingString:article.doi];
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:doiURL]];
	[(id<AppDelegate>)[NSApp delegate] showInfoOnAssociation]; //cheating here...
	[self finish];
	return;
    }
    pdf=[pdf stringByExpandingAmpersandEscapes];
    NSLog(@"pdf detected at:%@",pdf);
    NSURL* proxiedURL=[[NSURL URLWithString:pdf] proxiedURLForELibrary];
    NSLog(@"proxied:%@",proxiedURL);
    downloader=[[SecureDownloader alloc] initWithURL:proxiedURL
				      didEndSelector:@selector(journalPDFDownloadDidEnd:) 
					    delegate:self ];
    [ProgressIndicatorController startAnimation:self];
    [(id<AppDelegate>)[NSApp delegate] postMessage:@"Downloading PDF..."]; 
    [downloader download];	
}
-(void)journalPDFDownloadDidEnd:(NSString*)path
{
    [(id<AppDelegate>)[NSApp delegate] postMessage:nil]; 
    [ProgressIndicatorController stopAnimation:self];
    if(path){
	NSData*data=[[NSData dataWithContentsOfFile:path] subdataWithRange:NSMakeRange(0,4)];
	NSString*head=[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	if(![head hasPrefix:@"%PDF"]){
	    NSLog(@"failed to download PDF. instead opens the journal webpage");
	    NSString* doiURL=[@"http://dx.doi.org/" stringByAppendingString:article.doi];
	    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:doiURL]];
	    [(id<AppDelegate>)[NSApp delegate] showInfoOnAssociation]; //cheating here...
	}else{
	    NSString*dest=[self destinationPath];
	    if([[NSFileManager defaultManager] moveItemAtPath:path toPath:dest error:NULL]){
		[article associatePDF:dest];
	    }
	}
    }
    [self finish];
}    
-(void)cleanupToCancel
{
    [ProgressIndicatorController stopAnimation:self];
}
@end
