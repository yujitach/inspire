//
//  NSURL+libraryProxy.m
//  spires
//
//  Created by Yuji on 09/02/22.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import "NSURL+libraryProxy.h"
#import "RegexKitLite.h"

@implementation NSURL (libraryProxy)
-(NSURL*)proxiedURLForELibrary;
{
    NSUserDefaults*defaults=[NSUserDefaults standardUserDefaults];
    NSArray*pair=[defaults dictionaryForKey:@"regExpsForUniversityLibrary"][[defaults objectForKey:@"universityLibraryToGetPDF"]];
    NSString*from=pair[0];
    NSString*to=pair[1];
    NSString*proxiedURL=[[self absoluteString] stringByReplacingOccurrencesOfRegex:from withString:to];
    NSURL*url=[NSURL URLWithString:proxiedURL];
    return url;
}
@end
