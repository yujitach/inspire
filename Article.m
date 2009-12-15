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
#import "NSString+magic.h"
#import "MOC.h"
#import "ArticleData.h"
#import "RegexKitLite.h"
#import <objc/runtime.h>

@implementation Article 

@dynamic journal;
@dynamic flagInternal;
@dynamic citedBy;
@dynamic refersTo;
@dynamic citecount;
@dynamic uniqueId;
@dynamic IdForCitation;
@dynamic normalizedTitle;
@dynamic longishAuthorListForA;
@dynamic eprintForSorting;
@dynamic data;
@dynamic eprintForSortingAsString;


#pragma mark Misc
-(void)awakeFromInsert
{
    NSEntityDescription*articleDataEntity=[NSEntityDescription entityForName:@"ArticleData" inManagedObjectContext:[self managedObjectContext]];
    ArticleData*data=(ArticleData*)[[NSManagedObject alloc] initWithEntity:articleDataEntity
				  insertIntoManagedObjectContext:[self managedObjectContext]];
    self.data=data;
    [self setFlag:AFNone];
    [super awakeFromInsert];
}
/* +(Article*)newArticleInMOC:(NSManagedObjectContext*)moc
{
    NSEntityDescription*articleEntity=[NSEntityDescription entityForName:@"Article" inManagedObjectContext:moc];
    Article*a=[[NSManagedObject alloc] initWithEntity:articleEntity insertIntoManagedObjectContext:moc];
    [[AllArticleList allArticleListInMOC:moc] addArticlesObject:a];
    return a;
}*/

+(NSString*)eprintForSortingFromEprint:(NSString*)eprint
{
    if([[eprint lowercaseString] hasPrefix:@"arxiv:"]){
	NSString*y=[@"20" stringByAppendingString:[eprint substringFromIndex:[(NSString*)@"arXiv:" length]]];
	return [y stringByReplacingOccurrencesOfString:@"." withString:@""];
    }
    if([eprint rangeOfString:@"."].location!=NSNotFound){
	NSString*y=[@"20" stringByAppendingString:eprint ];
	return [y stringByReplacingOccurrencesOfString:@"." withString:@""];
    }
    NSArray*a=[eprint componentsSeparatedByString:@"/"];
    NSString*x=eprint;
    if([a count]>1){
	x=[a objectAtIndex:1];
	x=[x stringByAppendingString:@"0"];
    }
    if([x hasPrefix:@"0"]){
	return [@"20" stringByAppendingString:x];
    }
    return [@"19" stringByAppendingString:x];
    
}
-(NSString*)eprintForSortingAsString
{
    return [self.eprintForSorting stringValue];
}
+(Article*)articleWithEprint:(NSString *)eprint inMOC:(NSManagedObjectContext *)moc
{
    NSEntityDescription*articleEntity=[NSEntityDescription entityForName:@"Article" inManagedObjectContext:moc];
    NSFetchRequest*req=[[NSFetchRequest alloc]init];
    [req setEntity:articleEntity];
    NSString*es=[Article eprintForSortingFromEprint:eprint];
    NSPredicate*pred=[NSPredicate predicateWithFormat:@"eprintForSorting = %@",es];
    [req setPredicate:pred];
    [req setIncludesPropertyValues:YES];
    [req setRelationshipKeyPathsForPrefetching:[NSArray arrayWithObject:@"data"]];
    [req setReturnsObjectsAsFaults:NO];
    [req setFetchLimit:10];
    NSError*error=nil;
    NSArray*a=[moc executeFetchRequest:req error:&error];
    if(a==nil || [a count]==0){
	return nil;
    }else{
	NSRange r=[eprint rangeOfString:@"/"];
	if(r.location!=NSNotFound){
	    // old style eprint
	    NSString*prefix=[eprint substringToIndex:r.location];
	    for(Article*ar in a){
		if([ar.data.eprint hasPrefix:prefix]){
		    return ar;
		}
	    }
	    return nil;
	}else{
	    // new style eprint
	    Article*ar=[a objectAtIndex:0];
	    return ar;
	}
    }    
}
+(Article*)articleWith:(NSString*)value inDataForKey:(NSString*)key inMOC:(NSManagedObjectContext*)moc
{
    NSEntityDescription*articleEntity=[NSEntityDescription entityForName:@"ArticleData" inManagedObjectContext:moc];
    NSFetchRequest*req=[[NSFetchRequest alloc]init];
    [req setEntity:articleEntity];
    NSPredicate*pred=[NSPredicate predicateWithFormat:@"%K = %@",key,value];
    [req setPredicate:pred];

    [req setIncludesPropertyValues:YES];
    [req setRelationshipKeyPathsForPrefetching:[NSArray arrayWithObject:@"article"]];
    [req setReturnsObjectsAsFaults:NO];
    
    [req setFetchLimit:1];
    NSError*error=nil;
    NSArray*a=[moc executeFetchRequest:req error:&error];
    if(a==nil || [a count]==0){
	return nil;
    }else{
	ArticleData*ad=[a objectAtIndex:0];
	return ad.article;
    }
}
+(Article*)intelligentlyFindArticleWithId:(NSString*)idToLookUp inMOC:(NSManagedObjectContext*)moc
{
    if([idToLookUp hasPrefix:@"arXiv:"]){
	return [Article articleWithEprint:idToLookUp inMOC:moc];
    }
    if([idToLookUp rangeOfString:@"."].location!=NSNotFound){
	return [Article articleWithEprint:idToLookUp inMOC:moc];
    }
    if([idToLookUp rangeOfString:@"/"].location!=NSNotFound){
	return [Article articleWithEprint:idToLookUp inMOC:moc];
    }
    if([idToLookUp rangeOfString:@","].location!=NSNotFound){
	return [Article articleWith:[idToLookUp uppercaseString]
		       inDataForKey:@"spicite"
			      inMOC:moc];
    }
    if([idToLookUp rangeOfString:@":"].location!=NSNotFound){
	return [Article articleWith:idToLookUp
		       inDataForKey:@"texKey"
			      inMOC:moc];
    }
    return nil;
}




+(NSString*)longishAuthorListForAFromAuthorNames:(NSArray*)array;
{
    
    NSMutableArray*a=[NSMutableArray array];
    for(NSString*x in array){
	[a addObject:x];
    }
    [a sortUsingSelector:@selector(caseInsensitiveCompare:)];
    NSMutableString*result=[NSMutableString string];
    for(NSString*s in a){
	[result appendString:@"; "];
	if([s hasPrefix:@"collaboration"]){
	    [result appendString:s];
	    continue;
	}
	if([s rangeOfString:@"for the"].location!=NSNotFound){
	    [result appendString:s];
	    continue;
	}
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
    return result;
    
    
    
}
    
+(NSString*)longishAuthorListForEAFromAuthorNames:(NSArray*)array;
{
    NSMutableArray*a=[NSMutableArray array];
    for(NSString*s  in array){
	[a addObject:s];
    }
    [a sortUsingSelector:@selector(caseInsensitiveCompare:)];
    return [a componentsJoinedByString:@"; "];
}
 
+(NSString*)shortishAuthorListFromAuthorNames:(NSArray*)array;
{
    NSMutableArray*a=[NSMutableArray array];
    NSString*collaboration=nil;
    for(NSString*s in array){
	NSArray*q=[s componentsSeparatedByString:@", "];
	NSString*lastName=[q objectAtIndex:0];
	if([lastName rangeOfString:@"collaboration"].location!=NSNotFound){
	    lastName=[lastName stringByReplacingOccurrencesOfRegex:@" *collaborations? *" withString:@""];
	    lastName=[lastName uppercaseString];
	    collaboration=lastName;
	    continue;
	}else{
	    lastName=[lastName capitalizedStringForName];
	}
	[a addObject:lastName];
    }
    [a sortUsingSelector:@selector(caseInsensitiveCompare:)];
    
    if(collaboration){
	if([a count]>0){
	    return [NSString stringWithFormat:@"%@ (%@)",collaboration,[a componentsJoinedByString:@", "]];
	}else{
	    return collaboration;
	}
    }else{
	return [a componentsJoinedByString:@", "];
    }
}
+(NSString*)flagInternalFromFlag:(ArticleFlag)flag;
{
    NSMutableString*s=[NSMutableString string];
    if(flag&AFIsUnread){
	[s appendString:@"U"];
    }
    if(flag&AFIsFlagged){
	[s appendString:@"F"];
    }
    if(flag&AFHasPDF){
	[s appendString:@"P"];
    }
    return s;
}
+(ArticleFlag)flagFromFlagInternal:(NSString*)flagInternal;
{
    ArticleFlag f=AFNone;
    if([flagInternal rangeOfString:@"U"].location!=NSNotFound){
	f|=AFIsUnread;
    }
    if([flagInternal rangeOfString:@"F"].location!=NSNotFound){
	f|=AFIsFlagged;
    }
    if([flagInternal rangeOfString:@"P"].location!=NSNotFound){
	f|=AFHasPDF;
    }
    return f;
}


#pragma mark Extras Management
-(void)setExtra:(id)content forKey:(NSString*)key
{
    NSMutableDictionary* dict=[NSPropertyListSerialization propertyListFromData:self.data.extraURLs 
							mutabilityOption:NSPropertyListMutableContainers
								  format: NULL
							       errorDescription:NULL];
    if(!dict){
	dict=[NSMutableDictionary dictionary];
    }
    [dict setValue:content forKey:key];
    self.data.extraURLs=[NSPropertyListSerialization dataFromPropertyList:dict 
							      format:NSPropertyListBinaryFormat_v1_0
						    errorDescription:nil];
}

-(id)extraForKey:(NSString*)key
{
    NSMutableDictionary* dict=[NSPropertyListSerialization propertyListFromData:self.data.extraURLs 
							       mutabilityOption:NSPropertyListMutableContainers
									 format: NULL
							       errorDescription:nil];
    return [dict valueForKey:key];
}

#pragma mark Sort Key Precalculation 

-(void)setAuthorNames:(NSArray *)authorNames
{
    NSMutableArray*a=[NSMutableArray array];
    if(self.collaboration){
	NSMutableString*s=[[self.collaboration normalizedString] mutableCopy];
	[s replaceOccurrencesOfRegex:@" *on +behalf +of +the *" withString:@""];
	[s replaceOccurrencesOfRegex:@" *for +the *" withString:@""];
	[s replaceOccurrencesOfRegex:@"^the *" withString:@""];
	[a addObject:s];
    }
    for(NSString*s in authorNames){
	if(![s isEqualToString:@""]){
	    [a addObject:[s normalizedString]];
	}
    }
    self.shortishAuthorList=[Article shortishAuthorListFromAuthorNames:a];
    self.longishAuthorListForA=[Article longishAuthorListForAFromAuthorNames:a];
    self.longishAuthorListForEA=[Article longishAuthorListForEAFromAuthorNames:a];	
}

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
    return [Article eprintForSortingFromEprint:eprint];
}

/*- (NSString *)eprint 
{
    NSString * tmpValue;
    
//    [self willAccessValueForKey:@"eprint"];
    tmpValue = [self.data eprint];
//    [self didAccessValueForKey:@"eprint"];
    
    return tmpValue;
}*/
-(void)setEprint:(NSString*)e
{
//    [self willChangeValueForKey:@"eprint"];
    [self.data setEprint:e];
    self.eprintForSorting=[NSNumber numberWithInt:[[self calculateEprintForSorting] intValue]];
//    [self didChangeValueForKey:@"eprint"];
}
-(NSString*)eprintToShow
{
    NSString*eprint=self.eprint;
    if(!eprint)
	return nil;
    if([eprint hasPrefix:@"arXiv:"]){
	return [eprint substringFromIndex:[@"arXiv:" length]];
    }else{
	return eprint;
    }
    return nil;
}
/*- (NSDate *)date 
{
    NSDate * tmpValue;
    
//    [self willAccessValueForKey:@"date"];
    tmpValue = [self.data date];
//    [self didAccessValueForKey:@"date"];
    
    return tmpValue;
}*/

-(void)setDate:(NSDate*)d
{
//    [self willChangeValueForKey:@"date"];
    [self.data setDate:d];
    self.eprintForSorting=[NSNumber numberWithInt:[[self calculateEprintForSorting] intValue]];
//    [self didChangeValueForKey:@"date"];
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

/*- (NSString *)title
{
    NSString * tmpValue;
    
//    [self willAccessValueForKey:@"title"];
    tmpValue = [self.data title];
//    [self didAccessValueForKey:@"title"];
    
    return tmpValue;
}*/
-(void)setTitle:(NSString*)t
{
//    [self willChangeValueForKey:@"title"];
    [self.data setTitle:t];
    self.normalizedTitle=[self calculateNormalizedTitle];
//    self.quieterTitle=[self calculateQuieterTitle];
//    [self didChangeValueForKey:@"title"];
}
#pragma mark Misc.
+(NSSet*)keyPathsForValuesAffectingPdfPath
{
    return [NSSet setWithObjects:@"pdfAlias",@"data.pdfAlias",nil];
}
-(ArticleType)articleType
{
    if(self.eprint && ![self.eprint isEqualToString:@""]){
	return ATEprint;
    }else if(self.spicite && ![self.spicite isEqualToString:@""]){
	return ATSpires;
    }else if(self.spiresKey && [self.spiresKey integerValue]!=0){
	return ATSpiresWithOnlyKey;
    }
    return ATGeneric;
}
-(NSString*)pdfPath
{
    if(self.data.pdfAlias){
	NSError*error=nil;
	BOOL isStale=NO;
	NSURL* url=[NSURL URLByResolvingBookmarkData:self.data.pdfAlias
					     options:NSURLBookmarkResolutionWithoutUI|NSURLBookmarkResolutionWithoutMounting 
				       relativeToURL:nil
				 bookmarkDataIsStale:&isStale
					       error:&error];
	if(url){
	    NSString* path=[url path];
	    if(isStale){
		[self associatePDF:path];
	    }
	    return path;
	}else{
	    [self associatePDF:nil];
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
    if(!path){
	self.data.pdfAlias=nil;
    }
    NSError*error=nil;
    self.data.pdfAlias=[[NSURL fileURLWithPath:path] bookmarkDataWithOptions:NSURLBookmarkCreationMinimalBookmark
					 includingResourceValuesForKeys:nil
							  relativeToURL:nil
								  error:&error];
    [self setFlag:self.flag | AFHasPDF];
}

-(BOOL)hasPDFLocally
{
    BOOL b= [[NSFileManager defaultManager] fileExistsAtPath:self.pdfPath];
    if(b){
	[self setFlag:self.flag | AFHasPDF];
	if(!self.data.pdfAlias){
	    [self associatePDF:self.pdfPath];
	}
    }
    return b;
}
-(NSString*)IdForCitation
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
	return [self.spiresKey stringValue];
    }else{
	return @"shouldn't happen";
    }
}
-(NSString*)uniqueId
{
    if(self.articleType==ATEprint){
	NSString*s=self.eprint;
	s=[s stringByReplacingOccurrencesOfString:@"/" withString:@""];
	if([s hasPrefix:@"arXiv:"]){
	    return [s substringFromIndex:[(NSString*)@"arXiv:" length]];
	}else{
	    return s;
	}
    }else if(self.articleType==ATSpires){
	return self.spicite;
    }else if(self.articleType==ATSpiresWithOnlyKey){
	return [self.spiresKey stringValue];
    }else{
	return @"shouldn't happen";
    }
}
-(NSImage*)flagImage
{
    ArticleFlag af=self.flag;
    if(af&AFIsFlagged){
	return [NSImage imageNamed:@"flagged.png"];
    }else if(af&AFIsUnread){
	return [NSImage imageNamed:@"unread.png"];
    }else if(af&AFHasPDF){
	return [NSImage imageNamed:@"hasPDF.png"];
    }
    return nil;
}
+(NSSet*)keyPathsForValuesAffectingFlagImage
{
    return [NSSet setWithObjects:@"flagInternal",nil];
}
-(void)setFlag:(ArticleFlag)flag
{
    self.flagInternal=[Article flagInternalFromFlag:flag];
}
-(ArticleFlag)flag
{
    return [Article flagFromFlagInternal:self.flagInternal];
}

#pragma mark Property Forwarding
/*
- (NSString *)abstract
{
    NSString * tmpValue;
    
//    [self willAccessValueForKey:@"abstract"];
    tmpValue = [self.data abstract];
//    [self didAccessValueForKey:@"abstract"];
    
    return tmpValue;
}

- (void)setAbstract:(NSString *)value 
{
//    [self willChangeValueForKey:@"abstract"];
    [self.data setAbstract:value];
//    [self didChangeValueForKey:@"abstract"];
}

- (NSString *)arxivCategory
{
    NSString * tmpValue;
    
//    [self willAccessValueForKey:@"arxivCategory"];
    tmpValue = [self.data arxivCategory];
//    [self didAccessValueForKey:@"arxivCategory"];
    
    return tmpValue;
}

- (void)setArxivCategory:(NSString *)value 
{
//    [self willChangeValueForKey:@"arxivCategory"];
    [self.data setArxivCategory:value];
//    [self didChangeValueForKey:@"arxivCategory"];
}

- (NSString *)collaboration
{
    NSString * tmpValue;
    
//    [self willAccessValueForKey:@"collaboration"];
    tmpValue = [self.data collaboration];
//    [self didAccessValueForKey:@"collaboration"];
    
    return tmpValue;
}

- (void)setCollaboration:(NSString *)value 
{
//    [self willChangeValueForKey:@"collaboration"];
    [self.data setCollaboration:value];
//    [self didChangeValueForKey:@"collaboration"];
}

- (NSString *)comments 
{
    NSString * tmpValue;
    
//    [self willAccessValueForKey:@"comments"];
    tmpValue = [self.data comments];
//    [self didAccessValueForKey:@"comments"];
    
    return tmpValue;
}

- (void)setComments:(NSString *)value 
{
//    [self willChangeValueForKey:@"comments"];
    [self.data setComments:value];
//    [self didChangeValueForKey:@"comments"];
}



- (NSString *)doi 
{
    NSString * tmpValue;
    
//    [self willAccessValueForKey:@"doi"];
    tmpValue = [self.data doi];
//    [self didAccessValueForKey:@"doi"];
    
    return tmpValue;
}

- (void)setDoi:(NSString *)value 
{
//    [self willChangeValueForKey:@"doi"];
    [self.data setDoi:value];
//    [self didChangeValueForKey:@"doi"];
}


- (NSString *)longishAuthorListForEA
{
    NSString * tmpValue;
    
//    [self willAccessValueForKey:@"longishAuthorListForEA"];
    tmpValue = [self.data longishAuthorListForEA];
//    [self didAccessValueForKey:@"longishAuthorListForEA"];
    
    return tmpValue;
}

- (void)setLongishAuthorListForEA:(NSString *)value 
{
//    [self willChangeValueForKey:@"longishAuthorListForEA"];
    [self.data setLongishAuthorListForEA:value];
//    [self didChangeValueForKey:@"longishAuthorListForEA"];
}



- (NSString *)memo 
{
    NSString * tmpValue;
    
//    [self willAccessValueForKey:@"memo"];
    tmpValue = [self.data memo];
//    [self didAccessValueForKey:@"memo"];
    
    return tmpValue;
}

- (void)setMemo:(NSString *)value 
{
//    [self willChangeValueForKey:@"memo"];
    [self.data setMemo:value];
//    [self didChangeValueForKey:@"memo"];
}


- (NSNumber *)pages 
{
    NSNumber * tmpValue;
    
//    [self willAccessValueForKey:@"pages"];
    tmpValue = [self.data pages];
//    [self didAccessValueForKey:@"pages"];
    
    return tmpValue;
}

- (void)setPages:(NSNumber *)value 
{
//    [self willChangeValueForKey:@"pages"];
    [self.data setPages:value];
//    [self didChangeValueForKey:@"pages"];
}


- (NSData *)pdfAlias 
{
    NSData * tmpValue;
    
//    [self willAccessValueForKey:@"pdfAlias"];
    tmpValue = [self.data pdfAlias];
//    [self didAccessValueForKey:@"pdfAlias"];
    
    return tmpValue;
}

- (void)setPdfAlias:(NSData *)value 
{
//    [self willChangeValueForKey:@"pdfAlias"];
    [self.data setPdfAlias:value];
//    [self didChangeValueForKey:@"pdfAlias"];
}


- (NSString *)shortishAuthorList 
{
    NSString * tmpValue;
    
//    [self willAccessValueForKey:@"shortishAuthorList"];
    tmpValue = [self.data shortishAuthorList];
//    [self didAccessValueForKey:@"shortishAuthorList"];
    
    return tmpValue;
}

- (void)setShortishAuthorList:(NSString *)value 
{
//    [self willChangeValueForKey:@"shortishAuthorList"];
    [self.data setShortishAuthorList:value];
//    [self didChangeValueForKey:@"shortishAuthorList"];
}

- (NSString *)spicite 
{
    NSString * tmpValue;
    
 //   [self willAccessValueForKey:@"spicite"];
    tmpValue = [self.data spicite];
//    [self didAccessValueForKey:@"spicite"];
    
    return tmpValue;
}

- (void)setSpicite:(NSString *)value 
{
//    [self willChangeValueForKey:@"spicite"];
    [self.data setSpicite:value];
//    [self didChangeValueForKey:@"spicite"];
}

- (NSNumber *)spiresKey
{
    NSNumber * tmpValue;
    
//    [self willAccessValueForKey:@"spiresKey"];
    tmpValue = [self.data spiresKey];
//    [self didAccessValueForKey:@"spiresKey"];
    
    return tmpValue;
}

- (void)setSpiresKey:(NSNumber *)value 
{
//    [self willChangeValueForKey:@"spiresKey"];
    [self.data setSpiresKey:value];
//    [self didChangeValueForKey:@"spiresKey"];
}

- (NSString *)texKey 
{
    NSString * tmpValue;
    
//    [self willAccessValueForKey:@"texKey"];
    tmpValue = [self.data texKey];
//    [self didAccessValueForKey:@"texKey"];
    
    return tmpValue;
}

- (void)setTexKey:(NSString *)value 
{
//    [self willChangeValueForKey:@"texKey"];
    [self.data setTexKey:value];
//    [self didChangeValueForKey:@"texKey"];
}


- (NSNumber *)version 
{
    NSNumber * tmpValue;
    
//    [self willAccessValueForKey:@"version"];
    tmpValue = [self.data version];
//    [self didAccessValueForKey:@"version"];
    
    return tmpValue;
}

- (void)setVersion:(NSNumber *)value 
{
//    [self willChangeValueForKey:@"version"];
    [self.data setVersion:value];
//    [self didChangeValueForKey:@"version"];
}*/



-(id)valueForUndefinedKey:(NSString *)key
{
    // this shouldn't be called if everything is working alright
    NSLog(@"undefined getter for %@",key);
    return [self.data valueForKey:key];
}
-(void)setValue:(id)obj forUndefinedKey:(NSString *)key
{
    // this shouldn't be called if everything is working alright
    NSLog(@"undefined setter for %@",key);
    [self.data setValue:obj forKey:key];
}
- (id)_getter_
{
//    return [self.data performSelector:_cmd];
    return objc_msgSend(self.data, _cmd);
}

- (void)_setter_:(id)value 
{
//    [self.data performSelector:_cmd withObject:value];
    objc_msgSend(self.data, _cmd,value);
}
+(void)synthesizeForwarder:(NSString*)getterName
{
    NSString*setterName=[NSString stringWithFormat:@"set%@%@:",[[getterName substringToIndex:1] uppercaseString],[getterName substringFromIndex:1]];
//    [forwardDict setObject:getterName forKey:setterName];
    Method getter=class_getInstanceMethod(self, @selector(_getter_));
    class_addMethod(self, NSSelectorFromString(getterName), method_getImplementation(getter), method_getTypeEncoding(getter));
    Method setter=class_getInstanceMethod(self, @selector(_setter_:));
    class_addMethod(self, NSSelectorFromString(setterName), method_getImplementation(setter), method_getTypeEncoding(setter));
}

@dynamic abstract;
@dynamic arxivCategory;
@dynamic collaboration;
@dynamic comments;
@dynamic date;
@dynamic doi;
@dynamic eprint;
@dynamic longishAuthorListForEA;
@dynamic memo;
@dynamic pages;
@dynamic shortishAuthorList;
@dynamic texKey;
@dynamic title;
@dynamic version;
@dynamic spicite;
@dynamic spiresKey;

+(void)load
{
//    forwardDict=[NSMutableDictionary dictionary];
    for(NSString*selectorName in [NSArray arrayWithObjects:
				  @"abstract",
				  @"arxivCategory",
				  @"collaboration",
				  @"comments",
				  @"date",
				  @"doi",
				  @"eprint",
				  @"longishAuthorListForEA",
				  @"memo",
				  @"pages",
				  @"shortishAuthorList",
				  @"texKey",
				  @"title",
				  @"version",
				  @"spicite",
				  @"spiresKey",
				  nil]){
	[self synthesizeForwarder:selectorName];
    }
}

@end
