//
//  NSString+magicTeX.m
//  spires
//
//  Created by Yuji on 09/02/18.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import "NSString+magic.h"
#import "RegexKitLite.h"

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
/*    NSString*inPath=[NSString stringWithFormat:@"/tmp/inSPIRES-%d",getuid()];
    NSString*outPath=[NSString stringWithFormat:@"/tmp/outSPIRES-%d",getuid()];
    NSString*script=[[[NSBundle mainBundle] pathForResource:@"magic" ofType:@"perl"] stringByReplacingOccurrencesOfString:@"'" withString:@"\\'"];
    NSString* command=[NSString stringWithFormat:@"/usr/bin/perl %@ <%@ >%@" , [script quotedForShell],inPath,outPath];
    NSError*error=nil;
    [quieter writeToFile:inPath atomically:NO encoding:NSUTF8StringEncoding error:&error];
    system([command UTF8String]);
    return [[NSString alloc] initWithContentsOfFile:outPath encoding:NSUTF8StringEncoding error:&error];*/
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
    for(int i=0;i<[a count];i++){
	NSString*s=[a objectAtIndex:i];
	if(![abbrevs containsObject:s] && ![s hasPrefix:@"SU("] && ![s hasPrefix:@"SO("]){
	    s=[s lowercaseString];
	    if(i==0 || ![preps containsObject:s]){
		s=[s capitalizedStringForName];
		s=[s stringByReplacingOccurrencesOfString:@"Cft" withString:@"CFT"];
		s=[s stringByReplacingOccurrencesOfString:@"Ads" withString:@"AdS"];
		s=[s stringByReplacingOccurrencesOfString:@"Rn" withString:@"RN"];
		s=[s stringByReplacingOccurrencesOfString:@"Pp" withString:@"PP"];
		s=[s stringByReplacingOccurrencesOfString:@"Qcd" withString:@"QCD"];
		s=[s stringByReplacingOccurrencesOfString:@"Cft" withString:@"CFT"];
		s=[s stringByReplacingOccurrencesOfString:@"Scft" withString:@"SCFT"];
		s=[s stringByReplacingOccurrencesOfString:@"Ns" withString:@"NS"];
		s=[s stringByReplacingOccurrencesOfString:@"-Rg" withString:@"-RG"];
		s=[s stringByReplacingOccurrencesOfString:@"So-Usp" withString:@"SO-USp"];
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
    
    CFStringNormalize((CFMutableStringRef)result, kCFStringNormalizationFormD);
    CFStringFold((CFMutableStringRef)result, kCFCompareCaseInsensitive | kCFCompareDiacriticInsensitive | kCFCompareWidthInsensitive, NULL);
    
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
    if([self hasPrefix:@"Mc"]||[self hasPrefix:@"mc"]){
	return [@"Mc" stringByAppendingString:[[self substringFromIndex:2] capitalizedString]];
    }else if([self hasPrefix:@"de "]||[self hasPrefix:@"De "]){
	return [@"de " stringByAppendingString:[[self substringFromIndex:3] capitalizedString]];
    }else if([self hasPrefix:@"d'"]||[self hasPrefix:@"D'"]){
	return [@"D'" stringByAppendingString:[[self substringFromIndex:2] capitalizedString]];
    }else if([self hasPrefix:@"o'"]||[self hasPrefix:@"O'"]){
	return [@"O'" stringByAppendingString:[[self substringFromIndex:2] capitalizedString]];
    }else if([self hasPrefix:@"Van den "]||[self hasPrefix:@"van den "]){
	return [@"Van den" stringByAppendingString:[[self substringFromIndex:[@"Van den " length]] capitalizedString]];
    }else if([self hasPrefix:@"Van "]||[self hasPrefix:@"van "]){
	return [@"Van " stringByAppendingString:[[self substringFromIndex:4] capitalizedString]];
    }else if([self hasPrefix:@"'t "]||[self hasPrefix:@"'T "]){
	return [@"'t " stringByAppendingString:[[self substringFromIndex:3] capitalizedString]];
    }else{
	return [self capitalizedString];
    }
}
@end
