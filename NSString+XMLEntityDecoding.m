//
//  NSString+XMLEntityDecoding.m
//  spires
//
//  Created by Yuji on 08/10/16.
//  Copyright 2008 Y. Tachikawa. All rights reserved.
//

#import "NSString+XMLEntityDecoding.h"


@implementation NSString (XMLEntityDecoding)
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
	    
	int i, count = [codes count];
	    
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
		    [escaped insertString: [NSString stringWithFormat: @"%C", tempInt] atIndex: entityRange.location];
		}
		else
		{
		    [escaped insertString: [NSString stringWithFormat: @"%C", [value intValue]] atIndex: entityRange.location];
		}
		i = start.location;
	    }
	    else i++;
	    searchRange = NSMakeRange(i, [escaped length] - i);
	}
	
	return escaped;    // Note this is autoreleased
    }
}


@end
