//
//  ArticleView.h
//  spires
//
//  Created by Yuji on 08/10/17.
//  Copyright 2008 Y. Tachikawa. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>
@class Article;
@interface ArticleView : WebView {
    Article *article;
     NSString*templateForWebView;
}
-(void)setArticle:(Article*)a;
@end
