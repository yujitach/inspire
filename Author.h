//
//  Author.h
//  spires
//
//  Created by Yuji on 08/10/14.
//  Copyright 2008 Y. Tachikawa. All rights reserved.
//

#import <CoreData/CoreData.h>

@class Article;

@interface NSString (NameInitialAddition)
-(NSString*)abbreviatedFirstName;
@end

@interface Author :  NSManagedObject  
{
}

@property (retain) NSString * name;
@property (readonly)NSString* firstName;
@property (readonly)NSString* lastName;
@property (retain) NSSet* articles;
+(Author*)authorWithName:(NSString*)name inMOC:(NSManagedObjectContext*)moc;

@end

@interface Author (CoreDataGeneratedAccessors)
- (void)addArticlesObject:(Article *)value;
- (void)removeArticlesObject:(Article *)value;
- (void)addArticles:(NSSet *)value;
- (void)removeArticles:(NSSet *)value;

@end

