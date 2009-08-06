//
//  NSString+magic.h
//  spires
//
//  Created by Yuji on 09/02/18.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSString (NSString_magic)
-(NSString*)magicTeXed;
-(NSString*)quieterVersion;
-(NSString*)normalizedString;
-(NSString*)quotedForShell;
@end
