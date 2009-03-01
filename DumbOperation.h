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
    DumbOperationQueue *queue;
}
-(void)main;
-(BOOL)wantToRunOnMainThread;
-(void)finish;
@property DumbOperationQueue* queue;
@property BOOL finished;
@end

@interface DumbOperationQueue : NSObject {
    NSMutableArray* operations;
    BOOL running;
}
+(DumbOperationQueue*)sharedQueue;
+(DumbOperationQueue*)spiresQueue;
+(DumbOperationQueue*)arxivQueue;
-(void)addOperation:(DumbOperation*)op;
-(NSArray*)operations;
@end

