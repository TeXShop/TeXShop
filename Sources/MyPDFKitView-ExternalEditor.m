/*
 * TeXShop - TeX editor for Mac OS
 * Copyright (C) 2000-2019 Richard
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 */
 

#import "MyPDFKitView.h"
#import "globals.h"

@implementation MyPDFKitView (ExternalEditor)


- (void)doErrorWithLine: (NSInteger)myErrorLine andPath: (NSString *)myErrorPath
{
    if ([SUD boolForKey: OtherEditorSyncKey])
        [self sendLineToOtherEditor: myErrorLine forPath: myErrorPath];
    else if ([SUD boolForKey: TextMateSyncKey])
        [self sendLineToTextMate: myErrorLine forPath: myErrorPath];
}


- (void)doExternalSync: (NSPoint)thePoint
{
    NSInteger               pageNumber;
    NSTask                  *task;
    NSURL                   *myFileURL;
    NSURL                   *myCurrentDirectoryURL;
    BOOL                    result;
    NSError                 *error;
    NSString                *filename, *sourcePath, *pdfPath;
    NSMutableDictionary     *environmentForTask;
    NSArray                 *args;
    NSString                *editorString;
    
// The synctex routine in TeXLive seems to be broken. Hence we call lower level code to parse the .sync file.
// Remove the next two lines if synctex is fixed.
    
    [self doNewExternalSync: thePoint];
    return;
    
    if (! [SUD boolForKey: TextMateSyncKey])
        return;
    
    editorString = @"'mate --line %{line} %{input}'";
    
    
    NSPoint windowPosition = thePoint;
    NSPoint kitPosition = [self convertPoint: windowPosition fromView:nil];
    PDFPage *thePage = [self pageForPoint: kitPosition nearest:YES];
    if (thePage == NULL)
        return;
    NSPoint viewPosition = [self convertPoint: kitPosition toPage: thePage];
    pageNumber = [[self document] indexForPage: thePage];
    pageNumber++;
    pdfPath = [[[self.myDocument.fileURL path] stringByDeletingPathExtension] stringByAppendingPathExtension:@"pdf"];
    // NSLog(pdfPath);
    
    NSString *page = [[NSNumber numberWithLong:pageNumber] stringValue];
    NSString *xnum = [[NSNumber numberWithLong:viewPosition.x] stringValue];
    NSString *ynum = [[NSNumber numberWithLong:viewPosition.y] stringValue];
    
    NSString *syncArg1 =  [page stringByAppendingString: @":"];
    NSString *syncArg2 = [syncArg1 stringByAppendingString: xnum];
    NSString *syncArg3 = [syncArg2 stringByAppendingString: @":"];
    NSString *syncArg4 = [syncArg3 stringByAppendingString: ynum];
    NSString *syncArg5 = [syncArg4 stringByAppendingString: @":"];
    NSString *syncArg = [syncArg5 stringByAppendingString: pdfPath];
    // NSLog(syncArg);
    
    if (externalSyncTask != nil)
    {
        if ([externalSyncTask isRunning])
            [externalSyncTask terminate];
        externalSyncTask = nil;
    }
    task =  [[NSTask alloc] init];
    externalSyncTask = task;
    
    environmentForTask = [NSMutableDictionary dictionaryWithDictionary:[[NSProcessInfo processInfo] environment]];
    [task setEnvironment: environmentForTask];
    args = [NSArray arrayWithObjects:@"edit", @"-o", syncArg, @"-x", [NSString stringWithFormat:@"%@ %@ %@ %@", @"/usr/local/bin/mate", @"--line", @"%{line}", @"%{input}"],
            nil];
    [task setArguments: args];
    // NSLog(args[0]);
    // NSLog(args[1]);
    // NSLog(args[2]);
    // NSLog(args[3]);
    // NSLog(args[4]);
    
    // usage: synctex edit -o page:x:y:file [-d directory] [-x editor-command] [-h offset:context]
    // file is in general the path of a pdf or dvi file.
    // It can be either absolute or relative to the current directory.
    //
     // -x editor-command
     // The editor-command is a printf like format string with following specifiers.
     // %{input} is the name specifier of the input document.
     // %{line} is the 0 based line number specifier. %{line+1} is the 1 based line number specifier.
    
    filename = [[SUD stringForKey: TetexBinPath] stringByAppendingPathComponent: @"synctex"];
    sourcePath = [pdfPath stringByDeletingLastPathComponent];
    // NSLog(sourcePath);
    
#ifdef HIGHSIERRAORHIGHER
    if (atLeastHighSierra) // && (task != self.indexTask))
    {
        myFileURL = [NSURL fileURLWithPath:filename isDirectory:NO];
        task.executableURL = myFileURL;
        myCurrentDirectoryURL = [NSURL fileURLWithPath:sourcePath isDirectory:YES];
        task.currentDirectoryURL = myCurrentDirectoryURL;
        result = [task launchAndReturnError:&error];
    }
    else
#endif
    {
        [task setLaunchPath: filename];
        [task setCurrentDirectoryPath: [sourcePath stringByDeletingLastPathComponent]];
        [task launch];
    }
    
}

- (void)allocateExternalSyncScanner
{
    NSString        *myFileName, *mySyncTeXFileName;
    const char      *fileString;
    
    myFileName = [[self.myDocument fileURL] path];
    if (! myFileName)
        return;
    mySyncTeXFileName = [[myFileName stringByDeletingPathExtension] stringByAppendingPathExtension: @"synctex"];
    if (! [[NSFileManager defaultManager] fileExistsAtPath: mySyncTeXFileName])
    {
        mySyncTeXFileName = [[myFileName stringByDeletingPathExtension] stringByAppendingPathExtension: @"synctex.gz"];
        if (! [[NSFileManager defaultManager] fileExistsAtPath: mySyncTeXFileName])
            return;
    }
    
    if (external_scanner != NULL)
        synctex_scanner_free(external_scanner);
    external_scanner = NULL;
    fileString = [myFileName cStringUsingEncoding:NSUTF8StringEncoding];
    external_scanner = synctex_scanner_new_with_output_file(fileString, NULL, 1);
}



- (void)doNewExternalSync: (NSPoint)thePoint
{
    if ((! [SUD boolForKey: TextMateSyncKey]) && (! [SUD boolForKey: OtherEditorSyncKey]))
        return;
    
    NSPoint windowPosition = thePoint;
    NSPoint kitPosition = [self convertPoint: windowPosition fromView:nil];
    PDFPage *thePage = [self pageForPoint: kitPosition nearest:YES];
    if (thePage == NULL)
        return;
    NSRect pageSize = [thePage boundsForBox: kPDFDisplayBoxMediaBox];
    NSPoint viewPosition = [self convertPoint: kitPosition toPage: thePage];
    NSInteger pageNumber = [[self document] indexForPage: thePage] + 1;
    CGFloat xCoordinate = viewPosition.x;
    CGFloat yOriginalCoordinate = viewPosition.y;
    CGFloat yCoordinate = pageSize.size.height - viewPosition.y;
    
    [self doExternalSyncTeXForPage: pageNumber x: xCoordinate y: yCoordinate yOriginal: yOriginalCoordinate];
    
}


- (void)doExternalSyncTeXForPage: (NSInteger)pageNumber x: (CGFloat)xPosition y: (CGFloat)yPosition yOriginal: (CGFloat)yOriginalPosition
{
    NSString        *myFileName, *mySyncTeXFileName;
    const char      *theFoundFileName;
    NSString        *foundFileName;
    NSInteger       line;
    BOOL            gotSomething;
    NSString        *newFile;
    
    line = 0;
    foundFileName = NULL;
    
    myFileName = [[self.myDocument fileURL] path];
    if (! myFileName)
        return;
    mySyncTeXFileName = [[myFileName stringByDeletingPathExtension] stringByAppendingPathExtension: @"synctex"];
    if (! [[NSFileManager defaultManager] fileExistsAtPath: mySyncTeXFileName])
    {
        mySyncTeXFileName = [[myFileName stringByDeletingPathExtension] stringByAppendingPathExtension: @"synctex.gz"];
        if (! [[NSFileManager defaultManager] fileExistsAtPath: mySyncTeXFileName])
            return;
    }
    
    // BEGINNING OF PARSE SYNCTEX INFO CODE
    [self allocateExternalSyncScanner];
    if (external_scanner == NULL)
        return;
    else {
        gotSomething = NO;
        if (synctex_edit_query(external_scanner, pageNumber, xPosition, yPosition) > 0) {
            gotSomething = YES;
            synctex_node_p node;
            while ((node = synctex_scanner_next_result(external_scanner)) != NULL) {
                theFoundFileName = synctex_scanner_get_name(external_scanner, synctex_node_tag(node));
                if (theFoundFileName == NULL)
                    return;
                foundFileName = [NSString stringWithCString: theFoundFileName encoding:NSUTF8StringEncoding];
                line = synctex_node_line(node);
                break; // FIXME: use more nodes?
            }
            
            if (! gotSomething)
                return;
        }
        
        if ([foundFileName isAbsolutePath])
            newFile = [foundFileName stringByStandardizingPath];
        else
            newFile = [[[[[self.myDocument fileURL] path] stringByDeletingLastPathComponent] stringByAppendingPathComponent: foundFileName] stringByStandardizingPath];
        
        if ([SUD boolForKey: OtherEditorSyncKey])
            [self sendLineToOtherEditor: line forPath: newFile];
        
        else if ([SUD boolForKey: TextMateSyncKey])
            [self sendLineToTextMate: line forPath: newFile];
    }
}





         
@end
