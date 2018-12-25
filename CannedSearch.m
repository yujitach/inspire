//
//  CannedSearch.m
//  spires
//
//  Created by Yuji on 4/12/09.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import "CannedSearch.h"
#import "AppDelegate.h"
#import "SpiresHelper.h"
#import "DumbOperation.h"
#import "SpiresQueryOperation.h"
#import "MOC.h"

@implementation CannedSearch
+(CannedSearch*)createCannedSearchWithName:(NSString*)s inMOC:(NSManagedObjectContext*)moc
{
    NSEntityDescription*entity=[NSEntityDescription entityForName:@"CannedSearch" inManagedObjectContext:moc];
    CannedSearch* mo=(CannedSearch*)[[NSManagedObject alloc] initWithEntity:entity 
			      insertIntoManagedObjectContext:moc];
    mo.name=s;
    return mo;
}
-(void)reloadLocalWithCap:(NSUInteger)cap
{
//    NSLog(@"locally reloading canned search %@", self.name);
    if(self.managedObjectContext != [MOC moc]){
        // the way I wrote the cacheing feature of CannedSearch is totally fload.
        // This is an ad-hoc way to stop updating unless it's from the UI moc.
        return;
    }
    if(![self searchString] || [[self searchString] isEqualToString:@""] || [[self searchString] length]<5){
	return;
    }
    NSPredicate*predicate=[[SpiresHelper sharedHelper] predicateFromSPIRESsearchString:[self searchString]];
    NSEntityDescription*articleEntity=[NSEntityDescription entityForName:@"Article" inManagedObjectContext:[self managedObjectContext]];
    NSFetchRequest*req=[[NSFetchRequest alloc]init];
    [req setEntity:articleEntity];
    [req setPredicate:predicate];
    if(cap!=0){
	[req setFetchLimit:cap];
    }
    NSError*error=nil;
    NSArray*a=[[self managedObjectContext] executeFetchRequest:req error:&error];
    NSSet*set=[NSSet setWithArray:a];
    modifying=YES;
    [[self managedObjectContext] disableUndo];
    self.articles=set;
    [[self managedObjectContext] enableUndo];
    modifying=NO;
}
/*-(void)reloadLocalFully
{
    NSLog(@"fully");
    [self reloadLocalWithCap:0];
}
-(void)reloadLocal
{
    if(localReloadTimer){
	[localReloadTimer invalidate];
    }
    localReloadTimer=[NSTimer scheduledTimerWithTimeInterval:.5 
							  target:self 
							selector:@selector(reloadLocalFully) 
							userInfo:nil
							 repeats:NO];
    [self reloadLocalWithCap:100];
}*/
-(void)reloadLocal
{
    [self reloadLocalWithCap:0];
}
-(void)reload
{
    NSOperation*op=[[SpiresQueryOperation alloc] initWithQuery:[self searchString]
							andMOC:[self managedObjectContext]];
    [op setCompletionBlock:^{
	[self performSelectorOnMainThread:@selector(reloadLocal) withObject:nil waitUntilDone:NO];
    }];
    [[OperationQueues spiresQueue] addOperation:op];
}
-(void)prepareForDeletion
{
    modifying=YES;
    /* without this, "articles" will resurrect during the deletion
     because deletion itself invokes -articles, which fires -reloadLocal.
     This totally confuses CoreData and the next save will fail, 
     even when the delete rule is correctly specified! Ugh.
     Well, this assumes that prepareForDeletion is called 
     right after -[NSManagedObjectContext deleteObject:] is called,
     before -articles is called to perform Delete Propagation.
     I think it's guaranteed, see the "Discussion" in the documentation,
     which says "
     You can implement this method to perform any operations required 
     before the object is deleted, such as custom propagation 
     before relationships are torn down, 
     or reconfiguration of objects using key-value observing."
    */ 
}
-(NSSet*)articles
{
    if(!modifying){
	[self reloadLocal];
    }
    return [self primitiveValueForKey:@"articles"];
}
-(void)setSearchString:(NSString*)s
{
    if(!modifying){
	[self reloadLocal];
    }
    [self setPrimitiveValue:s forKey:@"searchString"];
}
#if TARGET_OS_IPHONE
-(UIImage*)icon
{
    return [UIImage imageNamed:@"canned-search"];
}
-(UIBarButtonItem*)barButtonItem
{
    UIBarButtonItem* bbi=[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(reload)];
    return bbi;
}
#else
-(NSImage*)icon
{
    NSImage*image=[NSImage imageNamed:@"canned-search"];
    image.template=YES;
    return image;
}
#endif
-(NSString*)placeholderForSearchField
{
    return @"Enter SPIRES query and hit return";
}
-(BOOL)searchStringEnabled
{
    return NO;
}
-(BOOL)hasButton
{
    return YES;
}
@end
