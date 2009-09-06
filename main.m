//
//  main.m
//  spires
//
//  Created by Yuji on 08/10/13.
//  Copyright Y. Tachikawa 2008. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SpiresPredicateTransformer.h"
#import "DumbOperation.h"
#import "AllArticleListFetchOperation.h"

int main(int argc, char *argv[])
{
    // Warm up the CoreData cache in a background thread.
    // see the difference it makes in the movie http://www.sns.ias.edu/~yujitach/spires/launchTimeComparison.mov
    [[OperationQueues sharedQueue] addOperation:[[AllArticleListFetchOperation alloc] init]];  

    [NSValueTransformer setValueTransformer:[[SpiresPredicateTransformer alloc] init]
				    forName:@"SpiresPredicateTransformer"];    
    
    return NSApplicationMain(argc,  (const char **) argv);
}
