//
//  TeXBibGenerationOperation.h
//  spires
//
//  Created by Yuji on 09/02/07.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DumbOperation.h"

@interface TeXBibGenerationOperation : ConcurrentOperation
-(TeXBibGenerationOperation*)initWithTeXFile:(NSString*)t andMOC:(NSManagedObjectContext*)m byLookingUpWeb:(BOOL)b andRefreshingAll:(BOOL)a;
+(NSDictionary*)infoForTeXFile:(NSString*)file;
@end
