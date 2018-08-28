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
@synthesize articleList=_articleList;
-(void)setArticleList:(ArticleList *)articleList
{
    _articleList=articleList;
    self.imageView.image=self.articleList.icon;
    self.textField.stringValue=self.articleList.name;
    
    self.imageView.enabled=YES;
    self.imageView.hidden=NO;
    self.button.enabled=NO;
    self.button.hidden=YES;

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
-(void)setBackgroundStyle:(NSBackgroundStyle)backgroundStyle
{
    [super setBackgroundStyle:backgroundStyle];
    if(self.articleList.hasButton && self.backgroundStyle==NSBackgroundStyleDark){
        self.imageView.enabled=NO;
        self.imageView.hidden=YES;
        self.button.enabled=YES;
        self.button.hidden=NO;
    }else{
        self.imageView.enabled=YES;
        self.imageView.hidden=NO;
        self.button.enabled=NO;
        self.button.hidden=YES;
    }
}
@end
