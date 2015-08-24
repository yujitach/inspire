//
//  Migrator.h
//  spires
//
//  Created by Yuji on 12/16/09.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

@import CoreData;


@interface Migrator : NSObject {
    NSString*dataFilePath;
    NSBundle*mainBundle;
}
-(id)initWithDataPath:(NSString*)path;
-(void)performMigration;
@end
