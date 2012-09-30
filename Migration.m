//
//  Migration.m
//  spires
//
//  Created by Yuji on 12/16/09.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import "Migration.h"
#import "MOC.h"

void migrateIfNecessary(void)
{
    if(![[MOC sharedMOCManager] migrationNeeded]){
	return;
    }
    NSMutableDictionary*env=[NSMutableDictionary dictionary]; 
    [env setObject:[[MOC sharedMOCManager] dataFilePath]
	    forKey:@"dataFilePath"];
    [env setObject:[[NSBundle mainBundle] bundlePath]
	    forKey:@"bundlePath"];
    NSString*migratorPath=[[NSBundle mainBundle] pathForResource:@"spires database migrator" ofType:@"app"];
    [[NSWorkspace sharedWorkspace] launchApplicationAtURL:[NSURL fileURLWithPath:migratorPath]
						  options:NSWorkspaceLaunchDefault
					    configuration:[NSDictionary dictionaryWithObject:env forKey:NSWorkspaceLaunchConfigurationEnvironment]
						    error:NULL];
    exit(0);
}
