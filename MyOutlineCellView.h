//
//  MyOutlineCellView.h
//  spires
//
//  Created by Yuji on 2018/08/27.
//

#import <Cocoa/Cocoa.h>
#import "HoverImageView.h"
@class ArticleList;
@class SideOutlineViewController;
@interface MyOutlineCellView : NSTableCellView
@property (nullable,assign) HoverImageView*imageView;
@property (nonatomic,retain)ArticleList*articleList;
@property (nonatomic,retain) IBOutlet SideOutlineViewController*sideOutlineViewController;
@end
