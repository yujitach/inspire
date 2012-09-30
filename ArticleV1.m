// 
//  Article.m
//  spires
//
//  Created by Yuji on 08/10/13.
//  Copyright 2008 Y. Tachikawa. All rights reserved.
//

#import "ArticleV1.h"
#import "Author.h"
#import "AllArticleList.h"
#import "NDAlias.h"
#import "NSString+magic.h"


@implementation ArticleV1
-(void)awakeFromFetch
{
    [super awakeFromFetch];
    [self removeObserver:self forKeyPath:@"authors"];
    [self addObserver:self
	   forKeyPath:@"authors"
	      options:NSKeyValueObservingOptionNew |NSKeyValueObservingOptionInitial
	      context:nil];
}
-(void)awakeFromInsert
{
    [super awakeFromInsert];
    [self removeObserver:self forKeyPath:@"authors"];
    [self addObserver:self
	   forKeyPath:@"authors"
	      options:NSKeyValueObservingOptionNew |NSKeyValueObservingOptionInitial
	      context:nil];
}

-(NSString*)shortishAuthorList
{
    NSMutableArray*a=[NSMutableArray array];
    for(Author*i in self.authors){
	[a addObject:i.lastName];
    }
    [a sortUsingSelector:@selector(caseInsensitiveCompare:)];
    
    return [a componentsJoinedByString:@", "];
}
-(NSString*)calculateLongishAuthorListForEA
{
    NSMutableArray*a=[NSMutableArray array];
    for(Author*i in self.authors){
	[a addObject:i.name];
    }
    [a sortUsingSelector:@selector(caseInsensitiveCompare:)];
    
    return [a componentsJoinedByString:@"; "];
}
-(NSString*)calculateLongishAuthorListForA
{
    NSMutableArray*a=[NSMutableArray array];
    for(Author*i in self.authors){
	[a addObject:i.name];
    }
    [a sortUsingSelector:@selector(caseInsensitiveCompare:)];
    NSMutableString*result=[NSMutableString string];
    for(NSString*s in a){
	NSArray* c=[s componentsSeparatedByString:@", "];
	if([c count]==1){
	    [result appendString:s];
	    [result appendString:@"; "];
	    continue;
	}
	NSString* last=[c objectAtIndex:0];
	[result appendString:last];
	[result appendString:@", "];
	    NSArray* d=[[c objectAtIndex:1] componentsSeparatedByString:@" "];
	    for(NSString*i in d){
		if(!i || [i isEqualToString:@""]) continue;
		[result appendString:[i substringToIndex:1]];
		[result appendString:@". "];
	    }
	[result appendString:@"; "];
    }
    return result;
    
}

-(NSString*)longishAuthorListForA
{
    if(!longishAuthorListForA){
	longishAuthorListForA=[self calculateLongishAuthorListForA];
    }
    return longishAuthorListForA;
}

-(NSString*)longishAuthorListForEA
{
    if(!longishAuthorListForEA){
	longishAuthorListForEA=[self calculateLongishAuthorListForEA];
    }
    return longishAuthorListForEA;
}

-(NSString*)longishAuthorList
{
    NSMutableArray*a=[NSMutableArray array];
    for(Author*i in self.authors){
	[a addObject:i.name];
    }
    [a sortUsingSelector:@selector(caseInsensitiveCompare:)];
    NSMutableString*result=[NSMutableString string];
    for(NSString*s in a){
	NSArray* c=[s componentsSeparatedByString:@", "];
	if([c count]==1){
	    [result appendString:s];
	    [result appendString:@"; "];
	    continue;
	}
	NSString* last=[c objectAtIndex:0];
	NSArray* d=[[c objectAtIndex:1] componentsSeparatedByString:@" "];
	for(NSString*i in d){
	    if(!i || [i isEqualToString:@""]) continue;
	    [result appendString:[i substringToIndex:1]];
	    [result appendString:@". "];
	}
	[result appendString:last];
	[result appendString:@"; "];
    }
    return result;
}

-(NSString*)_eprintForSorting
{
    NSString*eprint=self.eprint;
    if(!eprint){
	if(self.date){
	    NSDate*date=self.date;
	    NSString*s=[date descriptionWithCalendarFormat:@"%Y%m0000"
						  timeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]
						    locale:nil];
	    return s;
	}
	return nil;
    }
    if([eprint isEqualToString:@""])return nil;
    if([eprint hasPrefix:@"arXiv:"]){
	NSString*y=[@"20" stringByAppendingString:[eprint substringFromIndex:[(NSString*)@"arXiv:" length]]];
	return [y stringByReplacingOccurrencesOfString:@"." withString:@""];
    }
    NSString*x=[[eprint componentsSeparatedByString:@"/"]objectAtIndex:1];
    x=[x stringByAppendingString:@"0"];
    if([x hasPrefix:@"0"]){
	return [@"20" stringByAppendingString:x];
    }
    return [@"19" stringByAppendingString:x];
}
-(NSString*)eprintForSorting
{
    if(!_eprintForSorting){
	_eprintForSorting=[self _eprintForSorting];
    }
    return _eprintForSorting;
}
-(NSString*)quieterTitle
{
    if([self eprint]){
	return [self title];
    }
    if(![self title]){
	return nil;
    }
    if(!_quieterTitle){
	_quieterTitle=[self.title quieterVersion];
    }
    return _quieterTitle;
}
-(NSString*)texKey
{
    return [self extraForKey:@"texKey"];
}

-(void)setTexKey:(NSString*)s
{
    [self willChangeValueForKey:@"texKey"];
    [self setExtra:s forKey:@"texKey"];
    [self didChangeValueForKey:@"texKey"];
    
}
-(void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if([keyPath isEqualToString:@"authors"]){
	longishAuthorListForA=[self calculateLongishAuthorListForA];
	longishAuthorListForEA=[self calculateLongishAuthorListForEA];	
    }
}

@end
