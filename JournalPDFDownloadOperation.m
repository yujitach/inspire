//
//  JournalPDFDownloadOperation.m
//  spires
//
//  Created by Yuji on 09/02/07.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import "JournalPDFDownloadOperation.h"
#import "SecureDownloader.h"
#import "AppDelegate.h"
#import "RegexKitLite.h"
#import "Article.h"
#import "JournalEntry.h"
#import "NSString+magic.h"
#import "PDFHelper.h"
#import "NSURL+libraryProxy.h"

@interface JournalPDFDownloadOperation()
-(void)continuation:(NSString*)path;
-(void)preContinuation:(NSString*)path;
@end


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
-(void)failed
{
    //	NSLog(@"failed to download PDF. instead opens the journal webpage");
    NSString* doiURL=[@"http://dx.doi.org/" stringByAppendingString:article.doi];
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:doiURL]];
    [[NSApp appDelegate] showInfoOnAssociation]; //cheating here...    
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
    [[NSApp appDelegate] startProgressIndicator];
    [[NSApp appDelegate] postMessage:@"Looking up journal webpage..."]; 
    downloader=[[SecureDownloader alloc] initWithURL:[[NSURL URLWithString:doiURL] proxiedURLForELibrary]
				   completionHandler:^(NSString*path){
				       [[NSApp appDelegate] postMessage:nil]; 
				       [[NSApp appDelegate] stopProgressIndicator];
				       if(path){
					   [self performSelector:@selector(preContinuation:)
						      withObject: path
						      afterDelay:0];
				       }else{
					   [self failed];
					   [self finish];
					   return;
				       }
				   } ];
    [downloader download];				       
}
-(void)preContinuation:(NSString*)originalPath
{
    NSString*html=[NSString stringWithContentsOfFile:originalPath encoding:NSUTF8StringEncoding error:nil];
    if([html rangeOfString:@"Get the article at ScienceDirect"].location!=NSNotFound){
	NSString*s=[html stringByMatching:@"value=\"(http://.+?)\"" capture:1];
	NSLog(@"stupid Elsevier locator found:%@",s);
	s=[s stringByReplacingOccurrencesOfString:@"&amp;" withString:@"&"];
	NSURL*newURL=[NSURL URLWithString:s];
	[[NSApp appDelegate] startProgressIndicator];
	[[NSApp appDelegate] postMessage:@"resolving Elsevier locator..."]; 
	downloader=[[SecureDownloader alloc] initWithURL:newURL
				       completionHandler:^(NSString*path){
					   [[NSApp appDelegate] postMessage:nil]; 
					   [[NSApp appDelegate] stopProgressIndicator];
					   if(path){
					       [self performSelector:@selector(continuation:)
							  withObject: path
							  afterDelay:.5];
					   }else{
					       [self failed];
					       [self finish];
					       return;
					   }
				       } ];
	[downloader download];		
    }else{
	[self continuation:originalPath];
    }
}
-(void)continuation:(NSString*)path
{
    NSString*html=[NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    NSString*pdf=nil;
    if(!pdf){//Annual Reviews
	NSString*s=[html stringByMatching:@"/doi/pdf(.+?)\"" capture:1];
	if(s){
	    pdf=[NSString stringWithFormat:@"http://arjournals.annualreviews.org/doi/pdf%@",s];
	}
    }    
    if(!pdf){ //APS
	NSString*s=[html stringByMatching:@"(/pdf/.+?)\">PDF" capture:1];
	if(s){
	    pdf= [[[NSURL alloc] initWithString:s relativeToURL:[downloader url]] absoluteString];
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
	NSArray*x=[html componentsSeparatedByString:@"featureCount"];
	if([x count]>=2){
	    NSString*chunk=[x objectAtIndex:1];
	    NSString*s=[chunk stringByMatching:@"(/science.+?sdarticle.pdf)\"" capture:1];
	    if(s){
		pdf=[@"http://www.sciencedirect.com" stringByAppendingString:s];
	    }		
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
	[self failed];
	[self finish];
	return;
    }
    pdf=[pdf stringByExpandingAmpersandEscapes];
    NSLog(@"pdf detected at:%@",pdf);
    NSURL* proxiedURL=[[NSURL URLWithString:pdf] proxiedURLForELibrary];
    NSLog(@"proxied:%@",proxiedURL);
    [[NSApp appDelegate] startProgressIndicator];
    [[NSApp appDelegate] postMessage:@"Downloading PDF..."]; 
    downloader=[[SecureDownloader alloc] initWithURL:proxiedURL
				   completionHandler:^(NSString*pdfPath){
				       [[NSApp appDelegate] postMessage:nil]; 
				       [[NSApp appDelegate] stopProgressIndicator];
				       if(pdfPath){
					   NSData*data=[[NSData dataWithContentsOfFile:pdfPath] subdataWithRange:NSMakeRange(0,4)];
					   NSString*head=[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
					   if(![head hasPrefix:@"%PDF"]){
					       [self failed];
					   }else{
					       NSString*dest=[self destinationPath];
					       if([[NSFileManager defaultManager] moveItemAtPath:pdfPath toPath:dest error:NULL]){
						   [article associatePDF:dest];
					       }else{
						   if(![[NSFileManager defaultManager] fileExistsAtPath:dest]){
						       [[NSApp appDelegate] presentFileSaveError];
						   }
					       }
					   }
				       }
				       [self finish];				       
				   }];
    [downloader download];	
}
-(void)cleanupToCancel
{
    [[NSApp appDelegate] stopProgressIndicator];
}
@end
