// 
//  ArticleList.m
//  spires
//
//  Created by Yuji on 08/10/15.
//  Copyright 2008 Y. Tachikawa. All rights reserved.
//

#import "ArticleList.h"
#import "Article.h"
#import "MOC.h"
#import "AllArticleList.h"
#import "ArxivNewArticleList.h"
#import "CannedSearch.h"

@implementation ArticleList 

@dynamic name;
@dynamic articles;
@dynamic sortDescriptors;
@dynamic searchString;
@dynamic positionInView;
@dynamic parent;
@dynamic children;

-(void)reload
{
}
#if TARGET_OS_IPHONE
-(UIImage*)icon
{
    return nil;
}
-(UIBarButtonItem*)barButtonItem
{
    return nil;
}
#else
-(NSImage*)icon
{
    return nil;
}
-(NSButtonCell*)button
{
    return nil;
}
#endif
-(BOOL)searchStringEnabled
{
    return YES;
}
-(NSString*)placeholderForSearchField
{
    return @"";
}
-(NSIndexPath*)indexPath
{
    if(self.parent==nil){
        return [NSIndexPath indexPathWithIndex:[self.positionInView integerValue]/2];
    }
    return [self.parent.indexPath indexPathByAddingIndex:[self.positionInView integerValue]/2];
}
+(void)createStandardArticleLists
{
    BOOL needToSave=NO;
    
    if(![[NSUserDefaults standardUserDefaults]boolForKey:@"allArticleListPrepared"]){
        [[NSUserDefaults standardUserDefaults]setBool:YES forKey:@"allArticleListPrepared"];
        AllArticleList*all=[AllArticleList allArticleListInMOC:[MOC moc]];
        if(!all){
            //all=
            [AllArticleList allArticleList];
            needToSave=YES;
        }
    }
    
    
    if(![[NSUserDefaults standardUserDefaults]boolForKey:@"specialListPrepared"]){
        [[NSUserDefaults standardUserDefaults]setBool:YES forKey:@"specialListPrepared"];
        ArticleList*hepph=[ArxivNewArticleList createArXivNewArticleListWithName:@"hep-ph/new" inMOC:[MOC moc]];
        hepph.positionInView=@2;
        ArticleList*hepth=[ArxivNewArticleList createArXivNewArticleListWithName:@"hep-th/new" inMOC:[MOC moc]];
        hepth.positionInView=@4;
        needToSave=YES;
    }
    
    if(![[NSUserDefaults standardUserDefaults]boolForKey:@"flaggedListPrepared"]){
        [[NSUserDefaults standardUserDefaults]setBool:YES forKey:@"flaggedListPrepared"];
        CannedSearch*f=[CannedSearch createCannedSearchWithName:@"flagged" inMOC:[MOC moc]];
        f.searchString=@"f flagged";
        f.positionInView=@100;
        needToSave=YES;
    }
    if(![[NSUserDefaults standardUserDefaults]boolForKey:@"pdfListPrepared"]){
        [[NSUserDefaults standardUserDefaults]setBool:YES forKey:@"pdfListPrepared"];
        CannedSearch*f=[CannedSearch createCannedSearchWithName:@"has pdf" inMOC:[MOC moc]];
        f.searchString=@"f pdf";
        f.positionInView=@200;
        needToSave=YES;
    }
    if(needToSave){
        NSError*error=nil;
        BOOL success=[[MOC moc] save:&error]; // ensure the lists can be accessed from the second MOC
        if(!success){
            [[MOC sharedMOCManager] presentMOCSaveError:error];
        }
    }
}

+(void)updatePositionInViewFor:(ArticleList*)al to:(NSInteger)i
{
    if([al.positionInView integerValue]!=i){
        al.positionInView=@(i);
    }
}

+(NSArray*)articleListsInArticleList:(ArticleList*)parent
{
    NSArray*array=nil;
    NSSortDescriptor*desc=[[NSSortDescriptor alloc] initWithKey:@"positionInView" ascending:YES];
    if(!parent){
        NSEntityDescription* entity=[NSEntityDescription entityForName:@"ArticleList" inManagedObjectContext:[MOC moc]];
        NSFetchRequest* request=[[NSFetchRequest alloc] init];
        [request setEntity:entity];
        NSPredicate*pred=[NSPredicate predicateWithFormat:@"parent == nil"];
        [request setPredicate:pred];
        [request setSortDescriptors:@[desc]];
        
        NSError*error=nil;
        array=[[MOC moc] executeFetchRequest:request error:&error];
    }else{
        array=[parent.children allObjects];
        array=[array sortedArrayUsingDescriptors:@[desc]];
    }
    return array;
}
+(void)rearrangePositionInViewForArticleListsInArticleList:(ArticleList*)parent
{
    NSArray*array=[self articleListsInArticleList:parent];
    /*    for(ArticleList*aa in array){
     NSLog(@"%@",aa.name);
     }*/
    //    NSLog(@"rearranges:%@",parent.name);
    NSMutableArray* a=[NSMutableArray array];
    NSMutableArray* b=[NSMutableArray array];
    ArticleList* o=nil;
    //NSLog(@"articleLists:%@",all);
    for(ArticleList*al in array){
        //	NSLog(@"al:%@",al.name);
        if([al isKindOfClass:[AllArticleList class]]){
            o=al;
        }else if([al isKindOfClass:[ArxivNewArticleList class]]){
            [a addObject:al];
        }else if(![al isKindOfClass:[AllArticleList class]]){
            [b addObject:al];
        }
    }
    int i=0;
    if(o){
        [self updatePositionInViewFor:o to:2*i];
        i++;
    }
    for(ArticleList*x in a){
        [self updatePositionInViewFor:x to:2*i];
        //	NSLog(@"al:%d:%@ ",i,x.name);
        i++;
    }
    for(ArticleList*x in b){
        [self updatePositionInViewFor:x to:2*i];
        //	NSLog(@"al:%d:%@ ",i,x.name);
        i++;
    }
    //   [articleListController didChangeArrangementCriteria];
    /*    for(ArticleList*i in [articleListController arrangedObjects]){
     NSLog(@"%@ position:%@",i.name,i.positionInView);
     }*/
}
+(void)rearrangePositionInView
{
    [[MOC moc] performBlock:^{
        [self rearrangePositionInViewForArticleListsInArticleList:nil];
        NSEntityDescription* entity=[NSEntityDescription entityForName:@"ArticleFolder" inManagedObjectContext:[MOC moc]];
        NSFetchRequest* request=[[NSFetchRequest alloc] init];
        [request setEntity:entity];
        NSPredicate*pred=[NSPredicate predicateWithValue:YES];
        [request setPredicate:pred];
        NSError*error=nil;
        NSArray*array=[[MOC moc] executeFetchRequest:request error:&error];
        for(ArticleList*al in array){
            [self rearrangePositionInViewForArticleListsInArticleList:al];
        }
    }];
}
@end
