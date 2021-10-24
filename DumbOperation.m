//
//  DumbOperations.m
//  spires
//
//  Created by Yuji on 09/02/07.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import "DumbOperation.h"
#import "NetworkOperationQueue.h"

static NSOperationQueue*_queue=nil;
static NSOperationQueue*_Iqueue=nil;
static NSOperationQueue*_Squeue=nil;
static NSOperationQueue*_Aqueue=nil;

@interface UniqueOperationQueue:NSOperationQueue{
}
@end
@implementation UniqueOperationQueue
-(void)addOperation:(NSOperation*)op
{
    for(NSOperation*o in self.operations){
	if([op isEqual:o]){
	    return;
	}
    }
    [super addOperation:op];
}
@end

@implementation OperationQueues
+(NSOperationQueue*)sharedQueue;
{
    if(!_queue){
	_queue=[[UniqueOperationQueue alloc] init];
//	[_queue setMaxConcurrentOperationCount:1];
    }
    return _queue;
}
+(NSOperationQueue*)importQueue;
{
    if(!_Iqueue){
        _Iqueue=[[UniqueOperationQueue alloc] init];
        [_Iqueue setMaxConcurrentOperationCount:1];
    }
    return _Iqueue;
}
+(NSOperationQueue*)spiresQueue;
{
    if(!_Squeue){
	_Squeue=[[NetworkOperationQueue alloc] initWithHost:@"inspirehep.net" andWaitBetweenOperations:
                 [[NSUserDefaults standardUserDefaults] integerForKey:@"inspireWaitInSeconds"]];
	[_Squeue setMaxConcurrentOperationCount:1];
    }
    return _Squeue;
}
+(NSOperationQueue*)arxivQueue;
{
    if(!_Aqueue){
	_Aqueue=[[NetworkOperationQueue alloc] initWithHost:@"arxiv.org" andWaitBetweenOperations:
                 [[NSUserDefaults standardUserDefaults] integerForKey:@"arXivWaitInSeconds"]];
	[_Aqueue setMaxConcurrentOperationCount:1];
    }
    return _Aqueue;
}
+(void)cancelOperationsInQueue:(NSOperationQueue*)q
{
    for(NSOperation*op in [q operations]){
	[op cancel];
    }
}
+(void)cancelCurrentOperations
{
    [self cancelOperationsInQueue:[self sharedQueue]];
    [self cancelOperationsInQueue:[self arxivQueue]];
    [self cancelOperationsInQueue:[self spiresQueue]];
}
@end

@implementation ConcurrentOperation
-(void)start
{
    [self performSelectorOnMainThread:@selector(run) withObject:nil waitUntilDone:YES];
}
-(void)run
{
    NSLog(@"should not be called at all!");
}
-(BOOL)isConcurrent
{
    return YES;
}
-(BOOL)isExecuting
{
    return isExecuting;
}
-(BOOL)isFinished
{
    return isFinished;
}
-(void)checkIfCancelled:(id)userInfo
{
    if([self isCancelled]){
	[self cleanupToCancel];
	[self finish];
    }
}
-(void)setIsExecuting:(BOOL)b
{
    [self willChangeValueForKey:@"isExecuting"];
    isExecuting=b;
    if(b){
	cancelTimer=[NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(checkIfCancelled:) userInfo:nil repeats:YES];
    }else{
	[cancelTimer invalidate];
    }
    [self didChangeValueForKey:@"isExecuting"];
}
-(void)setIsFinished:(BOOL)b
{
    [self willChangeValueForKey:@"isFinished"];
    isFinished=b;
    [self didChangeValueForKey:@"isFinished"];
}
-(void)finish
{
    self.isExecuting=NO;
    self.isFinished=YES;
}
-(void)cleanupToCancel
{
}
@end
