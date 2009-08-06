// 
//  Author.m
//  spires
//
//  Created by Yuji on 08/10/14.
//  Copyright 2008 Y. Tachikawa. All rights reserved.
//

#import "Author.h"

#import "Article.h"

@implementation NSString (NameInitialAddition)
-(NSString*)abbreviatedFirstName
{
    if([self isEqualToString:@""])return nil;
    NSArray*b=[self componentsSeparatedByString:@" "];
    NSMutableArray*x=[NSMutableArray array];
    for(NSString*s in b){
	if(!s)continue;
	if([s isEqualToString:@""])continue;
	[x addObject:[[s substringToIndex:1] stringByAppendingString:@"."]];
    }
    return [x componentsJoinedByString:@" "];
}
@end

@implementation Author 

@dynamic name;
@dynamic articles;

NSMutableDictionary* authorDict=nil;
+(void)initialize
{
    if(!authorDict){
	authorDict=[NSMutableDictionary dictionary];
    }
}
+(Author*)authorWithName:(NSString*)name inMOC:(NSManagedObjectContext*)moc
{
//    Author* au= [authorDict objectForKey:name];
//    if(au)return au;
    Author*au=nil;
    NSEntityDescription*authorEntity=[NSEntityDescription entityForName:@"Author" inManagedObjectContext:moc];
    NSFetchRequest*req=[[NSFetchRequest alloc]init];
    [req setEntity:authorEntity];
    NSPredicate*pred=[NSPredicate predicateWithFormat:@"name == %@",name];
    [req setPredicate:pred];
    NSError*error=nil;
//    NSLog(@"%@",name);
    NSArray*a=[moc executeFetchRequest:req error:&error];
    if([a count]>0){
//	NSLog(@"name %@ found",name);
	au=[a objectAtIndex:0];
    }else{
//	NSLog(@"author entry %@ created",name);
	Author* mo=(Author*)[[NSManagedObject alloc] initWithEntity:authorEntity 
				     insertIntoManagedObjectContext:nil];
	[mo setValue:name forKey:@"name"];
	[moc insertObject:mo];	
	au= mo;
    }
    [authorDict setObject:au forKey:name];
    return au;
}


-(NSString*)firstName
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
}
@end
