//
//  ArticleV1V2MigrationPolicy.m
//  spires
//
//  Created by Yuji on 09/02/26.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import "ArticleV1V2MigrationPolicy.h"
#import "NSString+magic.h"
#import "Author.h"

@implementation ArticleV1V2MigrationPolicy
/*-(NSString*)firstName
{
    NSArray*a=[self.name componentsSeparatedByString:@", "];
    if([a count]==1)
	return nil;
    return [a objectAtIndex:1];
}
-(NSString*)lastName
{
    NSArray*a=[self.name componentsSeparatedByString:@", "];
    return [a objectAtIndex:0];
}*/

-(NSString*)calculateShortishAuthorList:(NSSet*)authors
{
    NSMutableArray*a=[NSMutableArray array];
    for(Author*i in authors){
	NSArray*x=[i.name componentsSeparatedByString:@", "];
	[a addObject:[x objectAtIndex:0]];
    }
    [a sortUsingSelector:@selector(caseInsensitiveCompare:)];
    
    return [a componentsJoinedByString:@", "];
}
-(NSString*)calculateLongishAuthorListForEA:(NSSet*)authors
{
    NSMutableArray*a=[NSMutableArray array];
    for(Author*i in authors){
	[a addObject:i.name];
    }
    [a sortUsingSelector:@selector(caseInsensitiveCompare:)];
    
    return [[a componentsJoinedByString:@"; "] normalizedString];
}
-(NSString*)calculateLongishAuthorListForA:(NSSet*)authors
{
    NSMutableArray*a=[NSMutableArray array];
    for(Author*i in authors){
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
    return [result normalizedString];
    
}

-(NSString*)calculateEprintForSortingWithEprint:(NSString*)eprint andDate:(NSDate*)date;
{
    if(!eprint){
	if(date){
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

- (BOOL)createDestinationInstancesForSourceInstance:(NSManagedObject *)sInstance entityMapping:(NSEntityMapping *)mapping manager:(NSMigrationManager *)manager error:(NSError **)error
{
    
    NSArray *attributeMappings = [mapping attributeMappings];
    NSSet*authors=[sInstance valueForKey:@"authors"];
    NSString*eprint=[sInstance valueForKey:@"eprint"];
    NSDate*date=[sInstance valueForKey:@"date"];
    int32_t eprintForSorting=[[self calculateEprintForSortingWithEprint:eprint andDate:date] intValue];

    NSString*title=[sInstance valueForKey:@"title"];

      
    NSString*normalizedTitle=[title normalizedString];
    
    for(NSPropertyMapping *currentMapping in attributeMappings) 
    {
	NSString*name=[currentMapping name];
	if( [name isEqualToString:@"texKey"] ){
	    NSDictionary* dict=[NSPropertyListSerialization propertyListFromData:[sInstance valueForKey:@"extraURLs"]
								       mutabilityOption:NSPropertyListImmutable
										 format: NULL
								       errorDescription:nil];
	    NSString*texKey= [dict valueForKey:@"texKey"];
	    [currentMapping setValueExpression:[NSExpression expressionForConstantValue:texKey]];	    
	}else 	if( [name isEqualToString:@"longishAuthorListForA"] ){
	    [currentMapping setValueExpression:[NSExpression expressionForConstantValue:[self calculateLongishAuthorListForA:authors]]];	    
	}else 	if( [name isEqualToString:@"longishAuthorListForEA"] ){
	    [currentMapping setValueExpression:[NSExpression expressionForConstantValue:[self calculateLongishAuthorListForEA:authors]]];	    
	}else 	if( [name isEqualToString:@"shortishAuthorList"] ){
	    [currentMapping setValueExpression:[NSExpression expressionForConstantValue:[self calculateShortishAuthorList:authors]]];	    
	}else 	if( [name isEqualToString:@"eprintForSorting"] ){
	    [currentMapping setValueExpression:[NSExpression expressionForConstantValue:[NSNumber numberWithInt:eprintForSorting]]];	    
	}else 	if( [name isEqualToString:@"normalizedTitle"] ){
	    [currentMapping setValueExpression:[NSExpression expressionForConstantValue:normalizedTitle]];	    
	}
	
    }
    return [super createDestinationInstancesForSourceInstance:sInstance entityMapping:mapping manager:manager error:error];

}
@end
