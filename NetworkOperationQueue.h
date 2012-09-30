//
//  NetworkOperationQueue.h
//  inspire
//
//  Created by Yuji on 2012/09/30.
//
//

#import <Foundation/Foundation.h>

@interface NetworkOperationQueue : NSOperationQueue
-(NetworkOperationQueue*)initWithHost:(NSString*)host andWaitBetweenOperations:(NSTimeInterval)wait;
@end
