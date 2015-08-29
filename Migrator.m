//
//  Migrator.m
//  spires
//
//  Created by Yuji on 12/16/09.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import "Migrator.h"
#import "MigrationProgressController.h"


@implementation Migrator
#pragma mark migration

// manual migration code. Taken from Marcus Zarra's CoreData book;
// progress bar code added by Yuji
-(int)versionFromMomPath:(NSString*)path
{
    NSArray*a=[[path lastPathComponent] componentsSeparatedByString:@" "];
    if([a count]==1)
	return 0;
    NSString*s=[a lastObject];
    NSString*t=[s componentsSeparatedByString:@"."][0];
    return [t intValue];
}
-(NSArray*)modelPaths
{
    //Find all of the mom and momd files in the Resources directory
    NSMutableArray *modelPaths = [NSMutableArray array];
    NSArray *momdArray = [mainBundle pathsForResourcesOfType:@"momd" 
							    inDirectory:nil];
    for (NSString *momdPath in momdArray) {
	NSString *resourceSubpath = [momdPath lastPathComponent];
	NSArray *array = [mainBundle 
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
					 mergedModelFromBundles:@[mainBundle]
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
	mappingModel = [NSMappingModel mappingModelFromBundles:@[mainBundle] 
						forSourceModel:sourceModel 
					      destinationModel:targetModel];
	//If we found a mapping model then proceed
	if (mappingModel) break;
	//Release the target model and keep looking
	targetModel = nil;
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
    NSString *backupPath = [[dataFilePath stringByDeletingLastPathComponent] stringByAppendingPathComponent:name];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if([fileManager fileExistsAtPath:backupPath]){
	// Don't use async operation here! Think !
        NSURL*origin=[NSURL fileURLWithPath:backupPath];
        NSURL*destination;
        [[NSFileManager defaultManager] trashItemAtURL:origin resultingItemURL:&destination error:NULL];
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
    
//    [[NSGarbageCollector defaultCollector] collectExhaustively];
    
    //We may not be at the "current" model yet, so recurse
    return [self progressivelyMigrateURL:sourceStoreURL
				  ofType:type 
				 toModel:finalModel 
				   error:error];
    //END:progressivelyMigrateURLMoveAndRecurse
}

-(BOOL)specialMigrationFrom:(NSString*)from To:(NSString*)to
{
    NSError*error=nil;
    NSDictionary *sourceMetadata = 
    [NSPersistentStoreCoordinator metadataForPersistentStoreOfType:NSSQLiteStoreType
							       URL:[NSURL fileURLWithPath:dataFilePath]
							     error:&error];
    if (!sourceMetadata) return NO;
    NSString*fromModel=[@"spires_DataModel " stringByAppendingString:from];
    NSString*toModel=[@"spires_DataModel " stringByAppendingString:to];
    NSURL*oldMOMURL=[mainBundle URLForResource:fromModel withExtension:@"mom" subdirectory:@"spires_DataModel.momd"];
    NSManagedObjectModel* mom1=[[NSManagedObjectModel alloc] initWithContentsOfURL:oldMOMURL];
    
    if (![mom1 isConfiguration:nil 
   compatibleWithStoreMetadata:sourceMetadata]) {
	NSLog(@"No need to special case migration from %@ to %@.", from, to);
	return NO;
    }
    NSURL*newMOMURL=[mainBundle URLForResource:toModel withExtension:@"mom" subdirectory:@"spires_DataModel.momd"];
    NSManagedObjectModel* mom2=[[NSManagedObjectModel  alloc] initWithContentsOfURL:newMOMURL];
    
    error=nil;
    NSMappingModel*mm=[NSMappingModel inferredMappingModelForSourceModel:mom1
							destinationModel:mom2 error:&error];
    if(!mm){
	NSLog(@"Should perform special case migration, but can't.");
	return NO;
    }
    
    NSValue *classValue = [NSPersistentStoreCoordinator registeredStoreTypes][NSSQLiteStoreType];
    Class sqliteStoreClass = (Class)[classValue pointerValue];
    Class sqliteStoreMigrationManagerClass = [sqliteStoreClass migrationManagerClass];
    
    NSMigrationManager *manager = [[sqliteStoreMigrationManagerClass alloc]
				   initWithSourceModel:mom1 destinationModel:mom2];
    
    error=nil;
    NSString*destPath=[[dataFilePath stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"specialMigrationTemporary.sqlite"];
    if (![manager migrateStoreFromURL:[NSURL fileURLWithPath:dataFilePath] type:NSSQLiteStoreType
			      options:nil withMappingModel:mm toDestinationURL:[NSURL fileURLWithPath:destPath]
		      destinationType:NSSQLiteStoreType destinationOptions:nil error:&error]) {
	
        NSLog(@"special case migration failed: %@", error);
	
        return NO;
    }
//    FSPathMoveObjectToTrashSync([dataFilePath fileSystemRepresentation], NULL, kFSFileOperationDefaultOptions);
    [[NSFileManager defaultManager] moveItemAtPath:dataFilePath
					    toPath:[dataFilePath stringByAppendingString:[@".ver" stringByAppendingString:from]]
					     error:&error];
    [[NSFileManager defaultManager] moveItemAtPath:destPath
					    toPath:dataFilePath
					     error:&error];
    NSLog(@"special case migration from %@ to %@ succeeded.",from,to);
    
    return YES;
}
-(void)performMigration
{
/*    NSAlert*alert=[NSAlert alertWithMessageText:@"spires.app will update its database."
				  defaultButton:@"OK" 
				alternateButton:nil
				    otherButton:nil
		      informativeTextWithFormat:@"To improve the search performance, "
		   @"spires.app is going to precalculate various search keys and cache them, etc. " 
		   @"This might take five minuites or more. "
		   @"Spinning rainbow cursor will appear, but please wait patiently until it finishes. "
		   @"Force quitting might corrupt the database."];
    [alert runModal];  */    
    // this is a special code to initiate lightweight migration during developments
    [self specialMigrationFrom:@"5" To:@"6"];
    if([self specialMigrationFrom:@"6" To:@"7"]){
	return;
    }
    NSError*error=nil;
    if (![self progressivelyMigrateURL:[NSURL fileURLWithPath:dataFilePath]
				ofType:NSSQLiteStoreType
			       toModel:[NSManagedObjectModel mergedModelFromBundles:@[mainBundle]]
				 error:&error]) {
	[[NSApplication sharedApplication] presentError:error];
	return;
    }
    [NSApp requestUserAttention:NSInformationalRequest];
}

#pragma mark Misc
-(id)initWithDataPath:(NSString*)path
{
    self=[super init];
    dataFilePath=path;
    mainBundle=[NSBundle mainBundle];
    return self;
}
@end
