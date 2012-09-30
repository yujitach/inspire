//
//  NSManagedObjectContext+TrivialAddition.h
//  spires
//
//  Created by Yuji on 09/02/07.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <CoreData/CoreData.h>

@interface NSManagedObjectContext (TrivialAddition)
-(void)disableUndo;
-(void)enableUndo;
@end
