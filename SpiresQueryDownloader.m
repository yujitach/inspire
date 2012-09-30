//
//  SpiresQueryDownloader.m
//  spires
//
//  Created by Yuji on 7/3/09.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import "SpiresQueryDownloader.h"
#import "SpiresHelper.h"
#import "NSString+magic.h"
#import "AppDelegate.h"
#import "Article.h"

@interface SpiresQueryDownloader ()
- (void) xmlAlertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void*)ignored;
//- (void) tooManyAlertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void*)ignored;
@end

@implementation SpiresQueryDownloader
-(NSURL*)urlForSpiresForString:(NSString*)search
{
    NSURL*url=nil;
    if([search hasPrefix:@"r"]){
	NSArray*a=[search componentsSeparatedByString:@" "];
	NSString*s=nil;
	if([a count]>1){
	    NSUInteger i=1;
	    for(i=1;i<[a count];i++){
		s=[a objectAtIndex:i];
		if(![s isEqualToString:@""])break;
	    }
	    if([s isEqualToString:@"key"]){
		if(i+1>[a count]-1)return nil;
		s=[s stringByAppendingFormat:@"=%@",[a objectAtIndex:i+1]];
	    }
	}
	NSString*x=[SPIRESREFHEAD stringByAppendingString:s];
	url=[NSURL URLWithString:[x stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    }else{
	NSString*trailer=[[NSUserDefaults standardUserDefaults] stringForKey:@"spiresQueryTrailer"];
	if(trailer && ![trailer isEqualToString:@""]){
	    search=[search stringByAppendingFormat:@" and %@",trailer];
	}
	NSString*escapedSearch=[search stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding ];
	escapedSearch=[escapedSearch stringByReplacingOccurrencesOfString:@"+" withString:@"%2B"];
	escapedSearch=[escapedSearch stringByReplacingOccurrencesOfString:@"(" withString:@"%28"];
	escapedSearch=[escapedSearch stringByReplacingOccurrencesOfString:@")" withString:@"%29"];
	escapedSearch=[escapedSearch stringByReplacingOccurrencesOfString:@"/" withString:@"%2F"];
	url=  [NSURL URLWithString:[NSString stringWithFormat:@"%@%@&server=sunspi5", SPIRESXMLHEAD, escapedSearch]];
    }
    return url;
}
#define MAXPERQUERY 50
-(NSURL*)urlForInspireForString:(NSString*)search
{
    NSString*inspireQuery=nil;
    if([search hasPrefix:@"r"]||[search hasPrefix:@"c "]){
	NSString*rec=nil;
	NSNumber*inspireKey=article.inspireKey;
	if(inspireKey && [inspireKey integerValue]!=0){
	    rec=[NSString stringWithFormat:@"recid:%@",inspireKey];
	}else if(article.eprint && ![article.eprint isEqualToString:@""]){
	    rec=[NSString stringWithFormat:@"%@",article.eprint];
	}else if(article.spiresKey && [article.spiresKey integerValue]!=0){
            NSString*query=[NSString stringWithFormat:@"find key %@&rg=1&of=xm",article.spiresKey];
            NSURL*url=[[SpiresHelper sharedHelper] inspireURLForQuery:query];
            NSXMLDocument*doc=[[NSXMLDocument alloc] initWithContentsOfURL:url
								   options:0
								     error:NULL];
	    NSArray*a=[[doc rootElement] nodesForXPath:@"record/controlfield" error:NULL];
	    NSLog(@"%@",a);
	    if([a count]>0){
		NSXMLElement*e=[a objectAtIndex:0];
		NSLog(@"%@",e);
		NSNumber*n=[NSNumber numberWithInteger:[[e stringValue] integerValue]];
		article.inspireKey=n;
		rec=[NSString stringWithFormat:@"recid:%@",n];
	    }
	}else{
	    return nil;
	}
	NSString*head=nil;
	if([search hasPrefix:@"r"]){
	    head=@"citedby";
	}else{
	    head=@"refersto";
	}
	inspireQuery=[NSString stringWithFormat:@"%@:%@",head,rec];
    }else if([search hasPrefix:@"doi"]){
        inspireQuery=[search stringByReplacingOccurrencesOfRegex:@"^doi " withString:@"doi:"];
    }else{
        if(![search hasPrefix:@"find"]){
            inspireQuery=[NSString stringWithFormat:@"find+%@",search];
        }else{
            inspireQuery=search;
        }
    }
    NSString*str=[NSString stringWithFormat:@"%@&rg=%d&of=xm",inspireQuery,MAXPERQUERY];
    return [[SpiresHelper sharedHelper] inspireURLForQuery:str];
}
-(id)initWithQuery:(NSString*)search forArticle:(Article*)a delegate:(id)d didEndSelector:(SEL)selector 
{
    self=[super init];
    delegate=d;
    sel=selector;
    article=a;
    search=[search normalizedString];
    // 29/6/2009
    // differences in the query strings of the real web spires and those of my spires app should be addressed more properly
    // than this
    search=[search stringByReplacingOccurrencesOfRegex:@"^e " withString:@"eprint "];
    search=[search stringByReplacingOccurrencesOfRegex:@" e " withString:@" eprint "];
    search=[search stringByReplacingOccurrencesOfRegex:@"^ep " withString:@"eprint "];
    search=[search stringByReplacingOccurrencesOfRegex:@" ep " withString:@" eprint "];
    // end target of the comment above
    searchString=search;
    inspire=[[NSApp appDelegate] useInspire];
    NSURL*url=inspire?[self urlForInspireForString:search]:[self urlForSpiresForString:search];
    NSLog(@"fetching:%@",url);
    urlRequest=[NSURLRequest requestWithURL:url
				cachePolicy:NSURLRequestUseProtocolCachePolicy
			    timeoutInterval:240];
    
    temporaryData=[NSMutableData data];
    connection=[NSURLConnection connectionWithRequest:urlRequest
					     delegate:self];
    [[NSApp appDelegate] startProgressIndicator];
    [[NSApp appDelegate] postMessage:[NSString stringWithFormat:@"Waiting reply from %@...",(inspire?@"inspire":@"spires")]];
    return self;
}
#pragma mark Bibtex parser

-(NSString*)transformBibtexToXML:(NSString*)s
{
    //    NSLog(@"ok...");
    /*    NSTask* task=[[NSTask alloc] init];
     [task setLaunchPath:@"/usr/bin/perl"];
     [task setCurrentDirectoryPath:@"/tmp"];
     [task setArguments: [NSArray arrayWithObjects: [[NSBundle mainBundle] pathForResource:@"wwwrefsbibtex2xmlpublic" ofType:@"perl"],  nil]];
     NSPipe*pipe=[NSPipe pipe];
     [task setStandardOutput:pipe];
     [task setStandardInput:pipe];
     [task launch];
     [[pipe fileHandleForWriting] writeData:[s dataUsingEncoding:NSUTF8StringEncoding]];
     [[pipe fileHandleForWriting] closeFile];
     [task waitUntilExit];
     NSData*data=[[pipe fileHandleForReading] readDataToEndOfFile];
     
     NSString*result= [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];*/
    // prays the path to the app doesn't contain any ' ...
    NSString*inPath=[NSString stringWithFormat:@"/tmp/inSPIRES-%d",getuid()];
    NSString*outPath=[NSString stringWithFormat:@"/tmp/outSPIRES-%d",getuid()];
    NSString*script=[[NSBundle mainBundle] pathForResource:@"wwwrefsbibtex2xmlpublic" ofType:@"perl"];
    NSString* command=[NSString stringWithFormat:@"/usr/bin/perl %@ <%@ >%@" , [script quotedForShell], inPath,outPath];
    NSError*error=nil;
    [s writeToFile:inPath atomically:NO encoding:NSUTF8StringEncoding error:&error];
    system([command UTF8String]);
    NSString*result=[[NSString alloc] initWithContentsOfFile:outPath encoding:NSUTF8StringEncoding error:&error];
    //   NSLog(@"%@",result);
    return result;
}

#pragma mark URL connection delegates
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [temporaryData appendData:data];
}
-(NSXMLDocument*)docFromSpiresData:(NSError**)error
{
    //	NSString*t=[[NSString alloc] initWithData:temporaryData encoding:NSUTF8StringEncoding];
    NSString*t=[[NSString alloc] initWithData:temporaryData encoding:NSISOLatin1StringEncoding];
    
    
    if([searchString hasPrefix:@"r"]){
	t=[self transformBibtexToXML:t];
    }
    return [[NSXMLDocument alloc] initWithXMLString:t options:0 error:error];
}
-(NSURL*)xslURL
{
    static NSURL*xslURL=nil;
    if(!xslURL){
	xslURL=[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"marc2spires" ofType:@"xsl"]];
    }
    return xslURL;
}
-(void)dealWithTooManyResults
{
/*    NSString*text=[NSString stringWithFormat:@"The server found %d entries for your query; so far only %d entries are downloaded.\n Do you want to continue downloading the rest? Mostly the rest are very old.", (int)total, (int)sofar
		   ];
    NSAlert*alert=[NSAlert alertWithMessageText:@"Many results found"
				  defaultButton:@"No thanks"
				alternateButton:@"Continue"
				    otherButton:nil informativeTextWithFormat:text];
    //[alert setAlertStyle:NSCriticalAlertStyle];
    [alert beginSheetModalForWindow:[[NSApp appDelegate] mainWindow]
		      modalDelegate:self 
		     didEndSelector:@selector(tooManyAlertDidEnd:returnCode:contextInfo:)
			contextInfo:nil];
}

- (void) tooManyAlertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void*)ignored
{
    if(returnCode==NSAlertAlternateReturn){*/
	NSString*urlString=[[urlRequest URL] absoluteString];
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),^{
	    while(sofar<total){
		NSError*error;
		dispatch_async(dispatch_get_main_queue(),^{
		    [[NSApp appDelegate] startProgressIndicator];
		    [[NSApp appDelegate] postMessage:[NSString stringWithFormat:@"%d entries out of %d downloaded",(int)sofar,(int)total ]];
		});
		NSURL*url=[NSURL URLWithString:[NSString stringWithFormat:@"%@&jrec=%d",urlString,(int)sofar+1]];
		NSXMLDocument*doc=[[NSXMLDocument alloc] initWithContentsOfURL:url
								       options:0
									 error:&error];
		NSXMLDocument*transformed=[doc objectByApplyingXSLTAtURL:[self xslURL]
							       arguments:nil
								   error:&error];
		NSArray*a=[[transformed rootElement] nodesForXPath:@"document" error:NULL];
		sofar+=[a count];
		dispatch_async(dispatch_get_main_queue(),^{
		    [[NSApp appDelegate] postMessage:nil];
		    [[NSApp appDelegate] stopProgressIndicator];
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
		    [delegate performSelector:sel withObject:transformed];
		});		
	    }
	});
//    }
}


-(NSXMLDocument*)docFromInspireData:(NSError**)error
{
    if(total==0){
	NSString*s=[[NSString alloc] initWithData:temporaryData encoding:NSUTF8StringEncoding];
	NSString*t=[s stringByMatching:@"<!--.+?: *(\\d+?) *-->" capture:1];
	total=[t intValue];
    }
    NSXMLDocument*doc=[[NSXMLDocument alloc] initWithData:temporaryData 
						  options:0
						    error:error];
    if(!doc)
	return nil;
    NSXMLDocument*transformed=[doc objectByApplyingXSLTAtURL:[self xslURL]
						   arguments:nil
						       error:error];    
    
    NSArray*a=[[transformed rootElement] nodesForXPath:@"document" error:NULL];
    sofar=[a count];
    if(sofar!= total){
	[self dealWithTooManyResults];
    }
    return transformed;
}
-(void)connectionDidFinishLoading:(NSURLConnection*)c
{
    [[NSApp appDelegate] postMessage:nil];
    [[NSApp appDelegate] stopProgressIndicator];

    NSError*error;
    NSXMLDocument*doc=nil;
    if([temporaryData length]){
	doc=inspire?[self docFromInspireData:&error]:[self docFromSpiresData:&error];
	if(!doc){
	    NSLog(@"xml problem:%@",error);
	    NSString*text=[NSString stringWithFormat:@"Please report it and help develop this app.\n"
			   @"Clicking Yes will open up an email.\n"
			   ];
	    NSAlert*alert=[NSAlert alertWithMessageText:[NSString stringWithFormat:@"%@ returned malformed XML",inspire?@"Inspire":@"SPIRES"]
					  defaultButton:@"Yes"
					alternateButton:@"No thanks"
					    otherButton:nil informativeTextWithFormat:@"%@",text];
	    //[alert setAlertStyle:NSCriticalAlertStyle];
	    [alert beginSheetModalForWindow:[[NSApp appDelegate] mainWindow]
			      modalDelegate:self 
			     didEndSelector:@selector(xmlAlertDidEnd:returnCode:contextInfo:)
				contextInfo:nil];
	}
    }
    [delegate performSelector:sel withObject:doc];
    temporaryData=nil;
    connection=nil;
    
}

- (void) xmlAlertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void*)ignored
{
    if(returnCode==NSAlertDefaultReturn){
	NSString*urlString=[[urlRequest URL]  absoluteString];
	NSString* version=[[[NSBundle mainBundle] infoDictionary] valueForKey:@"CFBundleVersion"];
	[[NSWorkspace sharedWorkspace]
	 openURL:[NSURL URLWithString:
		  [[NSString stringWithFormat:
		    @"mailto:yujitach@ias.edu?subject=spires.app Bugs/Suggestions for v.%@&body=Following SPIRES/Inspire query returned an XML error:\r\n%@",
		    version,urlString]
		   stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]]];
	
    }
}


-(void)connection:(NSURLConnection*)c didFailWithError:(NSError*)error
{
    [delegate performSelector:sel withObject:nil];
    [[NSApp appDelegate] postMessage:nil];
    [[NSApp appDelegate] stopProgressIndicator];

    NSAlert*alert=[NSAlert alertWithMessageText:[NSString stringWithFormat:@"Connection Error to %@",inspire?@"Inspire":@"SPIRES"]
				  defaultButton:@"OK"
				alternateButton:nil
				    otherButton:nil informativeTextWithFormat:@"%@",[error localizedDescription]];
    //[alert setAlertStyle:NSCriticalAlertStyle];
    [alert beginSheetModalForWindow:[[NSApp appDelegate] mainWindow]
		      modalDelegate:nil 
		     didEndSelector:nil
			contextInfo:nil];
}

@end
