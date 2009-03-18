//
//  NSString+magicTeX.m
//  spires
//
//  Created by Yuji on 09/02/18.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import "NSString+magic.h"


@implementation NSString (NSString_magic)
-(NSString*)magicTeXed
{
    NSArray*a=[self componentsSeparatedByString:@"``"];
    NSMutableString*quieter=[NSMutableString string];
    for(NSString*i in a){
	NSRange range=[i rangeOfString:@"''"];
	if(range.location!=NSNotFound){
	    NSString*h=[i substringToIndex:range.location];
	    h=[h stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
	    NSString*t=[i substringFromIndex:range.location];
	    [quieter appendString:@"``"];
	    [quieter appendString:[h quieterVersion]];
	    [quieter appendString:t];
	}else{
	    [quieter appendString:i];
	}
    }
    NSString*inPath=[NSString stringWithFormat:@"/tmp/inSPIRES-%d",getuid()];
    NSString*outPath=[NSString stringWithFormat:@"/tmp/outSPIRES-%d",getuid()];
    NSString*script=[[[NSBundle mainBundle] pathForResource:@"magic" ofType:@"perl"] stringByReplacingOccurrencesOfString:@"'" withString:@"\\'"];
    NSString* command=[NSString stringWithFormat:@"/usr/bin/perl \'%@\' <%@ >%@" , script,inPath,outPath];
    NSError*error=nil;
    [quieter writeToFile:inPath atomically:NO encoding:NSUTF8StringEncoding error:&error];
    system([command UTF8String]);
    return [[NSString alloc] initWithContentsOfFile:outPath encoding:NSUTF8StringEncoding error:&error];
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
		s=[s capitalizedString];
		s=[s stringByReplacingOccurrencesOfString:@"/Cft" withString:@"/CFT"];
		s=[s stringByReplacingOccurrencesOfString:@"-Cft" withString:@"-CFT"];
		s=[s stringByReplacingOccurrencesOfString:@"Ads" withString:@"AdS"];
		s=[s stringByReplacingOccurrencesOfString:@"Rn" withString:@"RN"];
		s=[s stringByReplacingOccurrencesOfString:@"Ns" withString:@"NS"];
		s=[s stringByReplacingOccurrencesOfString:@"-Rg" withString:@"-RG"];
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
@end
