//
//  ImporterController.m
//  spires
//
//  Created by Yuji on 08/11/04.
//  Copyright 2008 Y. Tachikawa. All rights reserved.
//

#import "ImporterController.h"
#import "BatchImportOperation.h"
//#import "MOC.h"

@implementation ImporterController
-(ImporterController*)init; //WithAppDelegate:(spires_AppDelegate*)delegate
{
    [super initWithWindowNibName:@"Importer"];
//    appDelegate=delegate;
    return self;
}
-(void)import:(NSArray*)files
{
    [[self window] makeKeyAndOrderFront:self];
    [NSThread detachNewThreadSelector:@selector(mainWork:) toTarget:self withObject:files];
}
-(void)mainWork:(NSArray*)files
{
    total=[files count];
    for(current=0;current<total;current++){
	currentFile=[files objectAtIndex:current];
	NSError*error=nil;
	NSXMLDocument*doc=[[NSXMLDocument alloc] initWithContentsOfURL:[NSURL fileURLWithPath:currentFile]
							       options:0
								 error:&error];
	if(!doc){
	    NSLog(@"XML error:%@",error);
	    continue;
	}
	NSXMLElement* root=[doc rootElement];
	elements=[root elementsForName:@"document"];
	NSLog(@"%@ contains %d entries",currentFile,[elements count]);
	[self performSelectorOnMainThread:@selector(set:) withObject:self waitUntilDone:YES];
	int count=0;
	NSMutableArray*a=[NSMutableArray array];
	for(NSXMLElement* element in elements){
	    [a addObject:element];
	    count++;
	    if([a count]>100){
//		[appDelegate performSelectorOnMainThread:@selector(batchAddEntriesOfSPIRES:) withObject:a waitUntilDone:YES];
		[[OperationQueues sharedQueue] addOperation:[[BatchImportOperation alloc] initWithElements:a
											//	       andMOC:[MOC moc]
												      citedBy:nil 
												     refersTo:nil
											registerToArticleList:nil]];
		[self performSelectorOnMainThread:@selector(refreshProgressIndicator:) withObject:[NSNumber numberWithInt:count] waitUntilDone:YES];
		[a removeAllObjects];
	    }
	}
	if([a count]>0){
	    [[OperationQueues sharedQueue] addOperation:[[BatchImportOperation alloc] initWithElements:a
											//	   andMOC:[MOC moc]
												  citedBy:nil 
												 refersTo:nil
										    registerToArticleList:nil]];

	    [self performSelectorOnMainThread:@selector(refreshProgressIndicator:) withObject:[NSNumber numberWithInt:count] waitUntilDone:YES];
	}
	[[NSApp delegate] performSelectorOnMainThread:@selector(saveAction:) withObject:self waitUntilDone:YES];
	
    }
    [self performSelectorOnMainThread:@selector(closeWindow:) withObject:nil waitUntilDone:YES];
}
-(void)set:(id)sender
{
    [tf setStringValue:[NSString stringWithFormat:@"%d/%d : %d entries in %@",current+1,total,[elements count],[currentFile lastPathComponent]]];
    [pi setMinValue:0];
    [pi setMaxValue:[elements count]];    
}
-(void)refreshProgressIndicator:(NSNumber*)count
{
    [pi setDoubleValue:[count intValue]];
}
-(void)closeWindow:(id)sender
{
    [[self window] close];
}
@end
