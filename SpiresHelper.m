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
-(NSPredicate*)topcitePredicate:(NSString*)operand
{
    NSArray* a=[operand componentsSeparatedByString:@"+"];
    if([a count]==0)
	return nil; // [NSPredicate predicateWithValue:YES];
    NSNumber *num=[NSNumber numberWithInt:[[a objectAtIndex:0] intValue]];
    return [NSPredicate predicateWithFormat:@"citecount > %@",num];
}
-(NSPredicate*)eaPredicate:(NSString*)operand
{
    operand=[operand stringByReplacingOccurrencesOfString:@" " withString:@" "];
    if([operand rangeOfString:@","].location==NSNotFound){
	NSArray* a=[operand componentsSeparatedByString:@" "];
	if([a count]==0)
	    return nil; // [NSPredicate predicateWithValue:YES];
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
}
-(NSPredicate*)journalPredicate:(NSString*)operand
{
    operand=[operand stringByReplacingOccurrencesOfString:@" " withString:@" "];
    NSArray* a=[operand componentsSeparatedByString:@" "];
    if([a count]==0)
	return nil; //[NSPredicate predicateWithValue:YES];
    NSMutableString*ms=[NSMutableString string];
    for(NSString*s in a){
	[ms appendString:s];
	/*    if(![ms hasSuffix:@"."])
	 [ms appendString:@"."];*/
    }
    return [NSPredicate predicateWithFormat:@"journal.name contains[c] %@",ms];	    
}
-(NSPredicate*)citedByPredicate:(NSString*)operand
{
    if([operand rangeOfString:@":"].location!=NSNotFound || [operand rangeOfString:@"/"].location!=NSNotFound)
	return [NSPredicate predicateWithFormat:@"ANY refersTo.eprint beginswith[c] %@",operand];
    else
	return [NSPredicate predicateWithFormat:@"ANY refersTo.spicite beginswith[c] %@",operand];    
}
-(NSPredicate*)referesToPredicate:(NSString*)operand
{
    if([operand rangeOfString:@":"].location!=NSNotFound || [operand rangeOfString:@"/"].location!=NSNotFound){
	return [NSPredicate predicateWithFormat:@"ANY citedBy.eprint beginswith[c] %@",operand];
    }else if([operand hasPrefix:@"key"]){
	NSArray* a=[operand componentsSeparatedByString:@" "];
	if([a count]==2){
	    return [NSPredicate predicateWithFormat:@"ANY citedBy.spiresKey = %@",[a objectAtIndex:1]];
	}
    }
    return [NSPredicate predicateWithValue:NO];
}
-(NSString*)normalizedFirstAndMiddleNames:(NSArray*)d
{
    NSMutableString*result=[NSMutableString string];
    for(NSString*i in d){
	if(!i || [i isEqualToString:@""]) continue;
	[result appendString:[i substringToIndex:1]];
	[result appendString:@". "];
    }
    return result;
}
-(NSPredicate*)authorPredicate:(NSString*)operand
{
    NSString*key=@"longishAuthorListForA";
    
    NSArray* c=[operand componentsSeparatedByString:@", "];
    if([c count]==1){
	while([operand hasSuffix:@" "]){
	    operand=[operand substringToIndex:[operand length]-1];
	}
	NSArray*x=[operand componentsSeparatedByString:@" "];
	if([x count]==1){
	    //		return [NSPredicate predicateWithFormat:@"%K contains[cd] %@",key,operand];
	    NSString*last=[operand normalizedString];
	    NSString*query=[NSString stringWithFormat:@"; %@",last];
	    return [NSPredicate predicateWithFormat:@"%K contains %@",key,query];
	}
	NSString* last=[x lastObject];
	NSMutableArray*y=[NSMutableArray array];
	for(int i=0;i<[x count]-1;i++){
	    [y addObject:[x objectAtIndex:i]];
	}
	NSString* first=[self normalizedFirstAndMiddleNames:y];
//	NSString* query=[[NSString stringWithFormat:@"*; %@*, %@*", last, first] normalizedString];
//	NSPredicate*pred= [NSPredicate predicateWithFormat:@"%K like %@",key,query];	
	NSPredicate*pred= [NSPredicate predicateWithFormat:@"(%K contains %@) and (%K contains %@)",
			   key,[[@"; " stringByAppendingString:last] normalizedString],
			   key,[first normalizedString]];	
	return pred;
    }else{
	NSString* last=[c objectAtIndex:0];
	NSArray* firsts=[[c objectAtIndex:1] componentsSeparatedByString:@" "];
	NSString* first=[self normalizedFirstAndMiddleNames:firsts];
	NSString* query=[[NSString stringWithFormat:@"; %@, %@", last, first] normalizedString];
	NSPredicate*pred= [NSPredicate predicateWithFormat:@"%K contains %@",key,query];	
//	NSLog(@"%@",pred);
	return pred;
    }
    return nil;
}
-(NSPredicate*)datePredicate:(NSString*)operand
{
    operand=[operand stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSString* yearString=[operand stringByMatching:@"([01-9]+)" capture:1];
    if(!yearString)
	return nil;
    if([yearString length]!=2 && [yearString length]!=4)
	return nil;
    if([yearString length]==2){
	if([yearString isEqualToString:@"19"] || [yearString isEqualToString:@"20"] ){
	    return nil;
	}else if([yearString hasPrefix:@"0"]){
	    yearString=[(NSString*)@"20" stringByAppendingString:yearString];
	}else{
	    yearString=[(NSString*)@"19" stringByAppendingString:yearString];		
	}
    }
    int year=[yearString intValue];
    NSString*op=nil;
    if([operand hasPrefix:@">="]){
	op=@">";
    }else if([operand hasPrefix:@">"]){
	op=@">";
	year++;
    }else if([operand hasPrefix:@"<="]){
	op=@"<";
	year++;
    }else if([operand hasPrefix:@"<"]){
	op=@"<";
    }
    NSPredicate*pred=nil;
    if(op){
	pred= [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"eprintForSorting %@ %d",op,(int)(year*100*10000)]];
    }else{
	int upper=(year+1)*100*10000;
	int lower=year*100*10000;
	pred= [NSPredicate predicateWithFormat:@"(eprintForSorting < %d) and (eprintForSorting > %d)", upper, lower];
    }
//    NSLog(@"%@",pred);
    return pred;    
}
-(NSPredicate*)titlePredicate:(NSString*)operand
{
    NSString*key=@"normalizedTitle";
//    operand=[[operand componentsSeparatedByString:@","] objectAtIndex:0];
//    operand=[[operand componentsSeparatedByString:@" "] lastObject];
    operand=[operand stringByReplacingOccurrencesOfRegex:@" +" withString:@" "];
    if([operand isEqualToString:@""])
	return nil; //[NSPredicate predicateWithValue:YES];
    //    NSPredicate*pred=[NSPredicate predicateWithFormat:@"%K contains[cd] %@",key,operand];
    NSPredicate*pred=[NSPredicate predicateWithFormat:@"%K contains %@",key,[operand normalizedString]];
    //        NSLog(@"%@",pred);
    return pred;    
}
-(NSPredicate*)eprintPredicate:(NSString*)operand
{
    NSString*key=@"eprint";	
//    operand=[[operand componentsSeparatedByString:@","] objectAtIndex:0];
//    operand=[[operand componentsSeparatedByString:@" "] lastObject];
    if([operand isEqualToString:@""])
	return nil; //[NSPredicate predicateWithValue:YES];
    //    NSPredicate*pred=[NSPredicate predicateWithFormat:@"%K contains[cd] %@",key,operand];
    NSPredicate*pred=[NSPredicate predicateWithFormat:@"%K contains %@",key,[operand normalizedString]];
    //        NSLog(@"%@",pred);
    return pred;    
}
-(NSPredicate*)flagPredicate:(NSString*)operand
{
    NSString*key=@"flagInternal";	
    //    operand=[[operand componentsSeparatedByString:@","] objectAtIndex:0];
    //    operand=[[operand componentsSeparatedByString:@" "] lastObject];
    if([operand isEqualToString:@""])
	return [NSPredicate predicateWithValue:NO];
    //    NSPredicate*pred=[NSPredicate predicateWithFormat:@"%K contains[cd] %@",key,operand];
    NSString*head=nil;
    if([operand hasPrefix:@"f"]){
	head=@"F";
    }else if([operand hasPrefix:@"u"]){
	head=@"U";
    }else if([operand hasPrefix:@"p"]){
	head=@"P";
    }
    if(head){
	NSPredicate*pred=[NSPredicate predicateWithFormat:@"%K contains %@",key,head];
	//        NSLog(@"%@",pred);
	return pred;    
    }
    return [NSPredicate predicateWithValue:NO];
}
-(NSString*)extractOperand:(NSString*)s
{
    return [s stringByMatching:@"^ *(\\w+) +(.+)$" capture:2];
}
-(SEL)extractOperator:(NSString*)s
{
    NSString*operator=[s stringByMatching:@"^ *(\\w+) +(.+)$" capture:1];
    if([operator hasPrefix:@"to"]){
	return @selector(topcitePredicate:);
    }else if([operator hasPrefix:@"ea"]){
	return @selector(eaPredicate:);
    }else if([operator hasPrefix:@"j"]){
	return @selector(journalPredicate:);
    }else if([operator hasPrefix:@"c"]){
	return @selector(citedByPredicate:);
    }else if([operator hasPrefix:@"r"]){
	return @selector(referesToPredicate:);
    }else if([operator hasPrefix:@"a"]){
	return @selector(authorPredicate:);
    }else if([operator hasPrefix:@"d"]){
	return @selector(datePredicate:);
    }else if([operator hasPrefix:@"t"]){
	return @selector(titlePredicate:);
    }else if([operator hasPrefix:@"e"]){
	return @selector(eprintPredicate:);
    }else if([operator hasPrefix:@"f"]){
	return @selector(flagPredicate:);
    }else{
	return NULL;
    }    
}

-(NSPredicate*) predicateFromSPIRESsearchString:(NSString*)string
{
    //    string=[string stringByReplacingOccurrencesOfString:@" and " withString:@" & "];
    string=[string normalizedString];
    NSArray*a=[string componentsSeparatedByString:@" and "];
    NSMutableArray*arr=[NSMutableArray array];
    SEL operator=NULL;
    NSString*operand=nil;
    for(NSString*s in a){
	SEL op=[self extractOperator:s];
	if(!op && !operator)
	    return nil;
	if(op){
	    operator=op;
	    operand=[self extractOperand:s];
	}else{
	    operand=s;
	}
	if([operand length]<2)
	    continue;
	operand=[operand stringByReplacingOccurrencesOfString:@"#" withString:@""];
	NSPredicate*p=[self performSelector:operator withObject:operand];
	if(p)	
	    [arr addObject:p];
    }
    NSPredicate*pred=nil;
    if([arr count]==0){
	pred=[NSPredicate predicateWithValue:YES];
    }else if([arr count]==1){
	pred= [arr objectAtIndex:0];
    }else{
	pred=[[NSCompoundPredicate alloc] initWithType:NSAndPredicateType
					 subpredicates:arr];
    }
//    NSLog(@"%@",pred);
    return pred;
}

/* -(NSPredicate*) simplePredicateFromSPIRESsearchString:(NSString*)string
{
    NSString* operand=nil;
    NSString* operator=nil;
    NSUInteger location=[string rangeOfString:@" "].location;
    if(location==NSNotFound){
	return nil;
    }
    operator=[string substringToIndex:location];
    operand=[string substringFromIndex:location+1];
    if(operator==nil || operand==nil || [operator isEqualTo:@""] || [operand isEqualTo:@""] || [operand length]<2) {
	return nil;
    }
    operand=[operand stringByReplacingOccurrencesOfString:@"#" withString:@""];
    
    if([operator hasPrefix:@"to"]){
	return [self topcitePredicate:operand];
    }else if([operator hasPrefix:@"ea"]){
	return [self eaPredicate:operand];
    }else if([operator hasPrefix:@"j"]){
	return [self journalPredicate:operand];
    }else if([operator hasPrefix:@"c"]){
	return [self citedByPredicate:operand];
    }else if([operator hasPrefix:@"r"]){
	return [self referesToPredicate:operand];
    }else if([operator hasPrefix:@"a"]){
	return [self authorPredicate:operand];
    }else if([operator hasPrefix:@"d"]){
	return [self datePredicate:operand];
    }else if([operator hasPrefix:@"t"]){
	return [self titlePredicate:operand];
    }else if([operator hasPrefix:@"e"]){
	return [self eprintPredicate:operand];
    }else{
	return nil;
    }
}

-(NSPredicate*) predicateFromSPIRESsearchString_oldVersion:(NSString*)string
{
    //    string=[string stringByReplacingOccurrencesOfString:@" and " withString:@" & "];
    string=[string normalizedString];
    NSArray*a=[string componentsSeparatedByString:@" and "];
    NSMutableArray*arr=[NSMutableArray array];
    for(NSString*s in a){
	NSPredicate*p=[self simplePredicateFromSPIRESsearchString:s];
	if(p)	
	    [arr addObject:p];
    }
    NSPredicate*pred=nil;
    if([arr count]==0){
	pred=[NSPredicate predicateWithValue:YES];
    }else if([arr count]==1){
	pred= [arr objectAtIndex:0];
    }else{
	pred=[[NSCompoundPredicate alloc] initWithType:NSAndPredicateType
					 subpredicates:arr];
    }
    //    NSLog(@"%@",pred);
    return pred;
}*/
#pragma mark Bib Entries Query
-(NSArray*)bibtexEntriesForQuery:(NSString*)search
{
    NSURL* url=[NSURL URLWithString:[[NSString stringWithFormat:@"%@%@&server=sunspi5", SPIRESBIBTEXHEAD,search ] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding ] ];
//    NSString*s= [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:nil];
    NSString*s= [NSString stringWithContentsOfURL:url encoding:NSISOLatin1StringEncoding error:nil];


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
//    NSString*s= [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:nil];
    NSString*s= [NSString stringWithContentsOfURL:url encoding:NSISOLatin1StringEncoding error:nil];


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
    //    NSString*s= [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:nil];
    NSString*s= [NSString stringWithContentsOfURL:url encoding:NSISOLatin1StringEncoding error:nil];
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
    searchString=[search normalizedString];
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
    NSError*error;
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
	    [t writeToFile:@"/tmp/spires-xml.xml" atomically:NO encoding:NSUTF8StringEncoding error:nil];
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

#pragma mark online management
-(void)setIsOnline:(BOOL)b
{
    [[NSUserDefaults standardUserDefaults] setBool:b forKey:@"isOnline"];
    if(b){
	[[NSUserDefaults standardUserDefaults] setValue:NSLocalizedString(@"Turn Offline",@"Turn Offline")
						 forKey:@"turnOnOfflineMenuItem"];
    }else{
	[[NSUserDefaults standardUserDefaults] setValue:NSLocalizedString(@"Turn Online",@"Turn Online")
						 forKey:@"turnOnOfflineMenuItem"];	
    }
}
-(BOOL)isOnline
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"isOnline"];
}

@end
