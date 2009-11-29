//
//  MOC.m
//  spires
//
//  Created by Yuji on 09/02/28.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import "MOC.h"
#import "MigrationProgressController.h"
#import "DumbOperation.h"

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
    
    managedObjectModel = [[NSManagedObjectModel mergedModelFromBundles:nil] retain];    
    
    return managedObjectModel;
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
	[self performMigration];
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
-(int)versionFromMomPath:(NSString*)path
{
    NSArray*a=[[path lastPathComponent] componentsSeparatedByString:@" "];
    if([a count]==1)
	return 0;
    NSString*s=[a lastObject];
    NSString*t=[[s componentsSeparatedByString:@"."] objectAtIndex:0];
    return [t intValue];
}
-(NSArray*)modelPaths
{
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
    
    [modelPaths sortUsingComparator:^(id path1,id path2){
	int v1=[self versionFromMomPath:path1];
	int v2=[self versionFromMomPath:path2];
	if (v1<v2){
	    return (NSComparisonResult)NSOrderedDescending;
	}
	if (v1>v2){
	    return (NSComparisonResult)NSOrderedAscending;
	}
	return (NSComparisonResult)NSOrderedSame;
    }];
    return modelPaths;
}

- (BOOL)progressivelyMigrateURL:(NSURL*)sourceStoreURL
                         ofType:(NSString*)type 
                        toModel:(NSManagedObjectModel*)finalModel 
                          error:(NSError**)error
{
    NSAssert(error!=nil,@"error should be taken care of!");

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

    //Find the source model
    NSManagedObjectModel *sourceModel = [NSManagedObjectModel 
					 mergedModelFromBundles:nil
					 forStoreMetadata:sourceMetadata];
    NSAssert(sourceModel != nil, ([NSString stringWithFormat:
				   @"Failed to find source model\n%@", 
				   sourceMetadata]));
    

    NSArray*modelPaths=[self modelPaths];
    //See if we can find a matching destination model
    NSMappingModel *mappingModel = nil;
    NSManagedObjectModel *targetModel = nil;
    NSString *modelPath = nil;
    // modelPaths contain the models in the descending order of the models.
    for(modelPath in modelPaths){
	NSLog(@"trying to see if %@ works...",[modelPath lastPathComponent]);
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

    //We have a mapping model and a destination model.  Time to migrate
    //START:progressivelyMigrateURLMigrate
    NSMigrationManager *manager = [[NSMigrationManager alloc] 
				   initWithSourceModel:sourceModel
				   destinationModel:targetModel];
    NSString *modelName = [[modelPath lastPathComponent] 
			   stringByDeletingPathExtension];
    NSString *storeExtension = [[sourceStoreURL path] pathExtension];
    NSString *storePath = [[sourceStoreURL path] stringByDeletingPathExtension];

    int toVersion=[self versionFromMomPath:modelPath];
    NSString*message=[NSString stringWithFormat:@"Migrating database v%d to v%d. Please wait patiently...",toVersion-1,toVersion];
    MigrationProgressController*controller=[[MigrationProgressController alloc] initWithMigrationManager:manager
											     WithMessage:message];
    NSLog(@"migrating to %@...",modelName);
    //Build a path to write the new store
    storePath = [NSString stringWithFormat:@"%@.%@.%@", storePath, 
		 modelName, storeExtension];
    NSURL *destinationStoreURL = [NSURL fileURLWithPath:storePath];
    [[controller window] makeKeyAndOrderFront:self];
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),^{
	[manager migrateStoreFromURL:sourceStoreURL 
				type:type 
			     options:nil 
		    withMappingModel:mappingModel 
		    toDestinationURL:destinationStoreURL 
		     destinationType:type 
		  destinationOptions:nil 
			       error:error];
//	dispatch_async(dispatch_get_main_queue(),^{
	    [[NSApplication sharedApplication] stopModal];
//	});
//    });
//    [[NSApplication sharedApplication] runModalForWindow:[controller window]];
    [controller close];
    if(*error){
	return NO;
    }
    //END:progressivelyMigrateURLMigrate
    //Migration was successful, move the files around to preserve the source
    //START:progressivelyMigrateURLMoveAndRecurse
    NSString*name=[[sourceStoreURL lastPathComponent] stringByDeletingPathExtension];
    name=[name stringByAppendingFormat:@"~.%@",storeExtension];
    NSString *backupPath = [[self applicationSupportFolder] stringByAppendingPathComponent:name];
    
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
    
    [[NSGarbageCollector defaultCollector] collectExhaustively];
    
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
    NSError*error=nil;
    if (![self progressivelyMigrateURL:[NSURL fileURLWithPath:[self dataFilePath]]
				ofType:[self storeType]
			       toModel:[self managedObjectModel]
				 error:&error]) {
	[[NSApplication sharedApplication] presentError:error];
	return;
    }
    [[NSApplication sharedApplication] requestUserAttention:NSInformationalRequest];
}


@end
