//
//  BibViewController.h
//  spires
//
//  Created by Yuji on 09/02/01.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface BibViewController : NSWindowController {
    NSArray* articles;
    IBOutlet NSTextView* tv;
//    IBOutlet NSWindow* window;
}
-(void)setArticles:(NSArray*)a;
-(void)showWindow:(id)sender;
@end
