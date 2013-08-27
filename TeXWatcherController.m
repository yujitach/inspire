//
//  TeXWatcherController.m
//  spires
//
//  Created by Yuji on 6/29/09.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import "TeXWatcherController.h"
#import "DirWatcher.h"
#import "TeXBibGenerationOperation.h"
#import "MOC.h"

@interface TeXWatcherController ()
-(void)bibtexOutput:(NSNotification*)aNotification;
@end

@implementation TeXWatcherController
@synthesize image;
-(TeXWatcherController*)init
{
    self=[super initWithWindowNibName:@"TeXWatcher"];
    if(!ts){// might be already initiallized because [super init] might load the nib!
	ts=[[NSMutableAttributedString alloc] initWithString:@""];
    }
    self.pathToWatch=self.pathToWatch; // looks silly, but it loads from defaults the path to watch, and initiates the watch.
    [[NSNotificationCenter defaultCenter] addObserver:self  
					     selector:@selector(bibtexOutput:) 
						 name:NSFileHandleReadCompletionNotification
					       object:nil];    
    return self;
}
#pragma mark UI glues
-(void)addToLog:(NSString*)s
{
    NSColor*color=[NSColor blackColor];
    if([s rangeOfString:@"modified"].location!=NSNotFound){
	color=[NSColor colorWithCalibratedRed:0.665f green:0.052f blue:0.569f alpha:1.000f];
    }else if([s rangeOfString:@"watch"].location!=NSNotFound){
	color=[NSColor colorWithCalibratedRed:0.000f green:0.456f blue:0.000f alpha:1.000f];
    }
    NSAttributedString*as=[[NSAttributedString alloc] initWithString:s 
							  attributes:[NSDictionary dictionaryWithObject:color
												 forKey:NSForegroundColorAttributeName]
			   ];
    NSRange endRange;
    
    endRange.location = [ts length];
    endRange.length = 0;
    [ts replaceCharactersInRange:endRange withAttributedString:as];
    endRange.length = [as length];
    [tv scrollRangeToVisible:endRange];
}
-(void)awakeFromNib
{
    NSTextStorage*newts=[tv textStorage];
    if(ts){
	[newts replaceCharactersInRange:NSMakeRange(0,0) withAttributedString:ts];
    }
    ts=newts;
}

+(NSSet*)keyPathsForValuesAffectingMessage
{
    return [NSSet setWithObject:@"pathToWatch"];
}
-(NSString*)message
{
    if(self.pathToWatch){
	return @"Watching the folder...";
    }else{
	return nil;
    }
}
-(IBAction)clearFolderToWatch:(id)sender;
{
    self.pathToWatch=nil;
}

#pragma mark analysis of TeX files' mutual inclusion
-(void)updateParentsFor:(NSString*)texFullPath
{
    NSDictionary*dict=[TeXBibGenerationOperation infoForTeXFile:texFullPath];
    NSArray*inputs=[dict objectForKey:@"inputs"];
    if(inputs && [inputs count]>0){
	[self addToLog:[NSString stringWithFormat:@"%@ includes %@\n",[texFullPath lastPathComponent],[inputs componentsJoinedByString:@", "]]];
	for(__strong NSString*i in inputs){
	    if(![i hasSuffix:@".tex"]){
		i=[i stringByAppendingString:@".tex"];
	    }
	    i=[[texFullPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:i];
            if([[NSFileManager defaultManager] fileExistsAtPath:i]){
                [parents setObject:texFullPath forKey:i];                
            }
	}
    }
}
-(void)prepareParentsForDirectory:(NSString*)fullPath
{
    parents=[NSMutableDictionary dictionary];
    NSArray*contents=[[NSFileManager defaultManager] contentsOfDirectoryAtPath:fullPath error:NULL];
    for(NSString*file in contents){
	if(![file hasSuffix:@".tex"])
	    continue;
	NSString*texFullPath=[fullPath stringByAppendingPathComponent:file];
	[self updateParentsFor:texFullPath];
    }
}
-(NSString*)lookUpAncestor:(NSString*)file
{
    NSString*a=[parents objectForKey:file];
    if(a){
	return [self lookUpAncestor:a];
    }else{
	return file;
    }
}
#pragma mark @property pathToWatch
-(NSString*)folderOfURL:(NSURL*)url
{
    if(!url)
	return nil;
    NSString*file=[url path];
    if(!file)
	return nil;
    BOOL isDirectory=NO;
    [[NSFileManager defaultManager] fileExistsAtPath:file isDirectory:&isDirectory];
    if(!isDirectory){
	file=[file stringByDeletingLastPathComponent];
    }
    return file;
}
-(void)setPathToWatch:(NSURL*)url
{
    NSString*beforeDir=[self folderOfURL:self.pathToWatch];
    NSString*afterDir=[self folderOfURL:url];
    if(url){
	NSString*file=[url path];
	[[NSUserDefaults standardUserDefaults] setObject:file
						  forKey:@"watchDir"];
	self.image=[[NSWorkspace sharedWorkspace] iconForFile:file];
    }else{
	[[NSUserDefaults standardUserDefaults] setObject:@""
						  forKey:@"watchDir"];	
	self.image=[NSImage imageNamed:@"drop.png"];
    }
    
    if(beforeDir && ![beforeDir isEqualToString:afterDir]){
	[self addToLog:[NSString stringWithFormat:@"stopped to watch %@\n",beforeDir]];
	 dw=nil;
    }
    if(afterDir && !dw ){
	NSLog(@"start to watch %@",afterDir);
	[self addToLog:[NSString stringWithFormat:@"start to watch %@\n",afterDir]];
	dw=[[DirWatcher alloc] initWithPath:afterDir delegate:self];
	[self prepareParentsForDirectory:afterDir];	
    }
}
-(NSURL*)pathToWatch
{
    NSString* path=[[NSUserDefaults standardUserDefaults]stringForKey:@"watchDir"];
    if(path && ![path isEqualToString:@""]){
	return [NSURL fileURLWithPath:path];
    }else{
	return nil;
    }
}

#pragma mark bibtex handling

-(void)runBibTeXForLog:(NSString*)file
{
    NSString*content=[NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:NULL];
    if(!content){
        content=[NSString stringWithContentsOfFile:file encoding:NSISOLatin1StringEncoding error:NULL];
    }
    if(![content hasPrefix:@"This is"]){
	[self addToLog:[NSString stringWithFormat:@"%@ modified, but doesn't seem to be a .log for a TeX compilation\n",[file lastPathComponent]]];	
	return;
    }
    if([content rangeOfString:@"\n!"].location!=NSNotFound ||
       [content rangeOfString:@"\n?"].location!=NSNotFound 
       ){
	[self addToLog:[NSString stringWithFormat:@"%@ modified, but seems to contain TeX compilation error\n",[file lastPathComponent]]];	
	return;	
    }
    if([content rangeOfString:@"\nHere is how much"].location==NSNotFound){
	[self addToLog:[NSString stringWithFormat:@"%@ modified, but compilation seems to be still going on\n",[file lastPathComponent]]];	
	return;	
    }    
    [self addToLog:[NSString stringWithFormat:@"%@ modified, running bibtex\n",[file lastPathComponent]]];
    NSString*fileTrunk=[[file lastPathComponent] stringByDeletingPathExtension];
    setenv("PATH",[[[NSUserDefaults standardUserDefaults] valueForKey:@"texBinaryPath"] UTF8String],1);
    task=[[NSTask alloc] init];
    [task setLaunchPath:@"/usr/bin/env"];
    [task setCurrentDirectoryPath:[self folderOfURL:self.pathToWatch]];
    [task setArguments:[NSArray arrayWithObjects:@"bibtex",fileTrunk,nil]];
    pipe=[NSPipe pipe];
    [[pipe fileHandleForReading] readInBackgroundAndNotify];
    [task setStandardOutput:pipe];
    [task setStandardError:pipe];
    [task launch];
}
-(void)bibtexOutput:(NSNotification*)aNotification{
    NSFileHandle*fh=[aNotification object];
    if(![[pipe fileHandleForReading] isEqualTo: fh]){
	return;
    }
    NSData*d=[[aNotification userInfo] objectForKey:@"NSFileHandleNotificationDataItem"];
    if([d length]){
	[self addToLog:[[NSString alloc] initWithData:d  encoding:NSUTF8StringEncoding]];
        [fh readInBackgroundAndNotify];
    }else{
	pipe=nil;
    }
}

#pragma mark FSEvents delegate
-(void)modifiedFileAtPath:(NSString*)file
{
    if([file hasSuffix:@".tex"]){
	NSString*foo=[NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:NULL];
	if([foo hasPrefix:@"%This file is auto"]){
	    return;
	}
	[self updateParentsFor:file];
	self.pathToWatch=[NSURL fileURLWithPath:file];
	NSString*mainFile=[self lookUpAncestor:file];
	if([mainFile isEqualToString:file]){
	    [self addToLog:[NSString stringWithFormat:@"%@ modified, generating bib\n",[file lastPathComponent]]];
	}else{
	    [self addToLog:[NSString stringWithFormat:@"%@ modified, which is a subfile of %@. Generating bib\n",[file lastPathComponent],[mainFile lastPathComponent]]];	    
	}
	[[OperationQueues spiresQueue] addOperation:[[TeXBibGenerationOperation alloc] initWithTeXFile:mainFile
												andMOC:[MOC moc] 
											byLookingUpWeb:YES]];
    }else if([file hasSuffix:@".log"]){
	[self performSelector:@selector(runBibTeXForLog:) withObject:file afterDelay:1];
    }
    
}

#pragma mark Drag-and-Drop support for the image well
- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender {
    NSPasteboard *pboard=[sender draggingPasteboard];
    
    if ( [[pboard types] containsObject:NSFilenamesPboardType] ) {
	return NSDragOperationCopy;
    }
    return NSDragOperationNone;
}
- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender {
    NSPasteboard *pboard=[sender draggingPasteboard];
    
    if ( [[pboard types] containsObject:NSFilenamesPboardType] ) {
        NSArray *files = [pboard propertyListForType:NSFilenamesPboardType];
	NSString* file=[files objectAtIndex:0];
	self.pathToWatch=[NSURL fileURLWithPath:file];
    }
    return YES;
}
-(NSArray*)draggedTypesToRegister
{
    return [NSArray arrayWithObject:NSFilenamesPboardType];
}
@end
