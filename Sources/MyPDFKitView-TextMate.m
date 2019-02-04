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

@implementation MyPDFKitView (TextMate)

- (void)sendLineToTextMate: (NSInteger)aLine forPath: (NSString *)aPath
{
    NSTask                  *task;
    NSMutableDictionary     *environmentForTask;
    NSArray                 *args;
    NSString                *filename, *sourcePath;
    NSURL                   *myFileURL, *myCurrentDirectoryURL;
    BOOL                    result;
    NSError                 *error;
    
    if (textMateTask != nil)
    {
        if ([textMateTask isRunning])
            [textMateTask terminate];
        textMateTask = nil;
    }
     task =  [[NSTask alloc] init];
    textMateTask = task;
    
    NSNumber *aNumber = [NSNumber numberWithLong: aLine];
    
    environmentForTask = [NSMutableDictionary dictionaryWithDictionary:[[NSProcessInfo processInfo] environment]];
    [task setEnvironment: environmentForTask];
    args = [NSArray arrayWithObjects:@"--line", [aNumber stringValue], aPath, nil];
    [task setArguments: args];
    
    filename = @"/usr/local/bin/mate";
    sourcePath = [aPath stringByDeletingLastPathComponent];
    
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
        [task setCurrentDirectoryPath: sourcePath];
        [task launch];
    }

}

- (void)sendLineToOtherEditor: (NSInteger)aLine forPath: (NSString *)aPath
{
    NSTask                  *task;
    NSMutableDictionary     *environmentForTask;
    NSArray                 *args;
    NSString                *filename, *sourcePath;
    NSURL                   *myFileURL, *myCurrentDirectoryURL;
    BOOL                    result;
    NSError                 *error;
    
    if (otherEditorTask != nil)
    {
        if ([otherEditorTask isRunning])
            [otherEditorTask terminate];
        otherEditorTask = nil;
    }
    task =  [[NSTask alloc] init];
    otherEditorTask = task;
    
    NSNumber *aNumber = [NSNumber numberWithLong: aLine];
    
    environmentForTask = [NSMutableDictionary dictionaryWithDictionary:[[NSProcessInfo processInfo] environment]];
    [task setEnvironment: environmentForTask];
    args = [NSArray arrayWithObjects: [aNumber stringValue], aPath, nil];
    [task setArguments: args];
    
    filename = @"/usr/local/bin/othereditor";
    sourcePath = [aPath stringByDeletingLastPathComponent];
    
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
        [task setCurrentDirectoryPath: sourcePath];
        [task launch];
    }
    
}

         
@end
