//
//  SpiresQueryOperation.h
//  spires
//
//  Created by Yuji on 09/02/07.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <CoreData/CoreData.h>
#import "DumbOperation.h"
@class Article;
@class SpiresQueryDownloader;
@interface SpiresQueryOperation : ConcurrentOperation {
    NSString*search;
    Article*citedByTarget;
    Article*refersToTarget;
    NSManagedObjectContext*moc;
    SpiresQueryDownloader*downloader;
    NSOperation*parent;
}
-(SpiresQueryOperation*)initWithQuery:(NSString*)q andMOC:(NSManagedObjectContext*)m;
-(void)setParent:(NSOperation*)p;
@end
