//
//  MyOutlineCellView.m
//  spires
//
//  Created by Yuji on 2018/08/27.
//

#import "MyOutlineCellView.h"
#import "ArticleList.h"
#import "SideOutlineViewController.h"

@implementation MyOutlineCellView
@dynamic imageView;
@synthesize articleList=_articleList;
-(void)setArticleList:(ArticleList *)articleList
{
    _articleList=articleList;
    self.imageView.image=self.articleList.icon;
    if(self.articleList.hasButton){
        self.imageView.alternateImage=[NSImage imageNamed:NSImageNameRefreshTemplate];
    }else{
        self.imageView.alternateImage=nil;
    }
    self.textField.stringValue=self.articleList.name;
}

-(IBAction)articleListNameEdited:(NSTextField*)sender
{
    self.articleList.name=sender.stringValue;
}
-(IBAction)articleListImageClicked:(NSButton*)sender
{
    if(self.articleList.hasButton){
        [self.articleList reload];
    }
    [self.sideOutlineViewController selectArticleList:self.articleList];
}

@end
