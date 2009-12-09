//
//  TeXWatcherController.m
//  spires
//
//  Created by Yuji on 6/29/09.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import "TeXWatcherController.h"
#import "DirWatcher.h"
#import "DropAcceptingTextField.h"
#import "TeXBibGenerationOperation.h"
#import "MOC.h"

@interface TeXWatcherController ()
-(void)bibtexOutput:(NSNotification*)aNotification;
@end

static TeXWatcherController*_shared;
@implementation TeXWatcherController
+(TeXWatcherController*)sharedController
{
    return _shared;
}
-(TeXWatcherController*)init
{
    self=[super initWithWindowNibName:@"TeXWatcher"];
    if(!_shared)_shared=self;
    return self;
}
-(void)addToLog:(NSString*)s
{
    [tv setString:[[tv string] stringByAppendingString:s]];
    [tv scrollRangeToVisible:NSMakeRange([[tv string] length]-1,1)];
//    NSLog(@"bib:%@",s);
}
-(void)updateParentsFor:(NSString*)texFullPath
{
    NSDictionary*dict=[TeXBibGenerationOperation infoForTeXFile:texFullPath];
    NSArray*inputs=[dict objectForKey:@"inputs"];
    if(inputs && [inputs count]>0){
	[self addToLog:[NSString stringWithFormat:@"%@ includes %@\n",[texFullPath lastPathComponent],[inputs componentsJoinedByString:@", "]]];
	for(NSString*i in inputs){
	    if(![i hasSuffix:@".tex"]){
		i=[i stringByAppendingString:@".tex"];
	    }
	    i=[[texFullPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:i];
	    [parents setObject:texFullPath forKey:i];
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
-(void)setPathToWatch:(NSString*)path
{
    NSString* oldPath=self.pathToWatch;
    if(oldPath && ![oldPath isEqualToString:@""]){
	[self addToLog:[NSString stringWithFormat:@"stopped to watch %@\n",self.pathToWatch]];
    }
    if(path && ![path isEqualToString:@""]){
	NSString*fullPath=[path stringByExpandingTildeInPath];
	dw=[[DirWatcher alloc] initWithPath:fullPath delegate:self];
	[self addToLog:[NSString stringWithFormat:@"start to watch %@\n",fullPath]];
	[self prepareParentsForDirectory:fullPath];
	[[NSUserDefaults standardUserDefaults] setObject:path
						  forKey:@"watchDir"];
    }else{
	[[NSUserDefaults standardUserDefaults] setObject:@""
						  forKey:@"watchDir"];	
    }
}
-(NSString*)pathToWatch
{
    NSString* path=[[NSUserDefaults standardUserDefaults]stringForKey:@"watchDir"];
    if(path && ![path isEqualToString:@""]){
	return path;
    }else{
	return nil;
    }
}
-(void)startWatching:(NSString*)path
{
    self.pathToWatch=[path stringByAbbreviatingWithTildeInPath];
}
-(void)awakeFromNib
{
    [self startWatching:self.pathToWatch];
    [[NSNotificationCenter defaultCenter] addObserver:self  
					     selector:@selector(bibtexOutput:) 
						 name:NSFileHandleReadCompletionNotification
					       object:nil];
}
-(IBAction)clearFolderToWatch:(id)sender;
{
    [self startWatching:nil];
}
-(IBAction)setFolderToWatch:(id)sender
{
    NSOpenPanel*op=[NSOpenPanel openPanel];
    NSString*currentSetting=[self.pathToWatch stringByExpandingTildeInPath];
    [op setCanChooseFiles:NO];
    [op setCanChooseDirectories:YES];
    [op setCanCreateDirectories:YES];
    [op setMessage:@"Choose the folder to watch TeX files to generate bibliographies..."];
    [op setPrompt:@"Choose"];
    int res=[op runModalForDirectory:currentSetting file:nil types:nil];
    if(res==NSOKButton){
	NSString*nextSetting=[[op filenames] objectAtIndex:0];
	[self startWatching:nextSetting];
    }
}
-(void)runBibTeXForLog:(NSString*)file
{
    NSString*content=[NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:NULL];
    if(![content hasPrefix:@"This is"]){
	[self addToLog:[NSString stringWithFormat:@"%@ modified, but doesn't seem to be a .log for a TeX compilation\n",file]];	
	return;
    }
    [self addToLog:[NSString stringWithFormat:@"%@ modified, running bibtex\n",file]];
    NSString*fileTrunk=[[file lastPathComponent] stringByDeletingPathExtension];
    setenv("PATH",[[[NSUserDefaults standardUserDefaults] valueForKey:@"texBinaryPath"] UTF8String],1);
    NSTask*task=[[NSTask alloc] init];
    [task setLaunchPath:@"/usr/bin/env"];
    [task setCurrentDirectoryPath:[self.pathToWatch stringByExpandingTildeInPath]];
    [task setArguments:[NSArray arrayWithObjects:@"bibtex",fileTrunk,nil]];
    pipe=[NSPipe pipe];
    [[pipe fileHandleForReading] readInBackgroundAndNotify];
    [task setStandardOutput:pipe];
    [task setStandardError:pipe];
    [task launch];
}    
-(void)modifiedFileAtPath:(NSString*)file
{
    if([file hasSuffix:@".tex"]){
	NSString*foo=[NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:NULL];
	if([foo hasPrefix:@"%This file is auto"]){
	    return;
	}
	[self updateParentsFor:file];
	NSString*mainFile=[self lookUpAncestor:file];
	if([mainFile isEqualToString:file]){
	    [self addToLog:[NSString stringWithFormat:@"%@ modified, generating bib\n",file]];
	}else{
	    [self addToLog:[NSString stringWithFormat:@"%@ modified, which is a subfile of %@. Generating bib\n",file,mainFile]];	    
	}
	[[OperationQueues spiresQueue] addOperation:[[TeXBibGenerationOperation alloc] initWithTeXFile:mainFile
												andMOC:[MOC moc] byLookingUpWeb:YES]];
    }else if([file hasSuffix:@".log"]){
	[self performSelector:@selector(runBibTeXForLog:) withObject:file afterDelay:1];
    }
    
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

#pragma mark Drag-and-Drop support
- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender {
    NSPasteboard *pboard;
//    NSDragOperation sourceDragMask;
    
//    sourceDragMask = [sender draggingSourceOperationMask];
    pboard = [sender draggingPasteboard];
    
    if ( [[pboard types] containsObject:NSFilenamesPboardType] ) {
	return NSDragOperationLink;
    }
    return NSDragOperationNone;
}
- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender {
    NSPasteboard *pboard;
//    NSDragOperation sourceDragMask;
    
//    sourceDragMask = [sender draggingSourceOperationMask];
    pboard = [sender draggingPasteboard];
    
    if ( [[pboard types] containsObject:NSFilenamesPboardType] ) {
        NSArray *files = [pboard propertyListForType:NSFilenamesPboardType];
	NSString* file=[files objectAtIndex:0];
	BOOL isDirectory=NO;
	[[NSFileManager defaultManager] fileExistsAtPath:file isDirectory:&isDirectory];
	if(!isDirectory){
	    file=[file stringByDeletingLastPathComponent];
	}
	self.pathToWatch=[file stringByAbbreviatingWithTildeInPath];
	//	[self setValue:[file stringByAbbreviatingWithTildeInPath] forKey:@"value"];
    }
    return YES;
}
-(NSArray*)draggedTypesToRegister
{
    return [NSArray arrayWithObject:NSFilenamesPboardType];
}
@end
