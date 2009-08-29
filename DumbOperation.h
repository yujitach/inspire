//
//  DumbOperations.h
//  spires
//
//  Created by Yuji on 09/02/07.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import <Cocoa/Cocoa.h>
/*
@class DumbOperationQueue;
@interface DumbOperation : NSObject {
    BOOL finished;
    BOOL canceled;
    DumbOperationQueue *queue;
}
-(void)main;
-(BOOL)wantToRunOnMainThread;
-(void)finish;
-(void)cancel;
@property DumbOperationQueue* queue;
@property BOOL finished;
@property BOOL canceled;
@end

@interface DumbOperationQueue : NSObject {
    NSMutableArray* operations;
    BOOL running;
}
+(DumbOperationQueue*)sharedQueue;
+(DumbOperationQueue*)spiresQueue;
+(DumbOperationQueue*)arxivQueue;
-(void)addOperation:(DumbOperation*)op;
-(void)cancelCurrentOperation;
-(NSArray*)operations;
@end
*/

@interface OperationQueues : NSObject {
}
+(NSOperationQueue*)sharedQueue;
+(NSOperationQueue*)spiresQueue;
+(NSOperationQueue*)arxivQueue;
+(void)cancelCurrentOperations;
@end

@interface ConcurrentOperation: NSOperation {
    BOOL isFinished;
    BOOL isExecuting;
    NSTimer*cancelTimer;
}
-(void)finish;
-(void)cleanupToCancel;
// subclasses should override -run. 
//In Snow Leopard, NSOperationQueue runs concurrent NSOperations in non-main thread,
//which causes many headache. So ConcurrentOperation overrides -start to call -run on the main thread.
-(void)run;
@property (assign) BOOL isFinished;
@property (assign) BOOL isExecuting;
@end