// 
//  SimpleArticleList.m
//  spires
//
//  Created by Yuji on 08/10/15.
//  Copyright 2008 Y. Tachikawa. All rights reserved.
//

#import "SimpleArticleList.h"


@implementation SimpleArticleList 
+(SimpleArticleList*)simpleArticleListWithName:(NSString*)s inMOC:(NSManagedObjectContext*)moc
{
    NSEntityDescription*authorEntity=[NSEntityDescription entityForName:@"SimpleArticleList" inManagedObjectContext:moc];
    NSFetchRequest*req=[[NSFetchRequest alloc]init];
    [req setEntity:authorEntity];
    NSPredicate*pred=[NSPredicate predicateWithFormat:@"name = %@",s];
    [req setPredicate:pred];
    NSError*error=nil;
    NSArray*a=[moc executeFetchRequest:req error:&error];
    if([a count]>0){
	return [a objectAtIndex:0];
    }else{
	SimpleArticleList* mo=[[NSManagedObject alloc] initWithEntity:authorEntity 
					 insertIntoManagedObjectContext:moc];
	[mo setValue:s forKey:@"name"];
	return mo;
    }    
}
-(void)reload
{
}
-(NSImage*)icon
{
    return [NSImage imageNamed:@"spires-red.png"];
}
@end
