//
//  NSString+XMLEntityDecoding.h
//  spires
//
//  Created by Yuji on 08/10/16.
//  Copyright 2008 Y. Tachikawa. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSString (XMLEntityDecoding)
-(NSString*)stringByExpandingAmpersandEscapes;


@end
