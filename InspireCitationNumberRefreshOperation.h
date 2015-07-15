//
//  InspireCitationNumberRefreshOperation.h
//  spires
//
//  Created by Yuji on 3/26/11.
//  Copyright 2011 Y. Tachikawa. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DumbOperation.h"

@interface InspireCitationNumberRefreshOperation : NSOperation
-(InspireCitationNumberRefreshOperation*)initWithArticles:(NSSet*)a;
@end
