//
//  MOC.m
//  spires
//
//  Created by Yuji on 09/02/28.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import "MOC.h"
#import "Migrator.h"
#import "DumbOperation.h"

@implementation NSManagedObjectContext (TrivialAddition)
-(void)enableUndo
{
    [self processPendingChanges];
    [[self undoManager] enableUndoRegistration];    
}
-(void)disableUndo
{
    [self processPendingChanges];
    [[self undoManager] disableUndoRegistration];    
}

@end


MOC*_sharedMOCManager=nil;
@implementation MOC
@synthesize isUIready;
+(MOC*)sharedMOCManager
{
    if(!_sharedMOCManager){
	_sharedMOCManager=[[MOC alloc] init];
    }
    return _sharedMOCManager;
}
+(NSManagedObjectContext*)moc
{
    return [[MOC sharedMOCManager] managedObjectContext];
}
-(MOC*)init
{
    return [super init];
}
- (NSString *)applicationSupportFolder {
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? paths[0] : NSTemporaryDirectory();
    NSString* appSupportFolder= [basePath stringByAppendingPathComponent:@"spires"];
    
    NSFileManager *fileManager=[NSFileManager defaultManager];
    NSError *error=nil;
    if ( ![fileManager fileExistsAtPath:appSupportFolder isDirectory:NULL] ) {
        [fileManager createDirectoryAtPath:appSupportFolder 
	       withIntermediateDirectories:YES 
				attributes:nil 
				     error:&error];
    }
    return appSupportFolder;
    
}

/**
 Creates, retains, and returns the managed object model for the application 
 by merging all of the models found in the application bundle.
 */

- (NSManagedObjectModel *)managedObjectModel {
    
    if (managedObjectModel != nil) {
        return managedObjectModel;
    }
    
    managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:nil];    
    
    return managedObjectModel;
}



-(NSString*)dataFilePath
{
    NSString* extension=[[NSUserDefaults standardUserDefaults] stringForKey:@"CoreDataStoreType"];
    NSString* debug=@"";
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"debugMode"]){
	debug=@"_debug";
    }
    //    NSLog(@"%@",extension);
    if(!extension){
	extension=@".sqlite";
    }
    return [[self applicationSupportFolder] stringByAppendingPathComponent: [NSString stringWithFormat:@"spiresDatabase%@%@",debug,extension]];
}

-(NSString*)storeType
{
    NSString*filePath=[self dataFilePath];
    NSString*storeType=NSBinaryStoreType;
    if([filePath hasSuffix:@"xml"]){
	storeType=NSXMLStoreType;
    }else if([filePath hasSuffix:@"sqlite"]){
	storeType=NSSQLiteStoreType;
    }
    return storeType;
}
- (BOOL)migrationNeeded
{
    if(![[NSFileManager defaultManager] fileExistsAtPath:[self dataFilePath]]){
	return NO;
    }
    NSError*error=nil;
    NSDictionary *sourceMetadata =
    [NSPersistentStoreCoordinator metadataForPersistentStoreOfType:[self storeType]
							       URL:[NSURL fileURLWithPath:[self dataFilePath]]
							     error:&error];
    
    if (sourceMetadata == nil) {
	// deal with error
	// but don't care here
	return YES;
    }
    return ![[self managedObjectModel] isConfiguration:nil
			   compatibleWithStoreMetadata:sourceMetadata];
}


/**
 Returns the persistent store coordinator for the application.  This 
 implementation will create and return a coordinator, having added the 
 store for the application to it.  (The folder for the store is created, 
 if necessary.)
 */
- (NSPersistentStoreCoordinator *) persistentStoreCoordinator {
    
    if (persistentStoreCoordinator != nil) {
        return persistentStoreCoordinator;
    }
    
    
   persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: [self managedObjectModel]];
    
    if([self migrationNeeded]){
	Migrator*migrator=[[Migrator alloc] initWithDataPath:[self dataFilePath]];
	[migrator performMigration];
    }
    
    NSError*error=nil;
    if (![persistentStoreCoordinator addPersistentStoreWithType:[self storeType]
						  configuration:nil 
							    URL:[NSURL fileURLWithPath:[self dataFilePath]] 
							options:nil
							  error:&error]){
        [[NSApplication sharedApplication] presentError:error];
    }    
    
    return persistentStoreCoordinator;
}

/**
 Returns the managed object context for the application (which is already
 bound to the persistent store coordinator for the application.) 
 */
/*
 Merge policies:
 Main moc: error on conflict. I should arrange no conflict occurs in the save: operation from the main thread on the main moc.
 2ndary moc:  changes in moc forced into the disk. This alone will surely cause the conflict, so all of the saved objects are passed
           to the main thread as the managed object ID, and then conflict resolution is done immediately.
	   Now, the conflict resolution is easy for Articles because I should prefer them on the main moc,
           but once one starts mingling with the ArticleLists in the secondary moc various messy things happen.
           Currently registration into lists are done on the main thread, on the main moc only. Mar/2/2009
 */
/*
 Changed main moc merge policy to ObjectTrump. Mar/30/2009
 */
- (NSManagedObjectContext *) managedObjectContext {
    
    if (managedObjectContext != nil) {
        return managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        managedObjectContext = [[NSManagedObjectContext alloc] init];
        [managedObjectContext setPersistentStoreCoordinator: coordinator];
	[managedObjectContext setMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];
//	[managedObjectContext setMergePolicy:NSMergeByPropertyStoreTrumpMergePolicy];
	if([[NSUserDefaults standardUserDefaults] boolForKey:@"debugMOCsave"]){
	    NSLog(@"-[MOC save] debug mode...");
	    [managedObjectContext setMergePolicy:NSErrorMergePolicy];
	}
    }
    
    return managedObjectContext;
}

- (NSManagedObjectContext *) createSecondaryMOC {
    
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    NSManagedObjectContext*secondaryManagedObjectContext=nil;
    if (coordinator != nil) {
        secondaryManagedObjectContext = [[NSManagedObjectContext alloc] init];
        [secondaryManagedObjectContext setPersistentStoreCoordinator: coordinator];
	[secondaryManagedObjectContext setMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];
//	[secondaryManagedObjectContext setMergePolicy:NSErrorMergePolicy];
	[secondaryManagedObjectContext setUndoManager:nil];
    }
    
    return secondaryManagedObjectContext;
}

-(void)presentMOCSaveError:(NSError*)error
{
    // Note that this method is sometimes called from a secondary thread...
    NSLog(@"moc error:%@",error);
    NSDictionary* dict=[error userInfo];
    NSLog(@"userInfo:%@",dict);
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"debugMOCsave"]){
	NSArray* detailedErrors=dict[@"NSDetailedErrors"];
	if(detailedErrors){
	    for(NSError*e in detailedErrors){
		NSLog(@"moc suberror:%@",e);
		NSDictionary* d=[e userInfo];
		if(d){
		    NSLog(@"userInfo:%@",d);	 
		}
	    }
	}    
    }
}
#pragma mark Vacuum-cleaner
-(void)vacuum
{
    NSError*error=nil;
    if(![[self managedObjectContext] save:&error]){
	NSLog(@"save error:%@. Proceed...",error);
    }
    NSPersistentStoreCoordinator*psc=[self persistentStoreCoordinator];
    NSArray*stores=[psc persistentStores];
    error=nil;
    if(![psc removePersistentStore:stores[0] error:&error]){
	NSLog(@"couldn't remove:%@",error);
	return;
    }
    error=nil;
    NSMutableDictionary*options=[NSMutableDictionary dictionary];
    options[NSSQLiteManualVacuumOption] = @YES;
    options[NSSQLiteAnalyzeOption] = @YES;
    if (![psc addPersistentStoreWithType:[self storeType]
			   configuration:nil 
				     URL:[NSURL fileURLWithPath:[self dataFilePath]] 
				 options:options
				   error:&error]){
	NSLog(@"something really bad:%@",error);
    }
}


@end
