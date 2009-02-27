//
//  SpiresHelper.m
//  spires
//
//  Created by Yuji on 08/10/16.
//  Copyright 2008 Y. Tachikawa. All rights reserved.
//

#import "SpiresHelper.h"
#import "RegexKitLite.h"
#import "NSString+magic.h"
#define SPIRESXMLHEAD @"http://www.slac.stanford.edu/spires/find/hep/xmlpublic?rawcmd=find+"
#define SPIRESREFHEAD @"http://www.slac.stanford.edu/spires/find/hep/wwwrefsbibtex?"
#define SPIRESWWWHEAD @"http://www.slac.stanford.edu/spires/find/hep/www?rawcmd=find+"
#define SPIRESBIBTEXHEAD @"http://www.slac.stanford.edu/spires/find/hep/wwwbriefbibtex?rawcmd=find+"
#define SPIRESLATEX2HEAD @"http://www.slac.stanford.edu/spires/find/hep/wwwbrieflatex2?rawcmd=find+"
#define SPIRESHARVMACHEAD @"http://www.slac.stanford.edu/spires/find/hep/wwwbriefharvmac?rawcmd=find+"

SpiresHelper*_sharedSpiresHelper=nil;
@implementation SpiresHelper
+(SpiresHelper*)sharedHelper
{
    if(!_sharedSpiresHelper){
	_sharedSpiresHelper=[[SpiresHelper alloc]init];
    }
    return _sharedSpiresHelper;
}
-(NSPredicate*) simplePredicateFromSPIRESsearchString:(NSString*)string
{
  //  NSCharacterSet* an=[NSCharacterSet alphanumericCharacterSet];
    //NSScanner* scanner=[NSScanner scannerWithString:string];
    NSString* operand=nil;
    NSString* operator=nil;
    /*[scanner scanUpToCharactersFromSet:an intoString:NULL];
    [scanner scanCharactersFromSet:an intoString:&operator];
    [scanner scanUpToCharactersFromSet:an intoString:NULL];*/
//    NSLog(@"%@",string);
    int location=[string rangeOfString:@" "].location;
    if(location==NSNotFound){
	return nil;
    }
    operator=[string substringToIndex:location];
    operand=[string substringFromIndex:location+1];
    if(operator==nil || operand==nil || [operator isEqualTo:@""] || [operand isEqualTo:@""]) return [NSPredicate predicateWithValue:YES];
    NSString*key=@"";
    operand=[operand stringByReplacingOccurrencesOfString:@"#" withString:@""];

    if([operator hasPrefix:@"to"]){
	NSArray* a=[operand componentsSeparatedByString:@"+"];
	if([a count]==0)
	    return [NSPredicate predicateWithValue:YES];
	NSNumber *num=[NSNumber numberWithInt:[[a objectAtIndex:0] intValue]];
	return [NSPredicate predicateWithFormat:@"citecount > %@",num];
    }else if([operator hasPrefix:@"ea"]){
	operand=[operand stringByReplacingOccurrencesOfString:@" " withString:@" "];
	if([operand rangeOfString:@","].location==NSNotFound){
	    NSArray* a=[operand componentsSeparatedByString:@" "];
	    if([a count]==0)
		return [NSPredicate predicateWithValue:YES];
	    if([a count]==1){
		operand=[a objectAtIndex:0];
	    }else{
		operand=[[a lastObject] stringByAppendingString:@","];
		for(int i=0;i<[a count]-1;i++){
		    operand=[operand stringByAppendingString:@" "];
		    operand=[operand stringByAppendingString:[a objectAtIndex:i]];
		}
	    }
	}
//	return [NSPredicate predicateWithFormat:@"longishAuthorListForEA contains[cd] %@",operand];	
	return [NSPredicate predicateWithFormat:@"longishAuthorListForEA contains %@",[operand normalizedString]];	
    }else if([operator hasPrefix:@"j"]){
	operand=[operand stringByReplacingOccurrencesOfString:@" " withString:@" "];
	NSArray* a=[operand componentsSeparatedByString:@" "];
	if([a count]==0)
	    return [NSPredicate predicateWithValue:YES];
	NSMutableString*ms=[NSMutableString string];
	for(NSString*s in a){
	    [ms appendString:s];
	/*    if(![ms hasSuffix:@"."])
		[ms appendString:@"."];*/
	}
	return [NSPredicate predicateWithFormat:@"journal.name contains[c] %@",ms];	
    }else if([operator hasPrefix:@"c"]){
	if([operand rangeOfString:@":"].location!=NSNotFound || [operand rangeOfString:@"/"].location!=NSNotFound)
	    return [NSPredicate predicateWithFormat:@"ANY refersTo.eprint beginswith[c] %@",operand];
	else
	    return [NSPredicate predicateWithFormat:@"ANY refersTo.spicite beginswith[c] %@",operand];
    }else if([operator hasPrefix:@"r"]){
	if([operand rangeOfString:@":"].location!=NSNotFound || [operand rangeOfString:@"/"].location!=NSNotFound){
	    return [NSPredicate predicateWithFormat:@"ANY citedBy.eprint beginswith[c] %@",operand];
	}else if([operand hasPrefix:@"key"]){
	    NSArray* a=[operand componentsSeparatedByString:@" "];
	    if([a count]==2){
		return [NSPredicate predicateWithFormat:@"ANY citedBy.spiresKey = %@",[a objectAtIndex:1]];
	    }
	}
	return [NSPredicate predicateWithValue:NO];
    }else if([operator hasPrefix:@"t"]){
//	key=@"title";
	key=@"normalizedTitle";
    }else if([operator hasPrefix:@"e"]){
	key=@"eprint";
    }else{
	key=@"longishAuthorListForA";
/*	NSArray*a=[operand componentsSeparatedByString:@","];
	if([a count]>=2){
	    operand=[NSString stringWithFormat:@"%@ %@",[a objectAtIndex:1],[a objectAtIndex:0]];
	}
	operand=[operand stringByReplacingOccurrencesOfString:@"  " withString:@" "];
	a=[operand componentsSeparatedByString:@" "];
	if([a count]<2){
	    return [NSPredicate predicateWithFormat:@"%K contains[c] %@",key,operand];
	}
	NSMutableString*ms=[NSMutableString string];
	for(int i=0;i<[a count]-1;i++){
	    NSString*s=[a objectAtIndex:i];
	    if([s isEqualToString:@""])continue;
	    [ms appendString:[s substringToIndex:1]];
	    [ms appendString:@". "];
	}
	[ms appendString:[a lastObject]];*/
	
//	NSLog(@"%@",ms);
	NSMutableString*result=[NSMutableString string];
	NSArray* c=[operand componentsSeparatedByString:@", "];
	NSString*last=nil;
	NSArray*d=nil;
	if([c count]==1){
	    while([operand hasSuffix:@" "]){
		operand=[operand substringToIndex:[operand length]-1];
	    }
	    NSArray*x=[operand componentsSeparatedByString:@" "];
	    if([x count]==1){
//		return [NSPredicate predicateWithFormat:@"%K contains[cd] %@",key,operand];
		return [NSPredicate predicateWithFormat:@"%K contains %@",key,[operand normalizedString]];
	    }
	    last=[x lastObject];
	    NSMutableArray*y=[NSMutableArray array];
	    for(int i=0;i<[x count]-1;i++){
		[y addObject:[x objectAtIndex:i]];
	    }
	    d=y;
	}else{
	    last=[c objectAtIndex:0];
	    d=[[c objectAtIndex:1] componentsSeparatedByString:@" "];
	}
	for(NSString*i in d){
	    if(!i || [i isEqualToString:@""]) continue;
	    [result appendString:[i substringToIndex:1]];
	    [result appendString:@". "];
	}
	
	
//	NSPredicate*pred= [NSPredicate predicateWithFormat:@"(%K contains[cd] %@) and (%K contains[cd] %@)",key,last,key,result];	
	NSPredicate*pred= [NSPredicate predicateWithFormat:@"(%K contains %@) and (%K contains %@)",key,[last normalizedString],key,[result normalizedString]];	
//	NSLog(@"%@",pred);
	return pred;
    }
    operand=[[operand componentsSeparatedByString:@","] objectAtIndex:0];
    operand=[[operand componentsSeparatedByString:@" "] lastObject];
    if([operand isEqualToString:@""])
	return [NSPredicate predicateWithValue:YES];
//    NSPredicate*pred=[NSPredicate predicateWithFormat:@"%K contains[cd] %@",key,operand];
    NSPredicate*pred=[NSPredicate predicateWithFormat:@"%K contains %@",key,[operand normalizedString]];
//        NSLog(@"%@",pred);
    return pred;
}
-(NSPredicate*) predicateFromSPIRESsearchString:(NSString*)string
{
    //    string=[string stringByReplacingOccurrencesOfString:@" and " withString:@" & "];
    NSArray*a=[string componentsSeparatedByString:@" and "];
    NSMutableArray*arr=[NSMutableArray array];
    for(NSString*s in a){
	NSPredicate*p=[self simplePredicateFromSPIRESsearchString:s];
	if(p)	
	    [arr addObject:p];
    }
    NSPredicate*pred=nil;
    if([arr count]==1){
	pred= [arr objectAtIndex:0];
    }else{
	pred=[[NSCompoundPredicate alloc] initWithType:NSAndPredicateType
					 subpredicates:arr];
    }
//    NSLog(@"%@",pred);
    return pred;
}
-(NSArray*)bibtexEntriesForQuery:(NSString*)search
{
    NSURL* url=[NSURL URLWithString:[[NSString stringWithFormat:@"%@%@&server=sunspi5", SPIRESBIBTEXHEAD,search ] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding ] ];
    NSString*s= [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:nil];

    NSArray*a=[s componentsSeparatedByString:@"<pre>"];
    if(!a || [a count]<2)return nil;
    NSMutableArray* result=[NSMutableArray array];
    for(int i=1;i<[a count];i++){
	NSString*x=[a objectAtIndex:i];
	NSRange r=[x rangeOfString:@"</pre>"];
	x=[x substringToIndex:r.location];
	[result addObject:x];
    }
    return result;
}

-(NSArray*)latexEUEntriesForQuery:(NSString*)search
{
    NSURL* url=[NSURL URLWithString:[[NSString stringWithFormat:@"%@%@&server=sunspi5", SPIRESLATEX2HEAD,search ] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding ] ];
    NSString*s= [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:nil];

    NSArray*a=[s componentsSeparatedByString:@"<pre>"];
    if(!a || [a count]<2)return nil;
    NSMutableArray* result=[NSMutableArray array];
    for(int i=1;i<[a count];i++){
	NSString*x=[a objectAtIndex:i];
	NSRange r=[x rangeOfString:@"</pre>"];
	x=[x substringToIndex:r.location];
	[result addObject:x];
    }
    return result;
}

-(NSArray*)harvmacEntriesForQuery:(NSString*)search
{
    NSURL* url=[NSURL URLWithString:[[NSString stringWithFormat:@"%@%@&server=sunspi5", SPIRESHARVMACHEAD,search ] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding ] ];
    NSString*s= [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:nil];
    NSArray*a=[s componentsSeparatedByString:@"<pre>"];
    if(!a || [a count]<2)return nil;
    NSMutableArray* result=[NSMutableArray array];
    for(int i=1;i<[a count];i++){
	NSString*x=[a objectAtIndex:i];
	NSRange r=[x rangeOfString:@"</pre>"];
	x=[x substringWithRange:NSMakeRange(1,r.location-1)];
	[result addObject:x];
    }
    return result;
}

-(NSURL*)spiresURLForQuery:(NSString*)search
{
    return [NSURL URLWithString:[[NSString stringWithFormat:@"%@%@", SPIRESWWWHEAD,search ] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding ] ];
}
-(void)querySPIRES:(NSString*)search delegate:(id)d didEndSelector:(SEL)selector userInfo:(id)v
{
    userInfo=v;
    delegate=d;
    sel=selector;
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
		if(i+1>[a count]-1)return;
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
    NSString* command=[NSString stringWithFormat:@"/usr/bin/perl \'%@\' </tmp/inSPIRES >/tmp/outSPIRES" , [[NSBundle mainBundle] pathForResource:@"wwwrefsbibtex2xmlpublic" ofType:@"perl"]];
    NSError*error=nil;
    [s writeToFile:@"/tmp/inSPIRES" atomically:NO encoding:NSUTF8StringEncoding error:&error];
    system([command UTF8String]);
    NSString*result=[[NSString alloc] initWithContentsOfFile:@"/tmp/outSPIRES" encoding:NSUTF8StringEncoding error:&error];
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
    NSError*error;
    NSXMLDocument*doc=nil;
    if([temporaryData length]){
	NSString*t=[[NSString alloc] initWithData:temporaryData encoding:NSUTF8StringEncoding];
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
	    [s writeToFile:@"/tmp/xml-before.xml" atomically:NO encoding:NSUTF8StringEncoding error:nil];
	    [t writeToFile:@"/tmp/xml-after.xml" atomically:NO encoding:NSUTF8StringEncoding error:nil];
	    t=s;

	}
	
	if([searchString hasPrefix:@"r"]){
	    t=[self transformBibtexToXML:t];
	}
	doc=[[NSXMLDocument alloc] initWithXMLString:t options:0 error:&error];
	if(error){
	    NSLog(@"xml problem:%@",error);
	    NSString*text=[NSString stringWithFormat:@"Please report it and help develop this app.\n"
			   @"Clicking Yes will open up an email.\n"
			   ];
	    NSAlert*alert=[NSAlert alertWithMessageText:@"SPIRES returned malformed XML"
					  defaultButton:@"Yes"
					alternateButton:@"No thanks"
					    otherButton:nil informativeTextWithFormat:text];
	    //[alert setAlertStyle:NSCriticalAlertStyle];
	    [alert beginSheetModalForWindow:[[[NSApplication sharedApplication] delegate] mainWindow]
			      modalDelegate:self 
			     didEndSelector:@selector(xmlAlertDidEnd:returnCode:contextInfo:)
				contextInfo:nil];
	    [t writeToFile:@"/tmp/xml.xml" atomically:NO encoding:NSUTF8StringEncoding error:nil];
	}
    }
    [delegate performSelector:sel withObject:doc withObject:userInfo];
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
    [delegate performSelector:sel withObject:nil withObject:userInfo];
    NSAlert*alert=[NSAlert alertWithMessageText:@"Connection Error to SPIRES"
				  defaultButton:@"OK"
				alternateButton:nil
				    otherButton:nil informativeTextWithFormat:[error localizedDescription]];
    //[alert setAlertStyle:NSCriticalAlertStyle];
    [alert beginSheetModalForWindow:[[[NSApplication sharedApplication] delegate] mainWindow]
		      modalDelegate:nil 
		     didEndSelector:nil
			contextInfo:nil];
}
@end
