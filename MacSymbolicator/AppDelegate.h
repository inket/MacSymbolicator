//
//  AppDelegate.h
//  MacSymbolicator
//
//  Created by inket on 7/9/13.
//  Copyright (c) 2013 inket. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <objc/runtime.h>
#import "NSApplication+FixedWindowMenu.h"
#import "MBDropZone.h"
#import "NSString+ShellExecution.h"
#import "NSString+RubyConvenience.h"
#import "CrashFile.h"
#import "DSYMFile.h"

@interface AppDelegate : NSObject <NSApplicationDelegate, MBDropZoneDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSButton* symbolicateButton;
@property (assign) IBOutlet NSTextField* differentUUIDLabel;
@property (assign) IBOutlet MBDropZone *crashReportDropZone;
@property (assign) IBOutlet MBDropZone *dSYMDropZone;

@property (assign) IBOutlet NSWindow* resultWindow;
@property (assign) IBOutlet NSTextView* resultTextView;

@property (strong) CrashFile* crashReport;
@property (strong) DSYMFile* dsymFile;

- (IBAction)symbolicate:(id)sender;

@end
