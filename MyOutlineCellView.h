//
//  MyOutlineCellView.h
//  spires
//
//  Created by Yuji on 2018/08/27.
//

#import <Cocoa/Cocoa.h>
@class ArticleList;
@class SideOutlineViewController;
@interface MyOutlineCellView : NSTableCellView
@property (nullable,assign) IBOutlet NSButton*button;
@property (nullable,nonatomic,retain)ArticleList*articleList;
@property (nullable,nonatomic,retain) IBOutlet SideOutlineViewController*sideOutlineViewController;
@end
