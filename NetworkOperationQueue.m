//
//  NetworkOperationQueue.m
//  inspire
//
//  Created by Yuji on 2012/09/30.
//
//

#import "NetworkOperationQueue.h"
#import "Reachability.h"
#import "WaitOperation.h"
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
        [super addOperation:op];
        [super addOperation:[[WaitOperation alloc] initWithTimeInterval:sleep]];
    }
}
@end
