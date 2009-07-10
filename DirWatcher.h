//
//  DirWatcher.h
//  spires
//
//  Created by Yuji on 6/30/09.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import <Cocoa/Cocoa.h>

// delegate should respond to modifiedFileAtPath:
@interface NSObject (DirWatcherDelegate)
-(void)modifiedFileAtPath:(NSString*)file;
@end

@interface DirWatcher : NSObject {
    NSString*pathToWatch;
    FSEventStreamRef stream;
    id delegate;
    NSDate*date;
}
-(id)initWithPath:(NSString*)path delegate:(id)d;
@end
