//
//  DumbOperations.h
//  spires
//
//  Created by Yuji on 09/02/07.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import <Cocoa/Cocoa.h>

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

