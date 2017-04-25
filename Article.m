// 
//  Article.m
//  spires
//
//  Created by Yuji on 08/10/13.
//  Copyright 2008 Y. Tachikawa. All rights reserved.
//

#import "Article.h"
#import "Author.h"
#import "NSString+magic.h"
#import "MOC.h"
#import "ArticleData.h"
#import <objc/runtime.h>
#import <objc/message.h>

#if TARGET_OS_IPHONE
@import UIKit;
#define NSImage UIImage
#else
@import Cocoa;
#endif

@interface Article (private)
+(NSString*)longishAuthorListForAFromAuthorNames:(NSArray*)array;
+(NSString*)longishAuthorListForEAFromAuthorNames:(NSArray*)array;
+(NSString*)shortishAuthorListFromAuthorNames:(NSArray*)array;
+(NSString*)flagInternalFromFlag:(ArticleFlag)flag;
+(ArticleFlag)flagFromFlagInternal:(NSString*)flagInternal;
@end

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
//@dynamic eprintForSortingAsString;



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
	x=a[1];
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
    [req setRelationshipKeyPathsForPrefetching:@[@"article"]];
    [req setReturnsObjectsAsFaults:NO];
    
    [req setFetchLimit:1];
    __block NSArray*a=nil;
    [moc performBlockAndWait:^{
        NSError*error=nil;
        a=[moc executeFetchRequest:req error:&error];
    }];
    if(a==nil || [a count]==0){
	return nil;
    }else{
	ArticleData*ad=a[0];
	return ad.article;
    }
}
+(Article*)intelligentlyFindArticleWithId:(NSString*)idToLookUp inMOC:(NSManagedObjectContext*)moc
{
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
    if([idToLookUp rangeOfString:@":"].location!=NSNotFound){
	return [Article articleWith:idToLookUp
		       inDataForKey:@"texKey"
			      inMOC:moc];
    }
    idToLookUp=[idToLookUp lowercaseString];
    if([idToLookUp hasPrefix:@"key"]){
        idToLookUp=[idToLookUp stringByMatching:@"key +(\\d+)" capture:1];
    }
    return [Article articleWith:idToLookUp
		   inDataForKey:@"spiresKey"
			  inMOC:moc];
}

+(Article*)articleForQuery:(NSString*)query inMOC:(NSManagedObjectContext*)moc
{
    NSString*s=nil;
    if([query hasPrefix:@"c "]){
        NSString*ccc=[query componentsSeparatedByString:@"and"][0];
        NSArray*a=[ccc componentsSeparatedByString:@" "];
        if([a count]==2){
            s=a[1];
            if([s isEqualToString:@""])return nil;
        }else if([a count]==3){
            // c key nnnnnnn
            s=[@"key " stringByAppendingString:a[2]];
        }
    }
    if([query hasPrefix:@"r"]){
        NSString*ccc=[query componentsSeparatedByString:@"and"][0];
        NSArray*a=[ccc componentsSeparatedByString:@" "];
        if([a count]==2){
            s=a[1];
            if([s isEqualToString:@""])return nil;
        }else if([a count]==3){
            // r key nnnnnnn
            s=[@"key " stringByAppendingString:a[2]];
        }
    }
    if(!s)
        return nil;
    return [Article intelligentlyFindArticleWithId:s inMOC:moc];
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
	NSString* last=c[0];
	[result appendString:last];
	[result appendString:@", "];
	NSArray* d=[c[1] componentsSeparatedByString:@" "];
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
	NSString*lastName=q[0];
	if([lastName rangeOfString:@"collaboration"].location!=NSNotFound){
	    lastName=[lastName stringByReplacingOccurrencesOfRegex:@" *collaborations? *" withString:@""];
	    lastName=[lastName uppercaseString];
	    collaboration=lastName;
	    continue;
	}else if([lastName isEqualToString:@"group"] || [lastName isEqualToString:@"groups"] || [lastName isEqualToString:@"physics"] ){
	    if([q count]>1){
		lastName=q[1];
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
//	if([a count]>0){
//	    return [NSString stringWithFormat:@"%@ (%@)",collaboration,[a componentsJoinedByString:@", "]];
//	}else{
        return [collaboration stringByAppendingString:@" collaboration"];
//	}
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
    NSData*base=self.data.extraURLs;
    NSMutableDictionary* dict=nil;
    if(base){
        dict=[NSPropertyListSerialization propertyListWithData:self.data.extraURLs
                                                       options:NSPropertyListMutableContainers
                                                        format: NULL
                                                         error:NULL];
    }
    if(!dict){
	dict=[NSMutableDictionary dictionary];
    }
    [dict setValue:content forKey:key];
    self.data.extraURLs=[NSPropertyListSerialization dataWithPropertyList:dict
                                                                   format:NSPropertyListBinaryFormat_v1_0
                                                                  options:0
                                                                    error:NULL];
}

-(id)extraForKey:(NSString*)key
{
    if(!self.data.extraURLs){
        return nil;
    }
    NSMutableDictionary* dict=[NSPropertyListSerialization propertyListWithData:self.data.extraURLs
                                                                        options:NSPropertyListMutableContainers
                                                                         format: NULL
                                                                          error:NULL];
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
    }else{
        for(NSString*s in authorNames){
            NSString*t=[s normalizedString];
            if(![t isEqualToString:@""]){
                if([t rangeOfString:@"collaboration"].location!=NSNotFound){
                    if(self.collaboration){
                        continue;
                    }else{
                        if([t rangeOfString:@", "].location!=NSNotFound){
                            NSArray*x=[t componentsSeparatedByString:@", "];
                            t=[NSString stringWithFormat:@"%@ %@",x[1],x[0]];
                        }
                        self.collaboration=t;
                        [a addObject:[self tweakCollaborationName:self.collaboration]];
                    }
                }else{
                    [a addObject:t];
                }
            }
        }
    }
    self.shortishAuthorList=[Article shortishAuthorListFromAuthorNames:a];
    self.longishAuthorListForA=[Article longishAuthorListForAFromAuthorNames:a];
    self.longishAuthorListForEA=[Article longishAuthorListForEAFromAuthorNames:a];	
}
+(NSDateFormatter*)dateFormatter
{
    static dispatch_once_t once;
    static NSDateFormatter*df;
    dispatch_once(&once, ^{
        df=[[NSDateFormatter alloc]init];
        df.timeZone=[NSTimeZone timeZoneForSecondsFromGMT:0];
        df.locale=[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
        df.dateFormat=@"yyyyMM0000";
    });
    return df;
}
-(NSString*)calculateEprintForSorting
{
    NSString*eprint=self.eprint;
    if(!eprint){
	if(self.date){
	    NSDate*date=self.date;
            NSString*s=[[Article dateFormatter] stringFromDate:date];
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
    self.eprintForSorting=@([[self calculateEprintForSorting] longLongValue]);
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
    self.eprintForSorting=@([[self calculateEprintForSorting] longLongValue]);
}
-(NSString*)quieterTitle //calculateQuieterTitle
{
    if([self eprint]){
	return [self title];
    }
    if(![self title]){
	return @"";
    }
    return [self.title quieterVersion];
}
-(NSAttributedString*)attributedTitle
{
    if([self.title containsString:@"$"] || [self.title containsString:@"\\"]){
        return [self.title mockTeXed];
    }else{
        return [[NSAttributedString alloc] initWithString:self.quieterTitle];
    }
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
/*+(NSSet*)keyPathsForValuesAffectingPdfPath
{
    return [NSSet setWithObjects:@"data.pdfAlias",nil];
}
 */
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
        return;
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
//    }else if(self.spicite && ![self.spicite isEqualToString:@""]){
//	return self.spicite;
//    }else if(self.spiresKey && [self.spiresKey integerValue]!=0){
//	return [self.spiresKey stringValue];
    }else if(self.inspireKey &&[self.inspireKey integerValue]!=0){
        return [self.inspireKey stringValue];
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
//    }else if(self.spicite && ![self.spicite isEqualToString:@""]){
//	return [@"spicite " stringByAppendingString:self.spicite];
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
	return [NSImage imageNamed:@"flagged"];
    }else if(af&AFIsUnread){
        if(af&AFHasPDF){
            return [NSImage imageNamed:@"unread-hasPDF"];
        }else{
            return [NSImage imageNamed:@"unread"];
        }
    }else if(af&AFHasPDF){
	return [NSImage imageNamed:@"hasPDF"];
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

typedef id (*GETTERTYPE)(id,SEL);
typedef void (*SETTERTYPE)(id,SEL,id);
- (id)_getter_
{
//    return [self.data performSelector:_cmd];
    return ((GETTERTYPE)objc_msgSend)(self.data, _cmd);
}

- (void)_setter_:(id)value 
{
//    [self.data performSelector:_cmd withObject:value];
    ((SETTERTYPE)objc_msgSend)(self.data, _cmd,value);
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
//@dynamic spicite;
@dynamic spiresKey;
@dynamic inspireKey;

+(void)load  // don't change it to +initialize! it's too late, somehow.
{
    for(NSString*selectorName in @[@"abstract",
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
//				  @"spicite",
				  @"spiresKey",
				  @"inspireKey"]){
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
