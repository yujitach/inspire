//
//  NSFileManager+TemporaryFileName.m
//  spires
//
//  Created by Yuji on 09/02/07.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import "NSFileManager+TemporaryFileName.h"

static int num=0;
@implementation NSFileManager(TemporaryFileName)
-(NSString*)temporaryFileName
{
    NSString*tmpDir= @"/tmp/"; // NSTemporaryDirectory();
    if(!tmpDir){
	tmpDir=@"/tmp/";
    }
    if(![tmpDir hasSuffix:@"/"]){
	tmpDir=[tmpDir stringByAppendingString:@"/"];
    }
    return [NSString stringWithFormat:@"%@spiresTemporaryFile%d-%d",tmpDir,getuid(),num++];
}

@end
