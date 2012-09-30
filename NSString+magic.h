//
//  NSString+magic.h
//  spires
//
//  Created by Yuji on 09/02/18.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RegexKitLite.h"


@interface NSString (NSString_magic)
-(NSString*)magicTeXed;
-(NSString*)quieterVersion;
-(NSString*)normalizedString;
-(NSString*)quotedForShell;
-(NSString*)capitalizedStringForName;
-(NSString*)stringByExpandingAmpersandEscapes;
-(NSString*)stringByConvertingTeXintoHTML;
//-(NSString*)stringByReplacingOccurrencesOfRegex:(NSString*)regex withString:(NSString*)string;
@end

@interface NSMutableString (NSMutableString_magic)
//-(void)replaceOcuurrencesOfRegex:(NSString*)regex withString:(NSString*)string;
@end
