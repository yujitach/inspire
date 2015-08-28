//
//  ArticleList.h
//  spires
//
//  Created by Yuji on 08/10/15.
//  Copyright 2008 Y. Tachikawa. All rights reserved.
//

@import CoreData;
#if TARGET_OS_IPHONE
@import UIKit;
#else
@import Cocoa;
#endif

@class Article;

@interface ArticleList :  NSManagedObject  
{
}

@property  NSString* name;
@property  ArticleList* parent;
@property  NSSet* children;
@property  NSSet* articles;
@property  NSString* searchString;
@property  NSArray* sortDescriptors; // Transformable attribute.
#if TARGET_OS_IPHONE
@property (readonly) UIImage* icon;
@property (readonly) UIBarButtonItem*barButtonItem;
#else
@property (readonly) NSImage* icon;
@property (readonly) NSButtonCell* button;
#endif
@property (readonly) NSString* placeholderForSearchField;
@property  NSNumber* positionInView;
@property (readonly) BOOL searchStringEnabled;
@property (readonly) NSIndexPath*indexPath;
-(void)reload;
+(void)createStandardArticleLists;
+(void)rearrangePositionInView;
+(NSArray*)articleListsInArticleList:(ArticleList*)al;
@end

@interface ArticleList (CoreDataGeneratedAccessors)
- (void)addArticlesObject:(Article *)value;
- (void)removeArticlesObject:(Article *)value;
- (void)addArticles:(NSSet *)value;
- (void)removeArticles:(NSSet *)value;

@end

