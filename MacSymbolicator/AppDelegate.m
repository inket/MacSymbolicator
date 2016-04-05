//
//  AppDelegate.m
//  MacSymbolicator
//
//  Created by inket on 7/9/13.
//  Copyright (c) 2013 inket. All rights reserved.
//

#import "AppDelegate.h"
#import "MBDropZone.h"
#import "NSString+ShellExecution.h"
#import "NSString+RubyConvenience.h"
#import "CrashFile.h"
#import "DSYMFile.h"
#import "MBCrashReporter.h"
#import <Sparkle/Sparkle.h>

@interface AppDelegate() <MBDropZoneDelegate>

@property (nonatomic, weak) IBOutlet NSButton* symbolicateButton;
@property (nonatomic, weak) IBOutlet NSTextField* differentUUIDLabel;
@property (nonatomic, weak) IBOutlet MBDropZone *crashReportDropZone;
@property (nonatomic, weak) IBOutlet MBDropZone *dSYMDropZone;

@property (nonatomic, strong) IBOutlet NSWindow* resultWindow;
@property (nonatomic, strong) IBOutlet NSTextView* resultTextView;

@property (nonatomic, strong) CrashFile* crashReport;
@property (nonatomic, strong) DSYMFile* dsymFile;

@property (nonatomic, strong) IBOutlet SUUpdater *updater;

@end

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
    
    return YES;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    MBCrashReporter* crashReporter = [[MBCrashReporter alloc] initWithUploadURL:@"http://inket.herokuapp.com/crashreporter/MacSymbolicator" andDeveloperEmail:@"inket@outlook.com"];
    
    if ([crashReporter hasNewCrashReport] && [MBCrashReporter askToSendCrashReport])
        [crashReporter performSelectorOnMainThread:@selector(sendCrashReport) withObject:nil waitUntilDone:NO];
    
    if ([_resultWindow isKeyWindow])
        [NSApp addWindowsItem:_window title:@"MacSymbolicator" filename:NO];
    else
        [_window makeKeyAndOrderFront:nil];
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)sender hasVisibleWindows:(BOOL)flag {
    if ([_resultWindow isKeyWindow])
    {
        [_window makeKeyAndOrderFront:nil];
        [_resultWindow makeKeyAndOrderFront:nil];
    }
    else
        [_window makeKeyAndOrderFront:nil];
    
    return YES;
}

- (NSString*)searchSpotlightByUUIDLookingFor:(NSString*)uuid {
    NSString* command = [NSString stringWithFormat:@"mdfind '%@'", uuid];
    NSArray* files = [[command runAsCommand] componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    
    for (NSString* file in files) {
        if ([[file lowercaseString] hasSuffix:@".dsym"])
            return file;
    }
    
    return nil;
}

- (NSString*)searchSpotlightByDSYMLookingForUUID:(NSString*)uuid {
    NSString* allDSYMs = [@"mdfind 'kMDItemFSName == *.dSYM'" runAsCommand];
    NSArray* dsymFiles = [allDSYMs componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    
    for (NSString* file in dsymFiles) {
        NSString* dwarfDumpOutput = [[NSString stringWithFormat:@"dwarfdump --uuid '%@'", file] runAsCommand];
        NSString* foundUUID = [[[[dwarfDumpOutput strip] scan:@"/UUID: (.*) \\(/mi"] firstObject] firstObject];
        
        if ([uuid isEqualToString:foundUUID])
            return file;
    }
    
    return nil;
}

- (NSString*)searchArchivesFolderByDSYMLookingForUUID:(NSString*)uuid {
    NSString* allDSYMs = [@"find ~/Library/Developer/Xcode/Archives/ -name *.dSYM" runAsCommand];
    NSArray* dsymFiles = [allDSYMs componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    
    if ([[dsymFiles firstObject] hasSuffix:@"find:"]) // `find` error
        return nil;
    
    for (NSString* file in dsymFiles) {
        NSString* dwarfDumpOutput = [[NSString stringWithFormat:@"dwarfdump --uuid '%@'", file] runAsCommand];
        NSString* foundUUID = [[[[dwarfDumpOutput strip] scan:@"/UUID: (.*) \\(/mi"] firstObject] firstObject];
        
        if ([uuid isEqualToString:foundUUID])
            return file;
    }
    
    return nil;
}

- (void)startSearchForDSYM {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [_dSYMDropZone setDetailText:@"Searching…"];

        NSString* uuidLookedFor = [_crashReport uuid];
        
        NSString* file = [self searchSpotlightByUUIDLookingFor:uuidLookedFor];
        if (!file) file = [self searchSpotlightByDSYMLookingForUUID:uuidLookedFor];
        if (!file) file = [self searchArchivesFolderByDSYMLookingForUUID:uuidLookedFor];
        
        if (file)
        {
            [_dSYMDropZone setFile:file];
            [_dSYMDropZone setDetailText:file];
            DSYMFile* f = [DSYMFile dsymWithFile:file];
            [self setDsymFile:f];
            
            [_differentUUIDLabel setHidden:[_crashReport.uuid isEqualToString:_dsymFile.uuid]];
        }
        else
        {
            [_dSYMDropZone setDetailText:@""];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self symbolicate:nil];
            
            if (![_resultWindow isKeyWindow]) // if symbolication failed / dsym not found
                [_window makeKeyAndOrderFront:nil];
        });
    });
}

- (IBAction)symbolicate:(id)sender {
    if (![_crashReportDropZone file] || ![_dSYMDropZone file]) return;
    
    [_symbolicateButton setTitle:@"Symbolicating…"];
    [_symbolicateButton setEnabled:NO];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString* scriptPath = [[NSBundle mainBundle] pathForResource:@"symbolicate" ofType:@"rb"];
        if (!scriptPath) return;
        
        NSString* command = [NSString stringWithFormat:@"ruby '%@' '%@' '%@'", scriptPath, [_crashReportDropZone file], [_dSYMDropZone file]];
        NSString* result = [command runAsCommand];
        
        if ([result hasPrefix:@"MacSymbolicator"])
        {
            [_crashReport setSymbolicatedContent:result];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([result hasPrefix:@"MacSymbolicator"])
            {
                [_resultWindow setTitle:[NSString stringWithFormat:@"Symbolicated %@", [_crashReport fileName]]];
                [_resultTextView setString:result];
                [_resultWindow makeKeyAndOrderFront:nil];
            }
            else
                [[NSAlert alertWithMessageText:@"Symbolication Error"
                                 defaultButton:nil
                               alternateButton:nil
                                   otherButton:nil
                     informativeTextWithFormat:@"%@", result
                  ] runModal];
            
            [_symbolicateButton setTitle:@"Symbolicate"];
            [_symbolicateButton setEnabled:YES];
        });
    });
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
        BOOL sameUUID = [_crashReport.uuid isEqualToString:_dsymFile.uuid];
        [_differentUUIDLabel setHidden:sameUUID];
        
        if (sameUUID)
        {
            [_symbolicateButton setTitle:@"Symbolicate"];
            [_symbolicateButton performClick:nil];
        }
        else
            [_symbolicateButton setTitle:@"Symbolicate Anyway"];
    }
}

@end
