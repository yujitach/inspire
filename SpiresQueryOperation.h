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
@class BatchImportOperation;
@interface SpiresQueryOperation : ConcurrentOperation {
    NSString*search;
    NSManagedObjectContext*moc;
    SpiresQueryDownloader*downloader;
    NSInteger startAt;
    BatchImportOperation*importer;
}
-(SpiresQueryOperation*)initWithQuery:(NSString*)q andMOC:(NSManagedObjectContext*)m;
@property(readonly) BatchImportOperation*importer;
@end
