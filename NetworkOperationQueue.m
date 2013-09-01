//
//  NetworkOperationQueue.m
//  inspire
//
//  Created by Yuji on 2012/09/30.
//
//

#import "NetworkOperationQueue.h"
#import "Reachability.h"
@implementation NetworkOperationQueue
{
    Reachability*reach;
    NSTimeInterval sleep;
    NSString*hostname;
    BOOL online;
}
-(void)reachabilityChanged:(NSNotification*)note{
    Reachability*x=note.object;
    if(x!=reach)return;
    NetworkStatus status=[reach currentReachabilityStatus];
    if(status==NotReachable){
        NSLog(@"%@ is off line",hostname);
        online=NO;
    }else{
        NSLog(@"%@ is on line",hostname);
        online=YES;
    }
}

-(NetworkOperationQueue*)initWithHost:(NSString*)host andWaitBetweenOperations:(NSTimeInterval)wait
{
    if(self=[super init]){
        sleep=wait;
        hostname=host;
        online=YES;
        reach=[Reachability reachabilityWithHostName:host];
        [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(reachabilityChanged:) name: kReachabilityChangedNotification object: nil];
        reach=[Reachability reachabilityWithHostName:host];
        [reach startNotifier];
        NSLog(@"queue for %@ created with wait %d",host,(int)wait);
    }
    return self;
}

-(void)addOperation:(NSOperation *)op
{
    if(online){
        void (^cb)()=op.completionBlock;
        __weak NSOperationQueue*me=self;
        [op setCompletionBlock:^{
            [me setSuspended:YES];
//            NSLog(@"^wait %d for %@",(int)sleep,hostname);
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(sleep * NSEC_PER_SEC));
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                [me setSuspended:NO];
//                NSLog(@"_wait %d for %@",(int)sleep,hostname);
            });
            if(cb){
                cb();
            }
        }];
        [super addOperation:op];
    }
}
@end
