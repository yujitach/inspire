//
//  main.m
//  spires
//
//  Created by Yuji on 08/10/13.
//  Copyright Y. Tachikawa 2008. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SpiresPredicateTransformer.h"
#import "MOC.h"

int main(int argc, char *argv[])
{
    @autoreleasepool{
//            warmUpIfSuitable();
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),^{
                [NSData dataWithContentsOfFile:[[MOC sharedMOCManager] dataFilePath]];
            });
            [NSValueTransformer setValueTransformer:[[SpiresPredicateTransformer alloc] init]
				    forName:@"SpiresPredicateTransformer"];    
            return NSApplicationMain(argc,  (const char **) argv);
    }
}
