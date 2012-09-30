//
//  NSString+magicTeX.m
//  spires
//
//  Created by Yuji on 09/02/18.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import "NSString+magic.h"
#import <WebKit/WebKit.h>

static NSArray*magicRegExps=nil;
static void loadMagic(){
    NSMutableArray*a=[NSMutableArray array];
    NSString*contents=[NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"magicRegExps" ofType:@"perl"]
						encoding:NSUTF8StringEncoding
						   error:NULL];
    for(NSString*line in [contents componentsSeparatedByString:@"\n"]){
	NSArray*foo=[line componentsSeparatedByString:@"/"];
	if([foo count]>=3){
	    NSArray*bar=[NSArray arrayWithObjects:[foo objectAtIndex:1], [foo objectAtIndex:2],nil];
	    [a addObject:bar];
	}
    }
    magicRegExps=a;
}
@implementation NSString (NSString_magic)
-(NSString*)makeQuieterBetween:(NSString*)xxx and:(NSString*)yyy
{
    NSArray*a=[self componentsSeparatedByString:xxx];
    NSMutableString*quieter=[NSMutableString string];
    for(NSString*i in a){
	NSRange range=[i rangeOfString:yyy];
	if(range.location!=NSNotFound){
	    NSString*h=[i substringToIndex:range.location];
	    h=[h stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
	    NSString*t=[i substringFromIndex:range.location];
	    [quieter appendString:xxx];
	    [quieter appendString:[h quieterVersion]];
	    [quieter appendString:t];
	}else{
	    [quieter appendString:i];
	}
    }
    return quieter;
}
-(NSString*)magicTeXed
{
    NSString*quieter=[self makeQuieterBetween:@"``" and:@"''"];
    quieter=[quieter makeQuieterBetween:@"\"{" and:@"}\""];
    if(!magicRegExps){
	loadMagic();
    }
    NSMutableString*result=[quieter mutableCopy];
    for(NSArray*pair in magicRegExps){
	NSString*from=[pair objectAtIndex:0];
	NSString*to=[pair objectAtIndex:1];
	[result replaceOccurrencesOfRegex:from 
			       withString:to 
				  options:RKLCaseless|RKLMultiline 
				    range:NSMakeRange(0,[result length]) 
				    error:NULL];
    }
    return result;
}
-(NSString*)quieterVersion
{
    NSArray*a=[self componentsSeparatedByString:@" "];
    if([a count]==0){
	return @"";
    }
    NSMutableArray*b=[NSMutableArray array];
    NSArray*abbrevs=[[NSUserDefaults standardUserDefaults] arrayForKey:@"abbreviations"];
    NSArray*preps=[[NSUserDefaults standardUserDefaults] arrayForKey:@"prepositions"];
    for(NSUInteger i=0;i<[a count];i++){
	NSString*s=[a objectAtIndex:i];
	if(![abbrevs containsObject:s] && ![s hasPrefix:@"SU("] && ![s hasPrefix:@"SO("]){
	    s=[s lowercaseString];
	    if(i==0 || ![preps containsObject:s]){
		s=[s capitalizedStringForName];
		s=[s stringByReplacingOccurrencesOfString:@"Ads" withString:@"AdS"];
		s=[s stringByReplacingOccurrencesOfString:@"Rn" withString:@"RN"];
		s=[s stringByReplacingOccurrencesOfString:@"Pp" withString:@"PP"];
		s=[s stringByReplacingOccurrencesOfString:@"Qcd" withString:@"QCD"];
		s=[s stringByReplacingOccurrencesOfString:@"Cft" withString:@"CFT"];
		s=[s stringByReplacingOccurrencesOfString:@"Scft" withString:@"SCFT"];
		s=[s stringByReplacingOccurrencesOfString:@"Ns" withString:@"NS"];
		s=[s stringByReplacingOccurrencesOfString:@"-Rg" withString:@"-RG"];
		s=[s stringByReplacingOccurrencesOfString:@"'S" withString:@"'s"];
	    }
	}
	[b addObject:s];
    }
    return [b componentsJoinedByString:@" "];
}
-(NSString*)normalizedString
{
    if (!self) return nil;
    
    NSMutableString *result = [NSMutableString stringWithString:self];
    
    CFStringNormalize((__bridge CFMutableStringRef)result, kCFStringNormalizationFormD);
    CFStringFold((__bridge CFMutableStringRef)result, kCFCompareCaseInsensitive | kCFCompareDiacriticInsensitive | kCFCompareWidthInsensitive, NULL);
    
    return result;
    
}
-(NSString*)quotedForShell
{
    NSString*s=[self stringByReplacingOccurrencesOfRegex:@"([\\\\\"`\\$])" withString:@"\\\\$1"]; 
    s=[NSString stringWithFormat:@"\"%@\"",s];
//    NSLog(@"%@-->%@",self,s);
    return s;
}
-(NSString*)capitalizedStringForName;
{
    NSArray*particles=[[NSUserDefaults standardUserDefaults] objectForKey:@"particles"];
    for(NSString*particle in particles){
        NSString*a=[particle stringByAppendingString:@" "];
        if([self hasPrefix:a] || [self hasPrefix:[a capitalizedString]] 
        || [self hasPrefix:[a uppercaseString]]){
            NSString*rest=[[self substringFromIndex:[a length]] capitalizedString];
            return [a stringByAppendingString:rest];
        }
    }
    if([self hasPrefix:@"Mc"]||[self hasPrefix:@"mc"]){
	return [@"Mc" stringByAppendingString:[[self substringFromIndex:2] capitalizedString]];
    }else if([self hasPrefix:@"d'"]||[self hasPrefix:@"D'"]){
	return [@"D'" stringByAppendingString:[[self substringFromIndex:2] capitalizedString]];
    }else if([self hasPrefix:@"o'"]||[self hasPrefix:@"O'"]){
	return [@"O'" stringByAppendingString:[[self substringFromIndex:2] capitalizedString]];
    }else if([self hasPrefix:@"Van den "]||[self hasPrefix:@"van den "]){
	return [@"Van den" stringByAppendingString:[[self substringFromIndex:[@"Van den " length]] capitalizedString]];
    }else{
	return [self capitalizedString];
    }
}
-(NSString*)stringByExpandingAmpersandEscapes
{
    /*    NSString*s=[self stringByReplacingOccurrencesOfString:@"&lt;" withString:@"<"];
     s=[s stringByReplacingOccurrencesOfString:@"&gt;" withString:@">"];
     s=[s stringByReplacingOccurrencesOfString:@"&quot;" withString:@"\""];
     return s;*/
    // Mostly Taken from http://www.thinkmac.co.uk/blog/2005/05/removing-entities-from-html-in-cocoa.html
    
    NSString*source=self;
    if(!source){
	return nil;
    }else if([source rangeOfString: @"&"].location == NSNotFound) {
	return source;
    }else{
	NSMutableString *escaped = [NSMutableString stringWithString: source];
	NSArray *codes = [NSArray arrayWithObjects: 
			  @"&amp;", @"&lt;", @"&gt;", @"&quot;",
			  @"&nbsp;", /*@"&iexcl;", @"&cent;", @"&pound;", @"&curren;", @"&yen;", @"&brvbar;",
				      @"&sect;", @"&uml;", @"&copy;", @"&ordf;", @"&laquo;", @"&not;", @"&shy;", @"&reg;",
				      @"&macr;", @"&deg;", @"&plusmn;", @"&sup2;", @"&sup3;", @"&acute;", @"&micro;",
				      @"&para;", @"&middot;", @"&cedil;", @"&sup1;", @"&ordm;", @"&raquo;", @"&frac14;",
				      @"&frac12;", @"&frac34;", @"&iquest;", @"&Agrave;", @"&Aacute;", @"&Acirc;",
				      @"&Atilde;", @"&Auml;", @"&Aring;", @"&AElig;", @"&Ccedil;", @"&Egrave;",
				      @"&Eacute;", @"&Ecirc;", @"&Euml;", @"&Igrave;", @"&Iacute;", @"&Icirc;", @"&Iuml;",
				      @"&ETH;", @"&Ntilde;", @"&Ograve;", @"&Oacute;", @"&Ocirc;", @"&Otilde;", @"&Ouml;",
				      @"&times;", @"&Oslash;", @"&Ugrave;", @"&Uacute;", @"&Ucirc;", @"&Uuml;", @"&Yacute;",
				      @"&THORN;", @"&szlig;", @"&agrave;", @"&aacute;", @"&acirc;", @"&atilde;", @"&auml;",
				      @"&aring;", @"&aelig;", @"&ccedil;", @"&egrave;", @"&eacute;", @"&ecirc;", @"&euml;",
				      @"&igrave;", @"&iacute;", @"&icirc;", @"&iuml;", @"&eth;", @"&ntilde;", @"&ograve;",
				      @"&oacute;", @"&ocirc;", @"&otilde;", @"&ouml;", @"&divide;", @"&oslash;", @"&ugrave;",
				      @"&uacute;", @"&ucirc;", @"&uuml;", @"&yacute;", @"&thorn;", @"&yuml;",*/
			  nil];
	NSArray*characters=[NSArray arrayWithObjects:@"&",@"<",@">",@"\"",@" ",nil];
	
	NSUInteger i, count = [codes count];
	
	// Html
	for(i = 0; i < count; i++)
	{
	    NSRange range = [source rangeOfString: [codes objectAtIndex: i]];
	    if(range.location != NSNotFound)
	    {
		[escaped replaceOccurrencesOfString: [codes objectAtIndex: i] 
					 withString: [characters objectAtIndex:i]
					    options: NSLiteralSearch 
					      range: NSMakeRange(0, [escaped length])];
	    }
	}
	
	// Decimal & Hex
	NSRange start, finish, searchRange = NSMakeRange(0, [escaped length]);
	i = 0;
	while(i < [escaped length])
	{
	    start = [escaped rangeOfString: @"&#" 
				   options: NSCaseInsensitiveSearch 
				     range: searchRange];
	    
	    finish = [escaped rangeOfString: @";" 
				    options: NSCaseInsensitiveSearch 
				      range: searchRange];
	    
	    if(start.location != NSNotFound && finish.location != NSNotFound &&
	       finish.location > start.location)
	    {
		NSRange entityRange = NSMakeRange(start.location, (finish.location - start.location) + 1);
		NSString *entity = [escaped substringWithRange: entityRange];     
		NSString *value = [entity substringWithRange: NSMakeRange(2, [entity length] - 2)];
		
		[escaped deleteCharactersInRange: entityRange];
		
		if([value hasPrefix: @"x"])
		{
		    unsigned int tempInt = 0;
		    NSScanner *scanner = [NSScanner scannerWithString: [value substringFromIndex: 1]];
		    [scanner scanHexInt: &tempInt];
		    [escaped insertString: [NSString stringWithFormat: @"%C", (unsigned short)tempInt] atIndex: entityRange.location];
		}
		else
		{
		    [escaped insertString: [NSString stringWithFormat: @"%C", (unsigned short)[value intValue]] atIndex: entityRange.location];
		}
		i = start.location;
	    }
	    else i++;
	    searchRange = NSMakeRange(i, [escaped length] - i);
	}
	
	return escaped;    // Note this is autoreleased
    }
}
#pragma mark MockTeX
-(NSComparisonResult)compareFirstWithLength:(NSString*)string
{
    if([self length]>[string length]){
	return NSOrderedDescending;
    }else if([self length]<[string length]){
	return NSOrderedAscending;
    }else
	return [self compare:string];
}
-(NSString*)stringByConvertingTeXintoHTML
{
    static WebScriptObject*wso=nil;
    if(!wso){
	static WebView*wv=nil;
	wv=[[WebView alloc] init];
	NSString*script=[NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"tex" ofType:@"js"]
						  encoding:NSUTF8StringEncoding
						     error:NULL];
	[wv stringByEvaluatingJavaScriptFromString:script];
	wso=[wv windowScriptObject];
    }
    return [wso callWebScriptMethod:@"texify" withArguments:[NSArray arrayWithObject:self]];
}
@end
