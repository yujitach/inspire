//
//  SyncManager.h
//  inspire
//
//  Created by Yuji on 2015/08/11.
//
//

#import <Foundation/Foundation.h>
#if TARGET_OS_IPHONE
#import "iCloud.h"
#else
#import "DirWatcher.h"
#endif
@interface SyncManager :NSObject<
#if TARGET_OS_IPHONE
iCloudDelegate
#else
DirWatcherDelegate
#endif
>

@end
