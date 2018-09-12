//
//  NSString+magicTeX.m
//  spires
//
//  Created by Yuji on 09/02/18.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import "NSString+magic.h"
#import <JavaScriptCore/JavaScriptCore.h>
#if TARGET_OS_IPHONE
@import UIKit;
#define NSFont UIFont
#else
@import AppKit;
#endif

static NSArray*magicRegExps=nil;
static void loadMagic(){
    NSMutableArray*a=[NSMutableArray array];
    NSString*contents=[NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"magicRegExps" ofType:@"perl"]
						encoding:NSUTF8StringEncoding
						   error:NULL];
    for(NSString*line in [contents componentsSeparatedByString:@"\n"]){
	NSArray*foo=[line componentsSeparatedByString:@"/"];
	if([foo count]>=3){
	    NSArray*bar=@[foo[1], foo[2]];
	    [a addObject:bar];
	}
    }
    magicRegExps=a;
}
@implementation NSString (NSString_magic)

-(NSString*)extractArXivID
{
    NSString*s=[self stringByRemovingPercentEncoding];
    if(s==nil)return @"";
    if([s isEqualToString:@""])return @"";
    //    NSLog(@"%@",s);
    NSRange r=[s rangeOfString:@"/" options:NSBackwardsSearch];
    if(r.location!=NSNotFound){
        s=[s substringFromIndex:r.location+1];
    }
    if(s==nil)return @"";
    if([s isEqualToString:@""])return @"";
    
    NSScanner*scanner=[NSScanner scannerWithString:s];
    NSCharacterSet*set=[NSCharacterSet characterSetWithCharactersInString:@".0123456789"];
    [scanner scanUpToCharactersFromSet:set intoString:NULL];
    NSString* d=nil;
    [scanner scanCharactersFromSet:set intoString:&d];
    if(d){
        if([d hasSuffix:@"."]){
            d=[d substringToIndex:[d length]-1];
        }
        for(NSString*cat in @[@"hep-th",@"hep-ph",@"hep-ex",@"hep-lat",@"astro-ph",@"math-ph",@"math",@"cond-mat"]){
            if([self rangeOfString:cat].location!=NSNotFound){
                d=[NSString stringWithFormat:@"%@/%@",cat,d];
                break;
            }
        }
        return d;
    }
    else return nil;
}
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
-(NSString*)correctToInspire{
    NSString*result=self;
    result=[result stringByReplacingOccurrencesOfString:@"deWit:" withString:@"de Wit:"];
    result=[result stringByReplacingOccurrencesOfString:@"tHooft:" withString:@"'t Hooft:"];
    return result;
}
-(NSString*)inspireToCorrect{
    NSString*result=self;
    result=[result stringByReplacingOccurrencesOfString:@"de Wit:" withString:@"deWit:"];
    result=[result stringByReplacingOccurrencesOfString:@"'t Hooft:" withString:@"tHooft:"];
    return result;
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
	NSString*from=pair[0];
	NSString*to=pair[1];
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
	NSString*s=a[i];
        if(![abbrevs containsObject:s] && ![s hasPrefix:@"SU("] && ![s hasPrefix:@"SO("] && ![s hasPrefix:@"\\"] &&  ![s hasPrefix:@"$"]){
	    s=[s lowercaseString];
	    if(i==0 || ![preps containsObject:s]){
		s=[s capitalizedStringForName];
		s=[s stringByReplacingOccurrencesOfString:@"Ads" withString:@"AdS"];
		s=[s stringByReplacingOccurrencesOfString:@"Rn" withString:@"RN"];
		s=[s stringByReplacingOccurrencesOfString:@"Pp" withString:@"PP"];
		s=[s stringByReplacingOccurrencesOfString:@"Qcd" withString:@"QCD"];
		s=[s stringByReplacingOccurrencesOfString:@"Cft" withString:@"CFT"];
		s=[s stringByReplacingOccurrencesOfString:@"Ns" withString:@"NS"];
		s=[s stringByReplacingOccurrencesOfString:@"-Rg" withString:@"-RG"];
		s=[s stringByReplacingOccurrencesOfString:@"'S" withString:@"'s"];
	    }
	}
	[b addObject:s];
    }
    return [b componentsJoinedByString:@" "];
}

-(NSAttributedString*)mockTeXed
{
    static NSDictionary*dic=nil;
    if(!dic){
        dic=@{
              @"\\\\zeta" : @"ζ",
              @"\\\\xi" : @"ξ",
              @"\\\\wedge" : @"∧",
              @"\\\\vee" : @"∨",
              @"\\\\upsilon" : @"υ",
              @"\\\\to" : @"→",
              @"\\\\times" : @"×",
              @"\\\\theta" : @"θ",
              @"\\\\tau" : @"τ",
              @"\\\\sum" : @"∑",
              @"\\\\ss" : @"ß",
              @"\\\\sqrt" : @"√",
              @"\\\\sim" : @"〜",
              @"\\\\sigma" : @"σ",
              @"\\\\rightarrow" : @"→",
              @"\\\\uparrow" : @"↑",
              @"\\\\downarrow" : @"↓",
              @"\\\\rho" : @"ρ",
              @"\\\\psi" : @"ψ",
              @"\\\\prod" : @"Π",
              @"\\\\prime" : @"'",
              @"\\\\pm" : @"±",
              @"\\\\pi" : @"π",
              @"\\\\phi" : @"φ",
              @"\\\\perp" : @"⟂",
              @"\\\\partial" : @"∂",
              @"\\\\over" : @"/",
              @"\\\\otimes" : @"⊗",
              @"\\\\oplus" : @"⊕",
              @"\\\\omega" : @"ω",
              @"\\\\odot" : @"⊙",
              @"\\\\nu" : @"ν",
              @"\\\\neq" : @"≠",
              @"\\\\ne" : @"≠",
              @"\\\\nabla" : @"∇",
              @"\\\\mu" : @"μ",
              @"\\\\mp" : @"∓",
              @"\\\\lesssim" : @"≲",
              @"\\\\lsim" : @"≲",
              @"\\\\ll" : @"≪",
              @"\\\\leq" : @"≤",
              @"\\\\leftrightarrow" : @"↔",
              @"\\\\leftarrow" : @"←",
              @"\\\\left" : @"",
              @"\\\\right" : @"",
              @"\\\\le" : @"≤",
              @"\\\\lambda" : @"λ",
              @"\\\\kappa" : @"κ",
              @"\\\\iota" : @"ι",
              @"\\\\int" : @"∫",
              @"\\\\infty" : @"∞",
              @"\\\\in" : @"∈",
              @"\\\\hbar" : @"ħ",
              @"\\\\gtrsim" : @"≳",
              @"\\\\gsim" : @"≳",
              @"\\\\gg" : @"≫",
              @"\\\\geq" : @"≥",
              @"\\\\ge" : @"≥",
              @"\\\\gamma" : @"γ",
              @"\\\\eta" : @"η",
              @"\\\\equiv" : @"≡",
              @"\\\\epsilon" : @"ε",
              @"\\\\varepsilon" : @"ε",
              @"\\\\ell" : @"ℓ",
              @"\\\\delta" : @"δ",
              @"\\\\circ" : @"o",
              @"\\\\cup" : @"∪",
              @"\\\\chi" : @"χ",
              @"\\\\cap" : @"∩",
              @"\\\\beta" : @"β",
              @"\\\\approx" : @"≈",
              @"\\\\alpha" : @"α",
              @"\\\\Zeta" : @"Ζ",
              @"\\\\Xi" : @"Ξ",
              @"\\\\Upsilon" : @"Υ",
              @"\\\\Theta" : @"Θ",
              @"\\\\Tau" : @"Τ",
              @"\\\\Sigma" : @"Σ",
              @"\\\\Rho" : @"Ρ",
              @"\\\\Psi" : @"Ψ",
              @"\\\\Pi" : @"Π",
              @"\\\\Phi" : @"Φ",
              @"\\\\Omega" : @"Ω",
              @"\\\\Nu" : @"Ν",
              @"\\\\Mu" : @"Μ",
              @"\\\\Lambda" : @"Λ",
              @"\\\\Kappa" : @"Κ",
              @"\\\\Iota" : @"Ι",
              @"\\\\Gamma" : @"Γ",
              @"\\\\Eta" : @"Η",
              @"\\\\Epsilon" : @"Ε",
              @"\\\\Delta" : @"Δ",
              @"\\\\Chi" : @"Χ",
              @"\\\\Bmu" : @"Βμ",
              @"\\\\Beta" : @"Β",
              @"\\\\Alpha" : @"Α",
              @"\\\\AA" : @"Å",
              @"\\\\cdot" : @"•"};
    }
    
    static NSArray*keys=nil;
    if(!keys){
        keys=[[dic allKeys] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"length" ascending:NO]]];
    }
    NSMutableString*x=[self mutableCopy];
    
    for(NSString*key in keys){
        [x replaceOccurrencesOfRegex:key withString:dic[key]];
    }
    [x replaceOccurrencesOfRegex:@"\\\\[A-Za-z]+" withString:@""];
    [x replaceOccurrencesOfRegex:@"$" withString:@""];
    
    NSMutableAttributedString*s=[[NSMutableAttributedString alloc]initWithString:x];
#if TARGET_OS_IPHONE
#define UP (0.3)
#define DOWN (0.2)
    NSFont* regular=[NSFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    NSFont* small=[NSFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
#else
#define UP (0.25)
#define DOWN (0.2)
    NSFont* regular=[NSFont systemFontOfSize:[NSFont systemFontSize]];
    NSFont* small=[NSFont systemFontOfSize:[NSFont smallSystemFontSize]];
#endif
    while(1){
        NSRange r=[[s string] rangeOfString:@"^{"];
        if(r.location==NSNotFound)
            break;
        [[s mutableString] replaceCharactersInRange:r withString:@""];
        NSRange rr=[[s string] rangeOfString:@"}" options:NSLiteralSearch range:NSMakeRange(r.location, [[s string] length]-r.location)];
        [[s mutableString] replaceCharactersInRange:rr withString:@""];
        [s setAttributes:@{NSFontAttributeName:small, NSBaselineOffsetAttributeName:@(UP*regular.ascender)} range:NSMakeRange(r.location, rr.location-r.location)];
    }
    while(1){
        NSRange r=[[s string] rangeOfString:@"^"];
        if(r.location==NSNotFound)
            break;
        [[s mutableString] replaceCharactersInRange:r withString:@""];
        [s setAttributes:@{NSFontAttributeName:small, NSBaselineOffsetAttributeName:@(UP*regular.ascender)} range:r];
    }
    while(1){
        NSRange r=[[s string] rangeOfString:@"**"];
        if(r.location==NSNotFound)
            break;
        [[s mutableString] replaceCharactersInRange:r withString:@""];
        [s setAttributes:@{NSFontAttributeName:small, NSBaselineOffsetAttributeName:@(UP*regular.ascender)} range:NSMakeRange(r.location,1)];
    }
    while(1){
        NSRange r=[[s string] rangeOfString:@"_{"];
        if(r.location==NSNotFound)
            break;
        [[s mutableString] replaceCharactersInRange:r withString:@""];
        NSRange rr=[[s string] rangeOfString:@"}" options:NSLiteralSearch range:NSMakeRange(r.location, [[s string] length]-r.location)];
        [[s mutableString] replaceCharactersInRange:rr withString:@""];
        [s setAttributes:@{NSFontAttributeName:small, NSBaselineOffsetAttributeName:@(-DOWN*regular.ascender)} range:NSMakeRange(r.location, rr.location-r.location)];
    }
    while(1){
        NSRange r=[[s string] rangeOfString:@"_"];
        if(r.location==NSNotFound)
            break;
        [[s mutableString] replaceCharactersInRange:r withString:@""];
        [s setAttributes:@{NSFontAttributeName:small, NSBaselineOffsetAttributeName:@(-DOWN*regular.ascender)} range:r];
    }
    [[s mutableString] replaceOccurrencesOfString:@"{" withString:@"" options:NSLiteralSearch range:NSMakeRange(0, [[s mutableString] length])];
    [[s mutableString] replaceOccurrencesOfString:@"}" withString:@"" options:NSLiteralSearch range:NSMakeRange(0, [[s mutableString] length])];
    [[s mutableString] replaceOccurrencesOfString:@"$" withString:@"" options:NSLiteralSearch range:NSMakeRange(0, [[s mutableString] length])];
    return s;
}

-(NSString*)normalizedString
{
    if (!self) return nil;
    
    NSMutableString *result = [NSMutableString stringWithString:self];
    
    CFStringNormalize((__bridge CFMutableStringRef)result, kCFStringNormalizationFormD);
    CFStringFold((__bridge CFMutableStringRef)result, kCFCompareCaseInsensitive | kCFCompareDiacriticInsensitive | kCFCompareWidthInsensitive, NULL);
    
    return [[result componentsSeparatedByCharactersInSet:[NSCharacterSet controlCharacterSet]] componentsJoinedByString:@""];
    
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
	NSArray *codes = @[@"&amp;", @"&lt;", @"&gt;", @"&quot;",
			  @"&nbsp;"];
	NSArray*characters=@[@"&",@"<",@">",@"\"",@" "];
	
	NSUInteger i, count = [codes count];
	
	// Html
	for(i = 0; i < count; i++)
	{
	    NSRange range = [source rangeOfString: codes[i]];
	    if(range.location != NSNotFound)
	    {
		[escaped replaceOccurrencesOfString: codes[i] 
					 withString: characters[i]
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
    static JSContext*context=nil;
    if(!context){
        context=[[JSContext alloc] init];
        NSString*script=[NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"tex" ofType:@"js"]
                                                  encoding:NSUTF8StringEncoding
                                                     error:NULL];
        [context evaluateScript:script];
    }
    JSValue*texify=context[@"texify"];
    JSValue*result=[texify callWithArguments:@[self]];
    return [result toString];
}
@end
