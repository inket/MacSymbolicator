//
//  AppDelegate.h
//  MacSymbolicator
//
//  Created by inket on 7/9/13.
//  Copyright (c) 2013 inket. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MBDropZone.h"
#import "NSString+ShellExecution.h"
#import "NSString+RubyConvenience.h"
#import "CrashFile.h"
#import "DSYMFile.h"
#import "MBCrashReporter.h"

@interface AppDelegate : NSObject <NSApplicationDelegate, MBDropZoneDelegate>

@property (strong) IBOutlet NSWindow *window;
@property (strong) IBOutlet NSButton* symbolicateButton;
@property (strong) IBOutlet NSTextField* differentUUIDLabel;
@property (strong) IBOutlet MBDropZone *crashReportDropZone;
@property (strong) IBOutlet MBDropZone *dSYMDropZone;

@property (strong) IBOutlet NSWindow* resultWindow;
@property (strong) IBOutlet NSTextView* resultTextView;

@property (strong) CrashFile* crashReport;
@property (strong) DSYMFile* dsymFile;

- (IBAction)symbolicate:(id)sender;

@end
