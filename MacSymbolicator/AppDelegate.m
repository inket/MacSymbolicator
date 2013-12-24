//
//  AppDelegate.m
//  MacSymbolicator
//
//  Created by inket on 7/9/13.
//  Copyright (c) 2013 inket. All rights reserved.
//

#import "AppDelegate.h"
#import "MBCrashReporter.h"

@implementation AppDelegate

- (void)awakeFromNib {
    [_crashReportDropZone setText:@"Drop Crash Report"];
    [_crashReportDropZone setFileType:@".crash"];
    [_crashReportDropZone setDelegate:self];
    
    [_dSYMDropZone setText:@"Drop App DSYM"];
    [_dSYMDropZone setDetailText:@"(if not found automatically)"];
    [_dSYMDropZone setFileType:@".dSYM"];
    [_dSYMDropZone setDelegate:self];
}

- (BOOL)application:(NSApplication *)sender openFile:(NSString *)filename {
    [_crashReportDropZone setFile:filename];
    CrashFile* f = [CrashFile crashWithFile:filename];
    [self setCrashReport:f];
    
    [self startSearchForDSYM];
    [self symbolicate:nil];
        
    if (![_resultWindow isKeyWindow]) // if symbolication failed / dsym not found
        [_window makeKeyAndOrderFront:nil];
    
    return YES;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    MBCrashReporter* crashReporter = [[MBCrashReporter alloc] initWithUploadURL:@"http://inket.herokuapp.com/crashreporter/MacSymbolicator" andDeveloperEmail:@"inket@outlook.com"];
    
    if ([crashReporter hasNewCrashReport] && [MBCrashReporter askToSendCrashReport])
        [crashReporter sendCrashReport];
    
    if ([_resultWindow isKeyWindow])
        [NSApp addWindowsItem:_window title:@"MacSymbolicator" filename:NO];
    else
        [_window makeKeyAndOrderFront:nil];
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)sender hasVisibleWindows:(BOOL)flag {
    [_window makeKeyAndOrderFront:nil];
    
    return YES;
}

- (void)startSearchForDSYM {
    [_dSYMDropZone setDetailText:@"Searching…"];
    NSString* command = [NSString stringWithFormat:@"mdfind '%@'", [_crashReport uuid] ];
    NSArray* files = [[command runAsCommand] componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    
    for (NSString* file in files) {
        if ([[file lowercaseString] hasSuffix:@".dsym"])
        {
            [_dSYMDropZone setFile:file];
            [_dSYMDropZone setDetailText:file];
            DSYMFile* f = [DSYMFile dsymWithFile:file];
            [self setDsymFile:f];
            
            [_differentUUIDLabel setHidden:[_crashReport.uuid isEqualToString:_dsymFile.uuid]];

            break;
        }
    }
    
    if (![_dSYMDropZone file])
        [_dSYMDropZone setDetailText:@""];
}

- (IBAction)symbolicate:(id)sender {
    if (![_crashReportDropZone file] || ![_dSYMDropZone file]) return;
    if (![_crashReport.uuid isEqualToString:_dsymFile.uuid]) return;
    
    NSString* scriptPath = [[NSBundle mainBundle] pathForResource:@"symbolicate" ofType:@"rb"];
    if (!scriptPath) return;

    NSString* command = [NSString stringWithFormat:@"ruby '%@' '%@' '%@' -q", scriptPath, [_crashReportDropZone file], [_dSYMDropZone file]];
    NSString* result = [command runAsCommand];
    
    if ([result hasPrefix:@"Process:"])
    {
        [_crashReport setSymbolicatedContent:result];
        [_resultWindow setTitle:[NSString stringWithFormat:@"Symbolicated %@", [_crashReport fileName]]];
        [_resultTextView setString:result];
        [_resultWindow makeKeyAndOrderFront:nil];
    }
    else
        [[NSAlert alertWithMessageText:@"Symbolication Error" defaultButton:nil alternateButton:nil otherButton:nil informativeTextWithFormat:@"%@", result] runModal];
}

- (void)dropZone:(MBDropZone*)dropZone receivedFile:(NSString*)file {
    if (dropZone == _crashReportDropZone)
    {
        CrashFile* f = [CrashFile crashWithFile:file];
        [self setCrashReport:f];
    }
    
    if (dropZone == _dSYMDropZone)
    {
        [_dSYMDropZone setDetailText:file];
        DSYMFile* f = [DSYMFile dsymWithFile:file];
        [self setDsymFile:f];
    }
    
    if (dropZone == _crashReportDropZone && ![_dSYMDropZone file])
        [self startSearchForDSYM];
    else if ([_crashReportDropZone file] && [_dSYMDropZone file])
    {
        [_differentUUIDLabel setHidden:[_crashReport.uuid isEqualToString:_dsymFile.uuid]];
        if ([_crashReport.uuid isEqualToString:_dsymFile.uuid])
            [_symbolicateButton performClick:nil];
    }
}

@end
