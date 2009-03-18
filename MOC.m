//
//  MOC.m
//  spires
//
//  Created by Yuji on 09/02/28.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import "MOC.h"

MOC*_sharedMOCManager=nil;
@implementation MOC
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
+(NSManagedObjectContext*)createSecondaryMOC
{
    return [[MOC sharedMOCManager] createSecondaryMOC];
}
-(MOC*)init
{
    self=[super init];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didSaveNotificationReceived:) name:NSManagedObjectContextDidSaveNotification object:nil];
    
    return self;
}
/*-(void)didSaveNotificationReceived:(NSNotification*)n 
 // It is inherently evil to try conflict resolution automatically for any entities.
 // one needs to think what to do for each entity type!
{
    NSManagedObjectContext*moc=[n object];
    if(moc!=[self secondaryManagedObjectContext])
	return;
    NSDictionary*dict=[n userInfo];
    NSArray*inserted=[dict objectForKey:NSInsertedObjectsKey];
    NSArray*updated=[dict objectForKey:NSUpdatedObjectsKey];
//    NSLog(@"%d inserted:%@",(int)[inserted count],inserted);
//    NSLog(@"%d updated:%@",(int)[updated count], updated);
    for(NSManagedObject* o in inserted){
	[[self managedObjectContext] refreshObject:[[self managedObjectContext] objectWithID:[o objectID]] mergeChanges:YES];
    }
    for(NSManagedObject* o in updated){
	[[self managedObjectContext] refreshObject:[[self managedObjectContext] objectWithID:[o objectID]] mergeChanges:YES];
    }    
}*/
- (NSString *)applicationSupportFolder {
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : NSTemporaryDirectory();
    return [basePath stringByAppendingPathComponent:@"spires"];
}


/**
 Creates, retains, and returns the managed object model for the application 
 by merging all of the models found in the application bundle.
 */

- (NSManagedObjectModel *)managedObjectModel {
    
    if (managedObjectModel != nil) {
        return managedObjectModel;
    }
    
    managedObjectModel = [[NSManagedObjectModel mergedModelFromBundles:nil] retain];    
    
    return managedObjectModel;
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
    
    NSFileManager *fileManager;
    NSString *applicationSupportFolder = nil;
    NSError *error;
    
    fileManager = [NSFileManager defaultManager];
    applicationSupportFolder = [self applicationSupportFolder];
    if ( ![fileManager fileExistsAtPath:applicationSupportFolder isDirectory:NULL] ) {
        [fileManager createDirectoryAtPath:applicationSupportFolder attributes:nil];
    }
    
    NSString*filePath=[self dataFilePath];
    NSString*storeType=NSBinaryStoreType;
    if([filePath hasSuffix:@"xml"]){
	storeType=NSXMLStoreType;
    }else if([filePath hasSuffix:@"sqlite"]){
	storeType=NSSQLiteStoreType;
    }
    persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: [self managedObjectModel]];
    
    {
	NSDictionary *sourceMetadata =
	[NSPersistentStoreCoordinator metadataForPersistentStoreOfType:storeType
								   URL:[[NSURL alloc] initFileURLWithPath:filePath]
								 error:&error];
	
	if (sourceMetadata == nil) {
	    // deal with error
	    // but don't care here
	}else if(! [[self managedObjectModel] isConfiguration:nil
			    compatibleWithStoreMetadata:sourceMetadata]){
	    NSAlert*alert=[NSAlert alertWithMessageText:@"spires.app will update its database."
					  defaultButton:@"OK" 
					alternateButton:nil
					    otherButton:nil
			      informativeTextWithFormat:@"To improve the search performance, "
			   @"spires.app is going to precalculate various search keys and cache them. " 
			   @"This might take five minuites or more. "
			   @"Spinning rainbow cursor will appear, but please wait patiently until it finishes. "
			   @"Force quitting might corrupt the database."];
	    //    [alert setShowsSuppressionButton:YES];
	    [alert runModal];
	}
	
    }
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionary]; 
    [dict setObject:[NSNumber numberWithBool:YES] 
	     forKey:NSMigratePersistentStoresAutomaticallyOption]; 
    
    
    if (![persistentStoreCoordinator addPersistentStoreWithType:storeType
						  configuration:nil 
							    URL:[[NSURL alloc] initFileURLWithPath:filePath] 
							options:dict
							  error:&error]){
        [[NSApplication sharedApplication] presentError:error];
    }    
    
    return persistentStoreCoordinator;
}
-(NSString*)dataFilePath
{
    NSString* extension=[[NSUserDefaults standardUserDefaults] stringForKey:@"CoreDataStoreType"];
    //    NSLog(@"%@",extension);
    if(!extension){
	extension=@".sqlite";
    }
    return [[self applicationSupportFolder] stringByAppendingPathComponent: [NSString stringWithFormat:@"spiresDatabase%@",extension]];
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
- (NSManagedObjectContext *) managedObjectContext {
    
    if (managedObjectContext != nil) {
        return managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        managedObjectContext = [[NSManagedObjectContext alloc] init];
        [managedObjectContext setPersistentStoreCoordinator: coordinator];
//	[managedObjectContext setMergePolicy:NSMergeByPropertyStoreTrumpMergePolicy];
	[managedObjectContext setMergePolicy:NSErrorMergePolicy];
    }
    
    return managedObjectContext;
}

- (NSManagedObjectContext *) createSecondaryMOC {
    
/*    if (secondaryManagedObjectContext != nil) {
        return secondaryManagedObjectContext;
    }*/
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    NSManagedObjectContext*secondaryManagedObjectContext=nil;
    if (coordinator != nil) {
        secondaryManagedObjectContext = [[NSManagedObjectContext alloc] init];
        [secondaryManagedObjectContext setPersistentStoreCoordinator: coordinator];
	[secondaryManagedObjectContext setMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];
//	[secondaryManagedObjectContext setMergePolicy:NSErrorMergePolicy];
//	[secondaryManagedObjectContext setUndoManager:nil];
    }
    
    return secondaryManagedObjectContext;
}


/**
 Implementation of dealloc, to release the retained variables.
 */

- (void) dealloc {
    
    [managedObjectContext release], managedObjectContext = nil;
    [persistentStoreCoordinator release], persistentStoreCoordinator = nil;
    [managedObjectModel release], managedObjectModel = nil;
    [super dealloc];
}

@end
