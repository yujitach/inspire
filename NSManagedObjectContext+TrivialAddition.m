//
//  NSManagedObjectContext+TrivialAddition.m
//  spires
//
//  Created by Yuji on 09/02/07.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import "NSManagedObjectContext+TrivialAddition.h"


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
