// 
//  Article.m
//  spires
//
//  Created by Yuji on 08/10/13.
//  Copyright 2008 Y. Tachikawa. All rights reserved.
//

#import "Article.h"
#import "Author.h"
#import "AllArticleList.h"
#import "NDAlias.h"
#import "NSString+magic.h"

//NSMutableDictionary* eprintDict=nil;
@interface Article (Primitives)
-(void)setPrimitiveTitle:(NSString*)t;
-(NSMutableSet*)primitiveAuthors;
-(void)setPrimitiveEprint:(NSString*)e;
-(void)setPrimitiveDate:(NSDate*)d;
@end
@implementation Article 

@dynamic journal;
@dynamic comments;
@dynamic version;
@dynamic pages;
@dynamic doi;
@dynamic eprint;
@dynamic abstract;
@dynamic citecount;
@dynamic spicite;
@dynamic title;
@dynamic memo;
@dynamic date;
@dynamic authors;
@dynamic citedBy;
@dynamic refersTo;
@dynamic pdfAlias;
@dynamic extraURLs;
@dynamic spiresKey;
@dynamic texKey;
@dynamic preferredId;
@dynamic normalizedTitle;
@dynamic longishAuthorListForA;
@dynamic shortishAuthorList;
@dynamic longishAuthorListForEA;
@dynamic eprintForSorting;

+(void)initialize
{
//    eprintDict=[NSMutableDictionary dictionary];
}

+(Article*)newArticleInMOC:(NSManagedObjectContext*)moc
{
    NSEntityDescription*articleEntity=[NSEntityDescription entityForName:@"Article" inManagedObjectContext:moc];
    Article*a=[[NSManagedObject alloc] initWithEntity:articleEntity insertIntoManagedObjectContext:moc];
    [[AllArticleList allArticleListInMOC:moc] addArticlesObject:a];
    return a;
}
+(Article*)articleWith:(NSString*)value forKey:(NSString*)key inMOC:(NSManagedObjectContext*)moc
{
    // returns nil if not found.
/*    BOOL isEprint=[@"eprint" isEqualToString:key];
    if(isEprint){
	Article*a=[eprintDict valueForKey:value];
	if(a)return a;
    }*/
    NSEntityDescription*articleEntity=[NSEntityDescription entityForName:@"Article" inManagedObjectContext:moc];
    NSFetchRequest*req=[[NSFetchRequest alloc]init];
    [req setEntity:articleEntity];
    NSPredicate*pred=[NSPredicate predicateWithFormat:@"%K = %@",key,value];
    [req setPredicate:pred];
    NSError*error=nil;
    NSArray*a=[moc executeFetchRequest:req error:&error];
    Article*ar=nil;
    if(a==nil || [a count]==0){
/*	ar=[Article newArticleInMOC:moc];
	[ar setValue:value forKey:key];*/
    }else{
	ar=[a objectAtIndex:0];
    }
/*    if(isEprint && ar){
	[eprintDict setObject:ar forKey:value];
    }*/
    return ar;
}
+(Article*)intelligentlyFindArticleWithId:(NSString*)idToLookUp inMOC:(NSManagedObjectContext*)moc
{
    if([idToLookUp hasPrefix:@"arXiv:"]){
	return [Article articleWith:idToLookUp
			     forKey:@"eprint"
			      inMOC:moc];
    }
    if([idToLookUp rangeOfString:@"."].location!=NSNotFound){
	return [Article articleWith:[@"arXiv:" stringByAppendingString:idToLookUp]
			     forKey:@"eprint"
			      inMOC:moc];
    }
    if([idToLookUp rangeOfString:@"/"].location!=NSNotFound){
	return [Article articleWith:idToLookUp
			     forKey:@"eprint"
			      inMOC:moc];
    }
    if([idToLookUp rangeOfString:@":"].location!=NSNotFound){
	AllArticleList*all=[AllArticleList allArticleListInMOC:moc];
	NSSet* s=[all articles];
	NSPredicate *predicate =
	[NSPredicate predicateWithFormat:@"SELF.texKey beginswith %@",idToLookUp];
	NSSet* x=[s filteredSetUsingPredicate:predicate];
	if([x count]>0){
	    return [x anyObject];
	}
    }
    return nil;
}
-(void)awakeFromFetch
{
    [super awakeFromFetch];
    [self addObserver:self
	   forKeyPath:@"authors"
	      options:NSKeyValueObservingOptionNew // |NSKeyValueObservingOptionInitial
	      context:nil];
}
-(void)awakeFromInsert
{
    [super awakeFromInsert];
    [self addObserver:self
	   forKeyPath:@"authors"
	      options:NSKeyValueObservingOptionNew // |NSKeyValueObservingOptionInitial
	      context:nil];
}

#pragma mark Extras Management
-(void)setExtra:(id)content forKey:(NSString*)key
{
    NSMutableDictionary* dict=[NSPropertyListSerialization propertyListFromData:self.extraURLs 
							mutabilityOption:NSPropertyListMutableContainers
								  format: NULL
							       errorDescription:NULL];
    if(!dict){
	dict=[NSMutableDictionary dictionary];
    }
    [dict setValue:content forKey:key];
    self.extraURLs=[NSPropertyListSerialization dataFromPropertyList:dict 
							      format:NSPropertyListBinaryFormat_v1_0
						    errorDescription:nil];
}

-(id)extraForKey:(NSString*)key
{
    NSMutableDictionary* dict=[NSPropertyListSerialization propertyListFromData:self.extraURLs 
							       mutabilityOption:NSPropertyListMutableContainers
									 format: NULL
							       errorDescription:nil];
    return [dict valueForKey:key];
}

#pragma mark Sort Key Precalculation 
-(NSString*)calculateShortishAuthorList
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
	[a addObject:[@"; " stringByAppendingString:i.name]];
    }
    [a sortUsingSelector:@selector(caseInsensitiveCompare:)];
    
    return [[a componentsJoinedByString:@""] normalizedString];
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
	[result appendString:@"; "];
	NSArray* c=[s componentsSeparatedByString:@", "];
	if([c count]==1){
	    [result appendString:s];
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
    }
    return [result normalizedString];
    
}
-(void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if([keyPath isEqualToString:@"authors"]){
	self.shortishAuthorList=[self calculateShortishAuthorList];
	self.longishAuthorListForA=[self calculateLongishAuthorListForA];
	self.longishAuthorListForEA=[self calculateLongishAuthorListForEA];	
    }
}

/*- (void)addAuthorsObject:(NSManagedObject *)value
{
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    [self addAuthors:changedObjects];
}

- (void)removeAuthorsObject:(NSManagedObject *)value
{
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    [self removeAuthors:changedObjects];
}

- (void)addAuthors:(NSSet *)value
{
    [self willChangeValueForKey:@"authors"
		withSetMutation:NSKeyValueUnionSetMutation
		   usingObjects:value];
    [[self primitiveAuthors] unionSet:value];
    [self didChangeValueForKey:@"authors"
	       withSetMutation:NSKeyValueUnionSetMutation
		  usingObjects:value];
    self.longishAuthorListForA=[self calculateLongishAuthorListForA];
    self.longishAuthorListForEA=[self calculateLongishAuthorListForEA];	
    self.shortishAuthorList=[self calculateShortishAuthorList];	
}

- (void)removeAuthors:(NSSet *)value
{
    [self willChangeValueForKey:@"authors"
		withSetMutation:NSKeyValueMinusSetMutation
		   usingObjects:value];
    [[self primitiveAuthors] minusSet:value];
    [self didChangeValueForKey:@"authors"
	       withSetMutation:NSKeyValueMinusSetMutation
		  usingObjects:value];
    self.longishAuthorListForA=[self calculateLongishAuthorListForA];
    self.longishAuthorListForEA=[self calculateLongishAuthorListForEA];	
    self.shortishAuthorList=[self calculateShortishAuthorList];	
}*/

-(NSString*)calculateEprintForSorting
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
-(void)setEprint:(NSString*)e
{
    [self willChangeValueForKey:@"eprint"];
    [self setPrimitiveEprint:e];
    self.eprintForSorting=[NSNumber numberWithInt:[[self calculateEprintForSorting] intValue]];
    [self didChangeValueForKey:@"eprint"];
}

-(void)setDate:(NSDate*)d
{
    [self willChangeValueForKey:@"date"];
    [self setPrimitiveDate:d];
    self.eprintForSorting=[NSNumber numberWithInt:[[self calculateEprintForSorting] intValue]];
    [self didChangeValueForKey:@"date"];
}
-(NSString*)quieterTitle //calculateQuieterTitle
{
    if([self eprint]){
	return [self title];
    }
    if(![self title]){
	return nil;
    }
    return [self.title quieterVersion];
}
-(NSString*)calculateNormalizedTitle
{
    return [self.title normalizedString];
}

-(void)setTitle:(NSString*)t
{
    [self willChangeValueForKey:@"title"];
    [self setPrimitiveTitle:t];
    self.normalizedTitle=[self calculateNormalizedTitle];
//    self.quieterTitle=[self calculateQuieterTitle];
    [self didChangeValueForKey:@"title"];
}
#pragma mark Misc.
+(NSSet*)keyPathsForValuesAffectingPdfPath
{
    return [NSSet setWithObjects:@"pdfAlias",nil];
}
-(ArticleType)articleType
{
    if(self.eprint && ![self.eprint isEqualToString:@""]){
	return ATEprint;
    }else if(self.spicite && ![self.spicite isEqualToString:@""]){
	return ATSpires;
    }else if(self.spiresKey && ![self.spiresKey isEqualToString:@""]){
	return ATSpiresWithOnlyKey;
    }
    return ATGeneric;
}
-(NSString*)pdfPath
{
    if(self.pdfAlias){
	NDAlias* alias=[NDAlias aliasWithData:self.pdfAlias];
	if(alias){
	    NSString* path=[alias path];
	    if(path){
		[self setPrimitiveValue:[alias data] forKey:@"pdfAlias"];
	    }else{
		[self setPrimitiveValue:nil forKey:@"pdfAlias"];		
	    }
	    return path;
	}
    }else if(self.articleType==ATEprint){
	NSString* name=self.eprint;
	if([name hasPrefix:@"arXiv:"]){
	    name=[name substringFromIndex:[(NSString*)@"arXiv:" length]];
	}
	name=[name stringByReplacingOccurrencesOfString:@"/" withString:@""];
	NSString*pdfDir=[[NSUserDefaults standardUserDefaults] stringForKey:@"pdfDir"];
	return [[NSString stringWithFormat:@"%@/%@.pdf",pdfDir,name] stringByExpandingTildeInPath];
    }
    return nil;
}
-(void)associatePDF:(NSString*)path
{
    self.pdfAlias=[[NDAlias aliasWithPath:path] data];
}

-(BOOL)hasPDFLocally
{
    BOOL b= [[NSFileManager defaultManager] fileExistsAtPath:self.pdfPath];
    return b;
}
-(NSString*)associatedPDFPath
{
    return nil;
}
-(NSString*)preferredId
{
    if(self.texKey && ![self.texKey isEqualToString:@""]){
	return self.texKey;
    }
    if(self.articleType==ATEprint){
	NSString*s=self.eprint;
	if([s hasPrefix:@"arXiv:"]){
	    return [s substringFromIndex:[(NSString*)@"arXiv:" length]];
	}else{
	    return s;
	}
    }else if(self.articleType==ATSpires){
	return self.spicite;
    }else if(self.articleType==ATSpiresWithOnlyKey){
	return self.spiresKey;
    }else{
	return @"shouldn't happen";
    }
}
@end
