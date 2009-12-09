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
    return [NSString stringWithFormat:@"wait %f sec",(double)delay];
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
