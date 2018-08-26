//
//  SpiresHelper.m
//  spires
//
//  Created by Yuji on 08/10/16.
//  Copyright 2008 Y. Tachikawa. All rights reserved.
//

#import "SpiresHelper.h"
#import "NSString+magic.h"
#import "Article.h"
#import "MOC.h"

#define INSPIREWWWHEAD @"http://inspirehep.net/search"


SpiresHelper*_sharedSpiresHelper=nil;
@implementation SpiresHelper
{
    NSManagedObjectContext*moc;
}
-(SpiresHelper*)initWithMOC:(NSManagedObjectContext*)moc_{
    if(self=[super init]){
        moc=moc_;
    }
    return self;
}
+(SpiresHelper*)sharedHelper
{
    if(!_sharedSpiresHelper){
	_sharedSpiresHelper=[[SpiresHelper alloc]initWithMOC:[MOC moc]];
    }
    return _sharedSpiresHelper;
}
+(SpiresHelper*)helperWithMOC:(NSManagedObjectContext*)moc_
{
    return [[SpiresHelper alloc] initWithMOC:moc_];
}

-(NSPredicate*)topcitePredicate:(NSString*)operand
{
    NSArray* a=[operand componentsSeparatedByString:@"+"];
    if([a count]==0)
	return nil; // [NSPredicate predicateWithValue:YES];
    NSNumber *num=@([a[0] intValue]);
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
    Article*a=[Article intelligentlyFindArticleWithId:operand inMOC:moc];
    if(a){
        return [NSPredicate predicateWithFormat:@"refersTo contains %@", a];
    }else{
        return [NSPredicate predicateWithValue:NO];
    }
/*    return [NSPredicate predicateWithBlock:^(id ar,NSDictionary*dict){
	return [a.citedBy containsObject:ar];
    }];
 */
}
-(NSPredicate*)refersToPredicate:(NSString*)operand
{
    Article*a=[Article intelligentlyFindArticleWithId:operand inMOC:moc];
    if(a){
/*	return [NSPredicate predicateWithBlock:^(id ar,NSDictionary*dict){
	    return [a.refersTo containsObject:ar];
	}];
 */
        return [NSPredicate predicateWithFormat:@"citedBy contains %@", a];
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
	NSArray*particles=[[NSUserDefaults standardUserDefaults] objectForKey:@"particles"];
        for(NSString*particle in particles){
            NSString*a=[particle stringByAppendingString:@" "];
            NSString*b=[particle stringByAppendingString:@"+"];
            operand=[operand stringByReplacingOccurrencesOfString:a withString:b];            
        }
	NSArray*xx=[operand componentsSeparatedByString:@" "];
	NSMutableArray*x=[NSMutableArray array];
	for(NSString* s in xx){
	    [x addObject:[s stringByReplacingOccurrencesOfString:@"+" withString:@" "]];
	}
	
	NSString*last=[x lastObject];
	if([x count]==1){
	    //		return [NSPredicate predicateWithFormat:@"%K contains[cd] %@",key,operand];
	    NSString*query=[NSString stringWithFormat:@" %@",last];
	    return [NSPredicate predicateWithFormat:@"%K contains %@",key,query];
	}
	NSMutableArray*y=[NSMutableArray array];
	for(NSUInteger i=0;i<[x count]-1;i++){
	    [y addObject:x[i]];
	}
	NSString* first=[self normalizedFirstAndMiddleNames:y];
//	NSString* query=[[NSString stringWithFormat:@"*; %@*, %@*", last, first] normalizedString];
//	NSPredicate*pred= [NSPredicate predicateWithFormat:@"%K like %@",key,query];	
	NSPredicate*pred= [NSPredicate predicateWithFormat:@"(%K contains %@) and (%K contains %@)",
			   key,[[@"; " stringByAppendingString:last] normalizedString],
			   key,[first normalizedString]];	
	return pred;
    }else{
	NSString* last=c[0];
	NSArray* firsts=[c[1] componentsSeparatedByString:@" "];
	NSString* first=[self normalizedFirstAndMiddleNames:firsts];
	NSString* query=[[NSString stringWithFormat:@"; %@, %@", last, first] normalizedString];
	NSPredicate*pred= [NSPredicate predicateWithFormat:@"%K contains %@",key,query];	
//	NSLog(@"%@",pred);
	return pred;
    }
    return nil;
}
-(NSPredicate*)cnPredicate:(NSString*)operand
{
    if([operand length]<3){
	return nil;
    }
    NSArray*a=[operand componentsSeparatedByString:@" "];
    NSMutableArray*b=[NSMutableArray array];
    for(NSString*s in a){
	if(![s isEqualToString:@""]){
	    [b addObject:s];
	}
    }
    NSString*norm=[[b componentsJoinedByString:@" "] normalizedString];
    NSPredicate*pred2=[NSPredicate predicateWithFormat:@"data.collaboration contains[c] %@",norm];	    
    NSPredicate*pred1=[NSPredicate predicateWithFormat:@"longishAuthorListForA contains %@",norm];
    return [NSCompoundPredicate andPredicateWithSubpredicates:@[pred1,pred2]];    
}
-(NSPredicate*)eaPredicate:(NSString*)operand
{
    operand=[operand stringByReplacingOccurrencesOfString:@" " withString:@" "];
    if([operand length]<3){
	return nil;
    }
    if([operand rangeOfString:@","].location==NSNotFound){
	NSArray* a=[operand componentsSeparatedByString:@" "];
	if([a count]==0)
	    return nil; // [NSPredicate predicateWithValue:YES];
	if([a count]==1){
	    operand=a[0];
	}else{
	    operand=[[a lastObject] stringByAppendingString:@","];
	    for(NSUInteger i=0;i<[a count]-1;i++){
		operand=[operand stringByAppendingString:@" "];
		operand=[operand stringByAppendingString:a[i]];
	    }
	}
    }
    NSPredicate*pred2=[NSPredicate predicateWithFormat:@"data.longishAuthorListForEA contains %@",[operand normalizedString]];	    
    NSPredicate*pred1=[self authorPredicate:operand];
    return [NSCompoundPredicate andPredicateWithSubpredicates:@[pred1,pred2]];    
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
    long long year=[yearString intValue];
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
/*
    internally, eprintForSorting is of the form 
        yyyymmnnnn when yyyy<=2014  (old eprint format and very old non-eprint are normalized to this)
    but
        yyyymmnnnnn when yyyy>=2015
 */
    int multiplier=(year>=2015)?10:1;
    if(op){
	pred= [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"eprintForSorting %@ %@",op,@(year*100*10000*multiplier)]];
    }else{
	long long upper=(year+1)*100*10000*multiplier;
	long long lower=year*100*10000*multiplier;
	pred= [NSPredicate predicateWithFormat:@"(eprintForSorting < %@) and (eprintForSorting > %@)", @(upper), @(lower)];
    }
//    NSLog(@"%@",pred);
    return pred;    
}

-(NSPredicate*)eprintPredicate:(NSString*)operand
{
    if([operand isEqualToString:@""])
	return nil; 
    NSString*norm=[operand normalizedString];
    if([norm length]<4)
	return nil;
    NSString*es=[Article eprintForSortingFromEprint:norm];
    int year=[[es substringToIndex:4] intValue];
    NSUInteger boundary=(year>=2015)?11:10;
    NSUInteger i=[es length]; //2001mmnnnn or 2015mmnnnnn
    NSPredicate*pred1=nil;
    if(i==boundary){
        pred1= [NSPredicate predicateWithFormat:@"eprintForSorting == %@",@([es longLongValue])];
    }else if(i<boundary){
        NSString*zeros=[NSString stringWithFormat:@"%0*d",(int)(boundary-i),0];
        NSString*foo=[es stringByAppendingString:zeros];
        NSString*et=[NSString stringWithFormat:@"%ld",(long)([es integerValue]+1)];
        NSString*bar=[et stringByAppendingString:zeros];
        pred1=[NSCompoundPredicate andPredicateWithSubpredicates:@[
                [NSPredicate predicateWithFormat:@"eprintForSorting >= %@",@([foo longLongValue])],
               [NSPredicate predicateWithFormat:@"eprintForSorting < %@",@([bar  longLongValue])] ]];
    }else{
        pred1=[NSPredicate predicateWithValue:NO];
    }
    NSPredicate*pred2=[NSPredicate predicateWithFormat:@"data.eprint contains %@",norm];
    NSPredicate*pred=[NSCompoundPredicate andPredicateWithSubpredicates:@[pred1,pred2]];
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
    }else if([operator hasPrefix:@"cn"]){
	return @selector(cnPredicate:);
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

-(NSString*)removePrecedingFfrom:(NSString*)t
{
    // this is for old timers who tend to type "fin" at the beginning of the query
    // unfortunately I already used "f" as the query for the flag field,
    // so some special treatment is necessary... Ugh.
    NSString*s=[t stringByReplacingOccurrencesOfRegex:@"^ +" withString:@""];
    s=[s stringByReplacingOccurrencesOfRegex:@" +$" withString:@""];
    if(![s hasPrefix:@"f"]){
	return s;
    }
    if([s hasPrefix:@"f fl"] || [s hasPrefix:@"f pd"] || [s hasPrefix:@"f unre"]){
	return s;
    }
    return [s stringByReplacingOccurrencesOfRegex:@"^ *f\\w* " withString:@""];
}
-(NSPredicate*) predicateFromSPIRESsearchString:(NSString*)string
{
    //    string=[string stringByReplacingOccurrencesOfString:@" and " withString:@" & "];
    string=[string normalizedString];
    string=[self removePrecedingFfrom:string];
    NSArray*a=[string componentsSeparatedByString:@" and "];
    NSMutableArray*arr=[NSMutableArray array];
    SEL operator=NULL;
    NSString*operand=nil;
    for(__strong NSString*s in a){
	BOOL not=NO;
	if([s stringByMatching:@"^ *(not) +(.+)$" capture:1]){
	    not=YES;
	    s=[s stringByMatching:@"^ *(not) +(.+)$" capture:2];
	}
	SEL op=[self extractOperator:s];
	if(!op && !operator)
	    return nil;
	if(op){
	    operator=op;
	    operand=[self extractOperand:s];
	}else{
	    operand=s;
	}
	if([operand length]<3)
	    continue;
	operand=[operand stringByReplacingOccurrencesOfString:@"#" withString:@""];
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
	NSPredicate*p=[self performSelector:operator withObject:operand];
	if(p){
	    if(not){
		p=[NSCompoundPredicate notPredicateWithSubpredicate:p];
	    }
	    [arr addObject:p];
	}
    }
    NSPredicate*pred=nil;
    if([arr count]==0){
	pred=[NSPredicate predicateWithValue:YES];
    }else if([arr count]==1){
	pred= arr[0];
    }else{
	pred=[[NSCompoundPredicate alloc] initWithType:NSAndPredicateType
					 subpredicates:arr];
    }
//    NSLog(@"%@",pred);
    return pred;
}

#pragma mark Bib Entries Query

-(NSArray*)bibtexEntriesForQuery:(NSString*)search
{
    NSURL* url=[NSURL URLWithString:[[NSString stringWithFormat:@"%@?p=%@&of=hx",INSPIREWWWHEAD,search ] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding ] ];
    NSString*s= [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:nil];
    NSLog(@"fetching:%@",url);
//    NSString*s= [NSString stringWithContentsOfURL:url encoding:NSISOLatin1StringEncoding error:nil];


    NSArray*a=[s componentsSeparatedByString:@"<pre>"];
    if(!a || [a count]<2)return nil;
    NSMutableArray* result=[NSMutableArray array];
    for(NSUInteger i=1;i<[a count];i++){
	NSString*x=a[i];
	NSRange r=[x rangeOfString:@"</pre>"];
	x=[x substringToIndex:r.location];
        x=[x stringByReplacingOccurrencesOfString:@"&nbsp;" withString:@" "];
        x=[x stringByReplacingOccurrencesOfString:@"<br>" withString:@"\n"];
	[result addObject:x];
    }
    return result;
}

-(NSArray*)latexEUEntriesForQuery:(NSString*)search
{
    NSURL* url=[NSURL URLWithString:[[NSString stringWithFormat:@"%@?p=%@&of=hlxe",INSPIREWWWHEAD,search ] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding ] ];

    NSString*s= [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:nil];
    NSLog(@"fetching:%@",url);
//    NSString*s= [NSString stringWithContentsOfURL:url encoding:NSISOLatin1StringEncoding error:nil];


    NSArray*a=[s componentsSeparatedByString:@"<pre>"];
    if(!a || [a count]<2)return nil;
    NSMutableArray* result=[NSMutableArray array];
    for(NSUInteger i=1;i<[a count];i++){
	NSString*x=a[i];
	NSRange r=[x rangeOfString:@"</pre>"];
	x=[x substringToIndex:r.location];
        x=[x stringByReplacingOccurrencesOfString:@"&nbsp;" withString:@" "];
        x=[x stringByReplacingOccurrencesOfString:@"<br>" withString:@"\n"];
	[result addObject:x];
    }
    return result;
}

-(NSArray*)harvmacEntriesForQuery:(NSString*)search
{
    NSURL* url=[NSURL URLWithString:[[NSString stringWithFormat:@"%@?p=%@&of=hlxh",INSPIREWWWHEAD,search ] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding ] ];

    NSString*s= [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:nil];
    NSLog(@"fetching:%@",url);
  //  NSString*s= [NSString stringWithContentsOfURL:url encoding:NSISOLatin1StringEncoding error:nil];
    NSArray*a=[s componentsSeparatedByString:@"<pre>"];
    if(!a || [a count]<2)return nil;
    NSMutableArray* result=[NSMutableArray array];
    for(NSUInteger i=1;i<[a count];i++){
	NSString*x=a[i];
	NSRange r=[x rangeOfString:@"</pre>"];
	x=[x substringWithRange:NSMakeRange(1,r.location-1)];
        x=[x stringByReplacingOccurrencesOfString:@"&nbsp;" withString:@" "];
        x=[x stringByReplacingOccurrencesOfString:@"<br>" withString:@"\n"];
	[result addObject:x];
    }
    return result;
}




-(NSURL*)inspireURLForQuery:(NSString*)search
{
    return [NSURL URLWithString:[[NSString stringWithFormat:@"%@?p=%@", INSPIREWWWHEAD,search ] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding ] ];
}

@end
