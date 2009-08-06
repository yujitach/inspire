//
//  spires_AppDelegate_SyncCategory.m
//  spires
//
//  Created by Yuji on 09/02/04.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import "spires_AppDelegate_SyncCategory.h"
#import <SyncServices/SyncServices.h>

@implementation spires_AppDelegate (SyncCategory)
/*-(BOOL)syncEnabled
{
    return NO;
//    return [[NSUserDefaults standardUserDefaults] boolForKey:@"syncWithMobileMe"];
}

-(ISyncClient*)syncClient
{
    NSString *clientIdentifier = [[NSBundle mainBundle] bundleIdentifier];
    NSString *reason = @"unknown error";
    ISyncClient *client=nil;
    
    @try{
	client = [[ISyncManager sharedManager] clientWithIdentifier:clientIdentifier];
	if(!client){
	    if(![[ISyncManager sharedManager] registerSchemaWithBundlePath:[[NSBundle mainBundle] pathForResource:@"spires" ofType:@"syncschema"]]){
		reason=@"schema cannot be registered";
	    }else{	    
		client = [[ISyncManager sharedManager] registerClientWithIdentifier:clientIdentifier descriptionFilePath:[[NSBundle mainBundle] pathForResource:@"ClientDescription" ofType:@"plist"]];
		[client setShouldSynchronize:YES withClientsOfType:ISyncClientTypeApplication];
		[client setShouldSynchronize:YES withClientsOfType:ISyncClientTypeDevice];
		[client setShouldSynchronize:YES withClientsOfType:ISyncClientTypeServer];
		[client setShouldSynchronize:YES withClientsOfType:ISyncClientTypePeer];
	    }
	}
    }
    @catch(id exception){
	reason=[exception reason];
    }
    if (!client) {
        NSRunAlertPanel(@"You can not sync using MobileMe.", [NSString stringWithFormat:@"Failed to register the sync client: %@", reason], @"OK", nil, nil);
    }
    
    return client;
}
-(void)syncSetupAtStartup
{  
    NSURL*fastSyncDetailURL = [NSURL fileURLWithPath:[[self applicationSupportFolder] stringByAppendingPathComponent:@"spires.fastsyncstore"]];
    NSPersistentStore* store=[[[self persistentStoreCoordinator] persistentStores] objectAtIndex:0];
    [[self persistentStoreCoordinator] setStoresFastSyncDetailsAtURL:fastSyncDetailURL forPersistentStore:store];
    
    [[self syncClient] setSyncAlertHandler:self selector:@selector(client:mightWantToSyncEntityNames:)];
    [self syncAction:nil];
}
    

- (void)syncAction:(id)sender
{
    NSError *error = nil;
    ISyncClient *client = [self syncClient];
    if (nil != client) {
        [[[self managedObjectContext] persistentStoreCoordinator] syncWithClient:client inBackground:YES handler:self error:&error];
    }
    if (nil != error) {
        [[NSApplication sharedApplication] presentError:error];
    }
}

#pragma mark delegate methods

- (void)client:(ISyncClient *)client mightWantToSyncEntityNames:(NSArray *)entityNames
{
    NSLog(@"Saving for alert to sync...");
    [self saveAction:self];
}

- (NSArray *)managedObjectContextsToMonitorWhenSyncingPersistentStoreCoordinator:(NSPersistentStoreCoordinator *)coordinator
{
    return [NSArray arrayWithObject:[self managedObjectContext]];
}

- (NSArray *)managedObjectContextsToReloadAfterSyncingPersistentStoreCoordinator:(NSPersistentStoreCoordinator *)coordinator
{
    return [NSArray arrayWithObject:[self managedObjectContext]];
}

- (NSDictionary *)persistentStoreCoordinator:(NSPersistentStoreCoordinator *)coordinator willPushRecord:(NSDictionary *)record forManagedObject:(NSManagedObject *)managedObject inSyncSession:(ISyncSession *)session
{
    NSLog(@"push %@ = %@", [managedObject objectID], [record description]);
    return record;
}

- (ISyncChange *)persistentStoreCoordinator:(NSPersistentStoreCoordinator *)coordinator willApplyChange:(ISyncChange *)change toManagedObject:(NSManagedObject *)managedObject inSyncSession:(ISyncSession *)session
{
    NSLog(@"pull %@", [change description]);
    return change;
}
*/
@end
