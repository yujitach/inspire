// 
//  Article.m
//  spires
//
//  Created by Yuji on 08/10/13.
//  Copyright 2008 Y. Tachikawa. All rights reserved.
//

#import "Article.h"
#import "ArticlePrivate.h"
#import "Author.h"
#import "AllArticleList.h"
#import "NSString+magic.h"
#import "MOC.h"
#import "ArticleData.h"
#import <objc/runtime.h>
#import <objc/message.h>


@implementation Article 

@dynamic journal;
@dynamic flagInternal;
@dynamic citedBy;
@dynamic refersTo;
@dynamic citecount;
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
    if(![x hasPrefix:@"9"]){
	return [@"20" stringByAppendingString:x];
    }
    return [@"19" stringByAppendingString:x];
    
}
-(NSString*)eprintForSortingAsString
{
    return [self.eprintForSorting stringValue];
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
//    NSLog(@"finding article with id %@",idToLookUp);
    NSString*eprint=nil;
    if([[idToLookUp lowercaseString] hasPrefix:@"arxiv:"]){
	eprint=[[idToLookUp lowercaseString] stringByReplacingOccurrencesOfString:@"arxiv" withString:@"arXiv"];
    }else if([idToLookUp rangeOfString:@"."].location!=NSNotFound){
	eprint=[@"arXiv:" stringByAppendingString:idToLookUp];
    }else if([idToLookUp rangeOfString:@"/"].location!=NSNotFound){
	eprint=idToLookUp;
    }
    if(eprint){
	return [Article articleWith:eprint
		       inDataForKey:@"eprint"
			      inMOC:moc];	
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
    if([[idToLookUp lowercaseString] hasPrefix:@"key"]){
	NSArray* arr=[idToLookUp componentsSeparatedByString:@" "];
	if([arr count]>1){
	    idToLookUp=[arr lastObject];
	}
    }
    return [Article articleWith:idToLookUp
		   inDataForKey:@"spiresKey"
			  inMOC:[MOC moc]];
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
	if([s rangeOfString:@"collaboration"].location!=NSNotFound){
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
	}else if([lastName isEqualTo:@"group"] || [lastName isEqualTo:@"groups"] || [lastName isEqualTo:@"physics"] ){
	    if([q count]>1){
		lastName=[q objectAtIndex:1];
		lastName=[lastName stringByReplacingOccurrencesOfRegex:@" *the *" withString:@""];
		lastName=[lastName capitalizedString];
	    }
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
-(NSString*)tweakCollaborationName:(NSString*)c
{
    NSMutableString*s=[[c normalizedString] mutableCopy];
    [s replaceOccurrencesOfRegex:@" *on +behalf +of +the *" withString:@""];
    [s replaceOccurrencesOfRegex:@" *for +the *" withString:@""];
    [s replaceOccurrencesOfRegex:@"^ *the *" withString:@""];
    if([s rangeOfString:@"collaboration"].location==NSNotFound){
	[s appendString:@" collaboration"];
    }
    return s;
}
-(void)setAuthorNames:(NSArray *)authorNames
{
    NSMutableArray*a=[NSMutableArray array];
    if(self.collaboration){
	[a addObject:[self tweakCollaborationName:self.collaboration]];
    }
    for(NSString*s in authorNames){
	NSString*t=[s normalizedString];
	if(![t isEqualToString:@""]){
	    if([t rangeOfString:@"collaboration"].location!=NSNotFound){
		if(self.collaboration){
		    continue;
		}else{
		    if([t rangeOfString:@", "].location!=NSNotFound){
			NSArray*x=[t componentsSeparatedByString:@", "];
			t=[NSString stringWithFormat:@"%@ %@",[x objectAtIndex:1],[x objectAtIndex:0]];
		    }
		    self.collaboration=t;
		    [a addObject:[self tweakCollaborationName:self.collaboration]];		    
		}
	    }else{
		[a addObject:t];
	    }
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

-(void)setEprint:(NSString*)e
{
    [self.data setEprint:e];
    self.eprintForSorting=[NSNumber numberWithInt:[[self calculateEprintForSorting] intValue]];
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

-(void)setDate:(NSDate*)d
{
    [self.data setDate:d];
    self.eprintForSorting=[NSNumber numberWithInt:[[self calculateEprintForSorting] intValue]];
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
    [self.data setTitle:t];
    self.normalizedTitle=[self calculateNormalizedTitle];
}
#pragma mark Misc.
+(NSSet*)keyPathsForValuesAffectingPdfPath
{
    return [NSSet setWithObjects:@"data.pdfAlias",nil];
}
-(BOOL)trashContainsFileWithName:(NSString*)path
{
    return [[path stringByAbbreviatingWithTildeInPath] hasPrefix:@"~/.Trash"];
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
	    if(isStale && ![self trashContainsFileWithName:path]){
		[self associatePDF:path];
	    }
	    return path;
	}else{
	    [self associatePDF:nil];
	}
    }else if([self isEprint]){
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
-(BOOL)isEprint
{
    return self.eprint && ![self.eprint isEqualToString:@""];
}
-(BOOL)hasPDFLocally
{
    BOOL b= [[NSFileManager defaultManager] fileExistsAtPath:self.pdfPath];
    if(b && ![self trashContainsFileWithName:self.pdfPath]){
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
    if([self isEprint]){
	NSString*s=self.eprint;
	if([s hasPrefix:@"arXiv:"]){
	    return [s substringFromIndex:[(NSString*)@"arXiv:" length]];
	}else{
	    return s;
	}
    }else if(self.spicite && ![self.spicite isEqualToString:@""]){
	return self.spicite;
    }else if(self.spiresKey && [self.spiresKey integerValue]!=0){
	return [self.spiresKey stringValue];
    }else{
	return @"shouldn't happen";
    }
}
-(NSString*)uniqueSpiresQueryString
{
    if([self isEprint]){
	return [@"eprint " stringByAppendingString:self.eprint];
    }else if(self.texKey && ![self.texKey isEqualToString:@""]){
        return [@"texkey " stringByAppendingString:self.texKey];        
    }else if(self.spicite && ![self.spicite isEqualToString:@""]){
	return [@"spicite " stringByAppendingString:self.spicite];	
    }else if(self.spiresKey && [self.spiresKey integerValue]!=0){
	return [@"key " stringByAppendingString:[self.spiresKey stringValue]];	
    }else if(self.doi && ![self.doi isEqualToString:@""]){
        return [@"doi " stringByAppendingString:self.doi];        
    }
    return nil;
}
-(NSString*)uniqueInspireQueryString
{
    if(self.inspireKey &&[self.inspireKey integerValue]!=0){
        return [NSString stringWithFormat:@"recid:%@",self.inspireKey];
    }
    if([self isEprint]){
	return [@"eprint:" stringByAppendingString:self.eprint];
    }
    if(self.doi && ![self.doi isEqualToString:@""]){
	return [@"doi:" stringByAppendingString:self.doi];        
    }
    return [NSString stringWithFormat:@"title:\"%@\"",self.title];   
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
 Here comes the Objective-C runtime voodoo.
 
 Other parts of the program, written before the split of the entity Article 
 into Article and ArticleData, assume that every property is defined on Article.
 The split between Article and ArticleData is an implementation detail,
 so I don't want to rewrite the other parts of the program (unless it's crucial
 for the speed, like the design of the NSPredicates for the query).
 
 Then, it's necessary to forward self.pages to self.data.pages etc.
 It is tedious and error-prone to write them manually, so they are synthesized
 at the launch time. Many thanks to Mike Ash who personally taught me the error
 in my original approach. 
 
 Some of the setters are already defined above. They are not "overriden",
 because class_addMethod fails if there's already a method defined with the same name.
 
 */

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
@dynamic inspireKey;

+(void)load  // don't change it to +initialize! it's too late, somehow.
{
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
				  @"inspireKey",
				  nil]){
	[self synthesizeForwarder:selectorName];
    }
}


/*-(id)valueForUndefinedKey:(NSString *)key
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
 }*/
@end
