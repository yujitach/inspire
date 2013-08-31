//
//  WaitOperation.m
//  spires
//
//  Created by Yuji on 6/30/09.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import "WaitOperation.h"


@implementation WaitOperation
-(id)initWithTimeInterval:(NSTimeInterval)mm
{
    self=[super init];
    delay=mm;
    return self;
}
-(NSString*)description
{
    NSArray*a=[self dependencies];
    if([a count]==0){
        return [NSString stringWithFormat:@"wait %f sec",(double)delay];
    }else{
        return [NSString stringWithFormat:@"wait %f sec (for %@)",(double)delay, [a[0] description]];
    }
}
-(void)wakeUp:(id)neglected
{
    [self finish];
}
-(void)run
{
    self.isExecuting=YES;
    [self performSelector:@selector(wakeUp:) withObject:nil afterDelay:delay];
}
@end
