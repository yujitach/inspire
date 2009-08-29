//
//  DirWatcher.m
//  spires
//
//  Created by Yuji on 6/30/09.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import "DirWatcher.h"
#import <CoreServices/CoreServices.h>


@interface DirWatcher (private)
-(void)fsEventCallbackWithNumberOfEvents:(size_t)numEvents 
				   paths:(NSArray*)eventPaths 
				   flags:(const FSEventStreamEventFlags*) eventFlags
				     ids:(const FSEventStreamEventId*) eventIds;
@end
static void fsEventCallbackFunction(
				    ConstFSEventStreamRef streamRef,
				    void *clientCallBackInfo,
				    size_t numEvents,
				    void *eventPaths,
				    const FSEventStreamEventFlags eventFlags[],
				    const FSEventStreamEventId eventIds[])
{
    NSArray*a=eventPaths;
    DirWatcher*w=clientCallBackInfo;
    [w fsEventCallbackWithNumberOfEvents:numEvents paths:a flags: eventFlags ids:eventIds];
}


@implementation DirWatcher
-(id)initWithPath:(NSString*)path delegate:(id)d;
{
    self=[super init];
    pathToWatch=path;
    delegate=d;
    date=[NSDate date];
    CFArrayRef paths=CFRetain([NSArray arrayWithObject:pathToWatch]);
    FSEventStreamContext context;
    context.version=0;
    context.info=self;
    context.retain=NULL;
    context.release=NULL;
    context.copyDescription=NULL;
    stream = FSEventStreamCreate(kCFAllocatorDefault,
				 &fsEventCallbackFunction,
				 &context,
				 paths,
				 kFSEventStreamEventIdSinceNow, 
				 3.0,
				 kFSEventStreamCreateFlagUseCFTypes 
				 );
    CFRelease(paths);
    FSEventStreamScheduleWithRunLoop(stream, CFRunLoopGetCurrent(),kCFRunLoopDefaultMode);
    FSEventStreamStart(stream);
    return self;
}
-(void)finalize
{
    FSEventStreamStop(stream);
    FSEventStreamInvalidate(stream);
    FSEventStreamRelease(stream);
    [super finalize];
}
-(void)report
{
    NSDate*d=[NSDate date];
    NSFileManager*fm=[NSFileManager defaultManager];
    NSArray*files=[fm contentsOfDirectoryAtPath:pathToWatch error:NULL];
    for(NSString*file in files){
	NSString*fullPath=[pathToWatch stringByAppendingPathComponent:file];
	NSDictionary*dict=[fm attributesOfItemAtPath:fullPath error:NULL];
	NSDate*m=[dict valueForKey:NSFileModificationDate];
	if([m compare:date]==NSOrderedDescending){
	    [delegate modifiedFileAtPath:fullPath];
	}
    }
    date=d;
}
-(void)fsEventCallbackWithNumberOfEvents:(size_t)numEvents 
				   paths:(NSArray*)eventPaths 
                                   flags:(const FSEventStreamEventFlags*) eventFlags
				     ids:(const FSEventStreamEventId*) eventIds;
{
    for(size_t i=0;i<numEvents;i++){
	NSString*p=[eventPaths objectAtIndex:i];
	if([p isEqualToString:[pathToWatch stringByAppendingString:@"/"]]){
	    [self report];
	}
    }
}

@end
