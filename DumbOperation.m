//
//  DumbOperations.m
//  spires
//
//  Created by Yuji on 09/02/07.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import "DumbOperation.h"

/*
@implementation DumbOperation
@synthesize finished;
@synthesize canceled;
@synthesize queue;
-(void)main
{
}

-(BOOL)wantToRunOnMainThread;
{
    return YES;
}
-(void)finish
{
    self.finished=YES;
}
-(void)cancel
{
    self.canceled=YES;
}
-(void)mainExceptionCatcher
{
    @try{
	[self main];
    }
    @catch(NSException*e){
	NSLog(@"exception raised inside an operation %@: %@",self,e);
    }
}

@end
*/

static NSOperationQueue*_queue=nil;
static NSOperationQueue*_Squeue=nil;
static NSOperationQueue*_Aqueue=nil;

@implementation OperationQueues
+(NSOperationQueue*)sharedQueue;
{
    if(!_queue){
	_queue=[[NSOperationQueue alloc] init];
	[_queue setMaxConcurrentOperationCount:1];
    }
    return _queue;
}
+(NSOperationQueue*)spiresQueue;
{
    if(!_Squeue){
	_Squeue=[[NSOperationQueue alloc] init];
	[_Squeue setMaxConcurrentOperationCount:1];
    }
    return _Squeue;
}
+(NSOperationQueue*)arxivQueue;
{
    if(!_Aqueue){
	_Aqueue=[[NSOperationQueue alloc] init];
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
/*
-(DumbOperationQueue*)init
{
    [super init];
    operations=[NSMutableArray array];
    return self;
}
-(NSArray*)operations
{
    return operations;
}
-(void)runIfAny
{
    if(!running && [operations count]>0){
	DumbOperation* op=[operations objectAtIndex:0];
	NSLog(@"runs:%@",op);
	[op addObserver:self
	     forKeyPath:@"finished" 
		options:NSKeyValueObservingOptionNew
		context:nil];
	running=YES;
	if([op wantToRunOnMainThread]){
	    [op main];
	}else{
	    [NSThread detachNewThreadSelector:@selector(mainExceptionCatcher) toTarget:op withObject:nil];
	}
    }
}
-(void)done
{
    DumbOperation*op=[operations objectAtIndex:0];
    [op removeObserver:self
	    forKeyPath:@"finished"];
//    NSLog(@"%p finished %@",op,op);
//    [self willChangeValueForKey:@"operations"];
    [operations removeObject:op];
//    [self didChangeValueForKey:@"operations"];
    running=NO;
    [self runIfAny];
}
-(void)cancelCurrentOperation
{
    if(!running || [operations count]==0){
	return;
    }
    DumbOperation*op=[operations objectAtIndex:0];
    [op cancel];
    NSLog(@"canceled:%@",op);
    [op removeObserver:self
	    forKeyPath:@"finished"];
    [operations removeObject:op];
    running=NO;
    [self runIfAny];    
}

-(void)addOperation:(DumbOperation*)op;
{
    if(![[NSThread currentThread] isMainThread]){
	[self performSelectorOnMainThread:@selector(addOperation:) withObject:op waitUntilDone:NO];
	return;
    }
//    [self willChangeValueForKey:@"operations"];
    for(DumbOperation*o in operations){
	if([o isEqual:op]){
	    NSLog(@"operation already queued, ignored: %@",op);
	    return;
	}
    }
    [operations addObject:op];
    [op setQueue:self];
//    [self didChangeValueForKey:@"operations"];
//    NSLog(@"queued operation %@",op);
    [self runIfAny];
}

-(void) observeValueForKeyPath:(NSString *)keyPath ofObject:(DumbOperation*)object change:(NSDictionary *)change context:(void *)context
{
    if([keyPath isEqualToString:@"finished"] && object.finished){
	[self performSelectorOnMainThread:@selector(done) withObject:nil waitUntilDone:NO];
    }
}
 */
@end

@implementation ConcurrentOperation
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
-(void)checkIfCancelled:(id)userInfo
{
    if([self isCancelled]){
	[self cleanupToCancel];
	[self finish];
    }
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