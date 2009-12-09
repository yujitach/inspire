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
#import "RegexKitLite.h"
#import "AppDelegate.h"

@interface SpiresQueryDownloader ()
- (void) xmlAlertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void*)ignored;
@end

@implementation SpiresQueryDownloader


-(id)initWithQuery:(NSString*)search delegate:(id)d didEndSelector:(SEL)selector 
{
    self=[super init];
    delegate=d;
    sel=selector;
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
    
    NSURL*url=nil;
    if([search hasPrefix:@"r"]){
	NSArray*a=[search componentsSeparatedByString:@" "];
	NSString*s=nil;
	if([a count]>1){
	    int i=1;
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
    NSLog(@"fetching:%@",url);
    urlRequest=[NSURLRequest requestWithURL:url
				cachePolicy:NSURLRequestUseProtocolCachePolicy
			    timeoutInterval:240];
    
    temporaryData=[NSMutableData data];
    connection=[NSURLConnection connectionWithRequest:urlRequest
					     delegate:self];
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
-(void)connectionDidFinishLoading:(NSURLConnection*)c
{
    NSError*error=nil;
    NSXMLDocument*doc=nil;
    if([temporaryData length]){
	//	NSString*t=[[NSString alloc] initWithData:temporaryData encoding:NSUTF8StringEncoding];
	// spires' results sometimes contain 0xA0, non-breaking space...
	NSString*t=[[NSString alloc] initWithData:temporaryData encoding:NSISOLatin1StringEncoding];
	/*	NSArray*a=[t componentsSeparatedByString:@"</title>"];
	 NSMutableArray*b=[NSMutableArray array];
	 for(NSString*i in a){
	 NSRange r=[i rangeOfString:@"<title>" options:NSBackwardsSearch];
	 if(r.location!=NSNotFound){
	 NSString*front=[i substringToIndex:r.location+[@"<title>" length]];
	 NSString*back=[i substringFromIndex:r.location+[@"<title>" length]];
	 back=[back stringByReplacingOccurrencesOfString:@"&" withString:@"&amp;"];
	 back=[back stringByReplacingOccurrencesOfString:@"<" withString:@"&lt;"];
	 back=[back stringByReplacingOccurrencesOfString:@">" withString:@"&gt;"];
	 [b addObject:[front stringByAppendingString:back]];
	 }else{
	 [b addObject:i];
	 }
	 }
	 NSString*s=[b componentsJoinedByString:@"</title>"];
	 if(![t isEqualToString:s]){
	 NSLog(@"malformed XML patched");
	 }*/
	
	NSString*s=[t stringByReplacingOccurrencesOfRegex:@"\\[<.+? ([A-Z]) .+?>\\]" withString:@"$1"];
	s=[s stringByReplacingOccurrencesOfRegex:@"\\[<.+? ([A-Z])>\\]" withString:@"$1"];
	s=[s stringByReplacingOccurrencesOfRegex:@"\\[<([A-Z]) .+?>\\]" withString:@"$1"];
	s=[s stringByReplacingOccurrencesOfRegex:@"\\[<ANGSTROM SIGN>\\]" withString:@"A"];
	s=[s stringByReplacingOccurrencesOfRegex:@"&([^;]{10})" withString:@"&amp;$1"];
	if(![t isEqualToString:s]){
	    NSLog(@"malformed XML patched");
	    [s writeToFile:@"/tmp/spires-xml-before.xml" atomically:NO encoding:NSUTF8StringEncoding error:nil];
	    [t writeToFile:@"/tmp/spires-xml-after.xml" atomically:NO encoding:NSUTF8StringEncoding error:nil];
	    t=s;
	    
	}
	
	if([searchString hasPrefix:@"r"]){
	    t=[self transformBibtexToXML:t];
	}
	doc=[[NSXMLDocument alloc] initWithXMLString:t options:0 error:&error];
	if(!doc){
	    NSLog(@"xml problem:%@",error);
	    NSString*text=[NSString stringWithFormat:@"Please report it and help develop this app.\n"
			   @"Clicking Yes will open up an email.\n"
			   ];
	    NSAlert*alert=[NSAlert alertWithMessageText:@"SPIRES returned malformed XML"
					  defaultButton:@"Yes"
					alternateButton:@"No thanks"
					    otherButton:nil informativeTextWithFormat:text];
	    //[alert setAlertStyle:NSCriticalAlertStyle];
	    [alert beginSheetModalForWindow:[[NSApp appDelegate] mainWindow]
			      modalDelegate:self 
			     didEndSelector:@selector(xmlAlertDidEnd:returnCode:contextInfo:)
				contextInfo:nil];
	    [t writeToFile:@"/tmp/spires-xml.xml" atomically:NO encoding:NSUTF8StringEncoding error:nil];
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
		    @"mailto:yujitach@ias.edu?subject=spires.app Bugs/Suggestions for v.%@&body=Following SPIRES query returned an XML error:\r\n%@",
		    version,urlString]
		   stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]]];
	
    }
}


-(void)connection:(NSURLConnection*)c didFailWithError:(NSError*)error
{
    [delegate performSelector:sel withObject:nil];
    NSAlert*alert=[NSAlert alertWithMessageText:@"Connection Error to SPIRES"
				  defaultButton:@"OK"
				alternateButton:nil
				    otherButton:nil informativeTextWithFormat:[error localizedDescription]];
    //[alert setAlertStyle:NSCriticalAlertStyle];
    [alert beginSheetModalForWindow:[[NSApp appDelegate] mainWindow]
		      modalDelegate:nil 
		     didEndSelector:nil
			contextInfo:nil];
}

@end
