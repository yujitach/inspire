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
@interface SpiresQueryOperation : DumbOperation {
    NSString*search;
    Article*citedByTarget;
    Article*refersToTarget;
    NSManagedObjectContext*moc;

}
-(SpiresQueryOperation*)initWithQuery:(NSString*)q andMOC:(NSManagedObjectContext*)m;
@end
