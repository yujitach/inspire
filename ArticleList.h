//
//  ArticleList.h
//  spires
//
//  Created by Yuji on 08/10/15.
//  Copyright 2008 Y. Tachikawa. All rights reserved.
//

#import <CoreData/CoreData.h>

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
@property (readonly) NSImage* icon;
@property (readonly) NSButtonCell* button;
@property (readonly) NSString* placeholderForSearchField;
@property  NSNumber* positionInView;
@property (readonly) BOOL searchStringEnabled;
-(void)reload;

@end

@interface ArticleList (CoreDataGeneratedAccessors)
- (void)addArticlesObject:(Article *)value;
- (void)removeArticlesObject:(Article *)value;
- (void)addArticles:(NSSet *)value;
- (void)removeArticles:(NSSet *)value;

@end

