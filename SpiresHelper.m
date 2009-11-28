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
#import "Article.h"
#import "MOC.h"

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
    Article*a=[Article intelligentlyFindArticleWithId:operand inMOC:[MOC moc]];
    return [NSPredicate predicateWithBlock:^(id ar,NSDictionary*dict){
	return [a.citedBy containsObject:ar];
    }];
}
-(NSPredicate*)refersToPredicate:(NSString*)operand
{
    Article*a=nil;
    if([operand rangeOfString:@":"].location!=NSNotFound || [operand rangeOfString:@"/"].location!=NSNotFound){
	a=[Article articleWithEprint:operand inMOC:[MOC moc]];
    }else if([operand hasPrefix:@"key"]){
	NSArray* arr=[operand componentsSeparatedByString:@" "];
	if([arr count]==2){
	    a=[Article articleWith:[arr objectAtIndex:1]
		      inDataForKey:@"spiresKey"
			     inMOC:[MOC moc]];
	}
    }
    if(a){
	return [NSPredicate predicateWithBlock:^(id ar,NSDictionary*dict){
	    return [a.refersTo containsObject:ar];
	}];
    }else{
	return [NSPredicate predicateWithValue:NO];
    }
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
	
	operand=[operand stringByReplacingOccurrencesOfString:@"van " withString:@"van+"];
	operand=[operand stringByReplacingOccurrencesOfString:@"Van " withString:@"Van+"];
	operand=[operand stringByReplacingOccurrencesOfString:@"de " withString:@"de+"];
	operand=[operand stringByReplacingOccurrencesOfString:@"De " withString:@"De+"];
	NSArray*xx=[operand componentsSeparatedByString:@" "];
	NSMutableArray*x=[NSMutableArray array];
	for(NSString* s in xx){
	    [x addObject:[s stringByReplacingOccurrencesOfString:@"+" withString:@" "]];
	}
	
	NSString*last=[x lastObject];
	if([x count]==1){
	    //		return [NSPredicate predicateWithFormat:@"%K contains[cd] %@",key,operand];
	    NSString*query=[NSString stringWithFormat:@"; %@",last];
	    return [NSPredicate predicateWithFormat:@"%K contains %@",key,query];
	}
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
    NSPredicate*pred2=[NSPredicate predicateWithFormat:@"data.longishAuthorListForEA contains %@",[operand normalizedString]];	    
    NSPredicate*pred1=[self authorPredicate:operand];
    return [NSCompoundPredicate andPredicateWithSubpredicates:[NSArray arrayWithObjects:pred1,pred2,nil]];    
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
    if([operand isEqualToString:@""])
	return nil; 
    NSString*norm=[operand normalizedString];
    NSString*es=[Article eprintForSortingFromEprint:norm];
    NSPredicate*pred1=[NSPredicate predicateWithFormat:@"eprintForSortingAsString contains %@",es];
    NSPredicate*pred2=[NSPredicate predicateWithFormat:@"data.eprint contains %@",norm];
    NSPredicate*pred=[NSCompoundPredicate andPredicateWithSubpredicates:[NSArray arrayWithObjects:pred1,pred2,nil]];
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
	return @selector(refersToPredicate:);
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
