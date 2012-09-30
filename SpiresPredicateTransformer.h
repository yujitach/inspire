//
//  SpiresPredicateTransformer.h
//  spires
//
//  Created by Yuji on 08/10/16.
//  Copyright 2008 Y. Tachikawa. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface SpiresPredicateTransformer : NSValueTransformer {
}
+(Class)transformedValueClass;
+(BOOL)allowsReverseTransformation;
-(NSPredicate*)transformedValue:(NSString*)value;
+(NSPredicate*)transformedValue:(NSString*)value;
@end
