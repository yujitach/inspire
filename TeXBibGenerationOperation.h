//
//  TeXBibGenerationOperation.h
//  spires
//
//  Created by Yuji on 09/02/07.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DumbOperation.h"

@interface TeXBibGenerationOperation : ConcurrentOperation {
    NSString*texFile;
    NSManagedObjectContext*moc;
    BOOL twice;
    NSDictionary*dict;
    NSArray*citations;
    NSDictionary*mappings;
    NSMutableDictionary* keyToArticle;
    NSArray*entriesAlreadyInBib;
}
-(TeXBibGenerationOperation*)initWithTeXFile:(NSString*)t andMOC:(NSManagedObjectContext*)m byLookingUpWeb:(BOOL)b;
+(NSDictionary*)infoForTeXFile:(NSString*)file;
@end
