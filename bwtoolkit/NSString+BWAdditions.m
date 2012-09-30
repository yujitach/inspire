//
//  NSString+BWAdditions.m
//  BWToolkit
//
//  Created by Brandon Walkin (www.brandonwalkin.com)
//  All code is provided under the New BSD license.
//

#import "NSString+BWAdditions.h"

@implementation NSString (BWAdditions)

+ (NSString *)bwRandomUUID
{
	CFUUIDRef uuidObj = CFUUIDCreate(nil);
	NSString *newUUID = (__bridge_transfer NSString*)CFUUIDCreateString(nil, uuidObj);
	CFRelease(uuidObj);
	
	return newUUID;
}

@end
