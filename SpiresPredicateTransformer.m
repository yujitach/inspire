//
//  SpiresPredicateTransformer.m
//  spires
//
//  Created by Yuji on 08/10/16.
//  Copyright 2008 Y. Tachikawa. All rights reserved.
//

#import "SpiresPredicateTransformer.h"
#import "SpiresHelper.h"

@implementation SpiresPredicateTransformer
+(Class)transformedValueClass
{
    return [NSString class];
}
+(BOOL)allowsReverseTransformation
{
    return NO;
}
-(NSPredicate*)transformedValue:(NSString*)value
{
    return [[SpiresHelper sharedHelper] predicateFromSPIRESsearchString:value];
}
+(NSPredicate*)transformedValue:(NSString*)value
{
    return [[SpiresHelper sharedHelper] predicateFromSPIRESsearchString:value];
}

    
@end
