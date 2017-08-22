//
//  MOC.h
//  spires
//
//  Created by Yuji on 09/02/28.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

@import CoreData;
extern NSString* UIMOCDidMergeNotification;

@interface NSManagedObjectContext (TrivialAddition)
-(void)disableUndo;
-(void)enableUndo;
@end

@interface MOC : NSObject
+(NSManagedObjectContext*)moc;
+(MOC*)sharedMOCManager;
-(BOOL)migrationNeeded;
- (NSManagedObjectModel *)managedObjectModel;
- (NSManagedObjectContext *)managedObjectContext;
- (NSManagedObjectContext *)createSecondaryMOC;
- (NSString *)applicationSupportFolder;
- (NSString *)dataFilePath;
-(void)presentMOCSaveError:(NSError*)error;
-(void)vacuum;
@property(assign) BOOL isUIready;
@end
