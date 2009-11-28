//
//  MOC.m
//  spires
//
//  Created by Yuji on 09/02/28.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import "MOC.h"
#import "MigrationProgressController.h"

MOC*_sharedMOCManager=nil;
@interface MOC(Private)
-(void)performMigration;
@end
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
/*    [[NSFileManager defaultManager] createDirectoryAtPath:[self directoryForIndividualEntries] 
					       attributes:nil];
*/
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
- (NSPersistentStoreCoordinator *) persistentStoreCoordinatorWithAutoMigration:(BOOL)autoMigration {
    
    if (persistentStoreCoordinator != nil) {
        return persistentStoreCoordinator;
    }
    
    NSFileManager *fileManager;
    NSString *applicationSupportFolder = nil;
    NSError *error=nil;
    
    fileManager = [NSFileManager defaultManager];
    applicationSupportFolder = [self applicationSupportFolder];
    if ( ![fileManager fileExistsAtPath:applicationSupportFolder isDirectory:NULL] ) {
        [fileManager createDirectoryAtPath:applicationSupportFolder 
	       withIntermediateDirectories:YES 
				attributes:nil 
				     error:NULL];
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
	    if(!autoMigration){
		persistentStoreCoordinator=nil;
		return nil;
	    }
	    [self performMigration];
	}
	
    }
    
/*    NSMutableDictionary *dict = [NSMutableDictionary dictionary]; 
    [dict setObject:[NSNumber numberWithBool:YES] 
	     forKey:NSMigratePersistentStoresAutomaticallyOption]; */
    
    
    if (![persistentStoreCoordinator addPersistentStoreWithType:storeType
						  configuration:nil 
							    URL:[NSURL fileURLWithPath:filePath] 
							options:nil
							  error:&error]){
        [[NSApplication sharedApplication] presentError:error];
    }    
    
    return persistentStoreCoordinator;
}
- (NSString *)directoryForIndividualEntries
{
    NSString* debug=@"";
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"debugMode"]){
	debug=@"_debug";
    }
    return [[self applicationSupportFolder] stringByAppendingPathComponent:[@"entries" stringByAppendingString:debug]];
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
- (NSManagedObjectContext *) managedObjectContextWithoutMigration {
    
    if (managedObjectContext != nil) {
        return managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinatorWithAutoMigration:NO];
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
- (NSManagedObjectContext *) managedObjectContext {
    
    if (managedObjectContext != nil) {
        return managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinatorWithAutoMigration:YES];
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
    
/*    if (secondaryManagedObjectContext != nil) {
        return secondaryManagedObjectContext;
    }*/
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinatorWithAutoMigration:NO];
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
    NSArray* detailedErrors=[dict objectForKey:@"NSDetailedErrors"];
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

/**
 Implementation of dealloc, to release the retained variables.
 */

- (void) dealloc {
    
    [managedObjectContext release], managedObjectContext = nil;
    [persistentStoreCoordinator release], persistentStoreCoordinator = nil;
    [managedObjectModel release], managedObjectModel = nil;
    [super dealloc];
}

#pragma mark migration

// manual migration code. Taken from Marcus Zarra's CoreData book;
// progress bar code added by Yuji
//START:progressivelyMigrateURLMethodName
- (BOOL)progressivelyMigrateURL:(NSURL*)sourceStoreURL
                         ofType:(NSString*)type 
                        toModel:(NSManagedObjectModel*)finalModel 
                          error:(NSError**)error
{
    NSAssert(error!=nil,@"error should be taken care of!");
    //END:progressivelyMigrateURLMethodName
    //START:progressivelyMigrateURLHappyCheck
    NSDictionary *sourceMetadata = 
    [NSPersistentStoreCoordinator metadataForPersistentStoreOfType:type
							       URL:sourceStoreURL
							     error:error];
    if (!sourceMetadata) return NO;
    
    if ([finalModel isConfiguration:nil 
	compatibleWithStoreMetadata:sourceMetadata]) {
	*error = nil;
	return YES;
    }
    //END:progressivelyMigrateURLHappyCheck
    //START:progressivelyMigrateURLFindModels
    //Find the source model
    NSManagedObjectModel *sourceModel = [NSManagedObjectModel 
					 mergedModelFromBundles:nil
					 forStoreMetadata:sourceMetadata];
    NSAssert(sourceModel != nil, ([NSString stringWithFormat:
				   @"Failed to find source model\n%@", 
				   sourceMetadata]));
    
    //Find all of the mom and momd files in the Resources directory
    NSMutableArray *modelPaths = [NSMutableArray array];
    NSArray *momdArray = [[NSBundle mainBundle] pathsForResourcesOfType:@"momd" 
							    inDirectory:nil];
    for (NSString *momdPath in momdArray) {
	NSString *resourceSubpath = [momdPath lastPathComponent];
	NSArray *array = [[NSBundle mainBundle] 
			  pathsForResourcesOfType:@"mom" 
			  inDirectory:resourceSubpath];
	[modelPaths addObjectsFromArray:array];
    }
    NSArray* otherModels = [[NSBundle mainBundle] pathsForResourcesOfType:@"mom" 
							      inDirectory:nil];
    [modelPaths addObjectsFromArray:otherModels];
    
    if (!modelPaths || ![modelPaths count]) {
	//Throw an error if there are no models
	NSMutableDictionary *dict = [NSMutableDictionary dictionary];
	[dict setValue:@"No models found in bundle" 
		forKey:NSLocalizedDescriptionKey];
	//Populate the error
	*error = [NSError errorWithDomain:@"Zarra" code:8001 userInfo:dict];
	return NO;
    }
    //END:progressivelyMigrateURLFindModels
    
    //See if we can find a matching destination model
    //START:progressivelyMigrateURLFindMap
    NSMappingModel *mappingModel = nil;
    NSManagedObjectModel *targetModel = nil;
    NSString *modelPath = nil;
    for (modelPath in modelPaths) {
	targetModel = [[NSManagedObjectModel alloc] 
		       initWithContentsOfURL:[NSURL fileURLWithPath:modelPath]];
	mappingModel = [NSMappingModel mappingModelFromBundles:nil 
						forSourceModel:sourceModel 
					      destinationModel:targetModel];
	//If we found a mapping model then proceed
	if (mappingModel) break;
	//Release the target model and keep looking
	[targetModel release], targetModel = nil;
    }
    //We have tested every model, if nil here we failed
    if (!mappingModel) {
	NSMutableDictionary *dict = [NSMutableDictionary dictionary];
	[dict setValue:@"No models found in bundle" 
		forKey:NSLocalizedDescriptionKey];
	*error = [NSError errorWithDomain:@"Zarra" 
				     code:8001 
				 userInfo:dict];
	return NO;
    }
    //END:progressivelyMigrateURLFindMap
    //We have a mapping model and a destination model.  Time to migrate
    //START:progressivelyMigrateURLMigrate
    NSMigrationManager *manager = [[NSMigrationManager alloc] 
				   initWithSourceModel:sourceModel
				   destinationModel:targetModel];
    MigrationProgressController*controller=[[MigrationProgressController alloc] initWithMigrationManager:manager
											     WithMessage:@"please wait patiently..."];
    NSString *modelName = [[modelPath lastPathComponent] 
			   stringByDeletingPathExtension];
    NSString *storeExtension = [[sourceStoreURL path] pathExtension];
    NSString *storePath = [[sourceStoreURL path] stringByDeletingPathExtension];
    //Build a path to write the new store
    storePath = [NSString stringWithFormat:@"%@.%@.%@", storePath, 
		 modelName, storeExtension];
    NSURL *destinationStoreURL = [NSURL fileURLWithPath:storePath];
    
    __block NSError*err=NULL;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),^{
	[manager migrateStoreFromURL:sourceStoreURL 
				type:type 
			     options:nil 
		    withMappingModel:mappingModel 
		    toDestinationURL:destinationStoreURL 
		     destinationType:type 
		  destinationOptions:nil 
			       error:&err];
	dispatch_async(dispatch_get_main_queue(),^{
	    [[NSApplication sharedApplication] stopModal];
	});
    });
    [[NSApplication sharedApplication] runModalForWindow:[controller window]];
    [controller close];
    if(error){
	*error=err;
    }
    if(err){
	return nil;
    }
    //END:progressivelyMigrateURLMigrate
    //Migration was successful, move the files around to preserve the source
    //START:progressivelyMigrateURLMoveAndRecurse
    NSString *appSupportPath = [storePath stringByDeletingLastPathComponent];
    NSString*name=[[sourceStoreURL lastPathComponent] stringByDeletingPathExtension];
    name=[name stringByAppendingFormat:@"~.%@",storeExtension];
    NSString *backupPath = [appSupportPath stringByAppendingPathComponent:name];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if([fileManager fileExistsAtPath:backupPath]){
	FSPathMoveObjectToTrashSync([backupPath fileSystemRepresentation], NULL,  kFSFileOperationDefaultOptions);
    }
    if (![fileManager moveItemAtPath:[sourceStoreURL path]
			      toPath:backupPath
			       error:error]) {
	//Failed to copy the file
	return NO;
    }
    //Move the destination to the source path
    if (![fileManager moveItemAtPath:storePath
			      toPath:[sourceStoreURL path]
			       error:error]) {
	//Try to back out the source move first, no point in checking it for errors
	[fileManager moveItemAtPath:backupPath
			     toPath:[sourceStoreURL path]
			      error:nil];
	return NO;
    }
    //We may not be at the "current" model yet, so recurse
    return [self progressivelyMigrateURL:sourceStoreURL
				  ofType:type 
				 toModel:finalModel 
				   error:error];
    //END:progressivelyMigrateURLMoveAndRecurse
}


-(void)performMigration
{
    NSAlert*alert=[NSAlert alertWithMessageText:@"spires.app will update its database."
				  defaultButton:@"OK" 
				alternateButton:nil
				    otherButton:nil
		      informativeTextWithFormat:@"To improve the search performance, "
		   @"spires.app is going to precalculate various search keys and cache them. " 
		   @"This might take five minuites or more. "
		   @"Spinning rainbow cursor will appear, but please wait patiently until it finishes. "
		   @"Force quitting might corrupt the database."];
    [alert runModal];      
    NSString*filePath=[self dataFilePath];
    NSString*storeType=NSBinaryStoreType;
    if([filePath hasSuffix:@"xml"]){
	storeType=NSXMLStoreType;
    }else if([filePath hasSuffix:@"sqlite"]){
	storeType=NSSQLiteStoreType;
    }
    NSError *error = nil;
    if (![self progressivelyMigrateURL:[NSURL fileURLWithPath:filePath]
				ofType:storeType
			       toModel:[self managedObjectModel]
				 error:&error]) {
	[[NSApplication sharedApplication] presentError:error];
	return;
    }
    [[NSApplication sharedApplication] requestUserAttention:NSInformationalRequest];
}


@end
