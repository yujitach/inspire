//
//  MOC.h
//  spires
//
//  Created by Yuji on 09/02/28.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface MOC : NSObject {
    NSPersistentStoreCoordinator *persistentStoreCoordinator;
    NSManagedObjectModel *managedObjectModel;
    NSManagedObjectContext *managedObjectContext;    
    NSManagedObjectContext *secondaryManagedObjectContext;    
}
+(NSManagedObjectContext*)moc;
+(NSManagedObjectContext*)secondaryManagedObjectContext;
+(MOC*)sharedMOCManager;
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator;
- (NSManagedObjectModel *)managedObjectModel;
- (NSManagedObjectContext *)managedObjectContext;
- (NSManagedObjectContext *)secondaryManagedObjectContext;
- (NSString *)applicationSupportFolder;
- (NSString *)dataFilePath;
@end
