//
//  MBCrashReporter.m
//
//  Created by Mahdi Bchetnia on 23/7/13.
//  Copyright (c) 2013-2014 Mahdi Bchetnia. Licensed under GNU GPL v3.0. See LICENSE for details.
//  Attributes are appreciated.
//

#import "MBCrashReporter.h"

@implementation MBCrashReporter

- (id)initWithUploadURL:(NSString*)uploadURL andDeveloperEmail:(NSString*)email {
    self = [super init];
    
    if (self)
    {
        _uploadURL = uploadURL;
        _email = email;
    }
    
    return self;
}

- (BOOL)hasNewCrashReport {
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    NSMutableArray* crashHistory = [[defaults arrayForKey:@"crashHistory"] mutableCopy];
    
    NSFileManager* fileManager = [NSFileManager defaultManager];
    NSError* error = nil;
    NSArray* files = [fileManager contentsOfDirectoryAtPath:[@"~/Library/Logs/DiagnosticReports/" stringByExpandingTildeInPath] error:&error];
    
    if (error)
    {
        NSLog(@"%@", error);
        return NO;
    }
    
    NSMutableArray* newCrashes = [NSMutableArray array];
    NSString* appName = [[NSRunningApplication currentApplication] localizedName];
    for (NSString* crashReport in files) {
        if ([crashReport hasPrefix:[NSString stringWithFormat:@"%@_", appName]] && ![crashHistory containsObject:crashReport])
            [newCrashes addObject:crashReport];
    }
    
    if ([newCrashes count] > 0)
    {
        if (!crashHistory) crashHistory = [NSMutableArray array];
        [crashHistory addObjectsFromArray:newCrashes];
        [defaults setObject:crashHistory forKey:@"crashHistory"];
        [defaults synchronize];
        
        NSArray* crashes = [newCrashes sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
        NSString* latestCrash = [crashes lastObject];
        
        _newCrashReport = latestCrash;
        
        return YES;
    }
    
    return NO;
}

- (void)sendCrashReport {
    if (!_newCrashReport) return;
    
    NSString* crashReportPath = [[NSString stringWithFormat:@"~/Library/Logs/DiagnosticReports/%@", _newCrashReport] stringByExpandingTildeInPath];
    
    NSWindow* sendingWindow = [MBCrashReporter reportWindow];
    
    NSURLResponse* response = nil;
    NSError* error = nil;
    [MBCrashReporter uploadFile:crashReportPath toURL:_uploadURL returningResponse:&response error:&error];
    
    [sendingWindow orderOut:nil];
    sendingWindow = nil;
    
    if (error || [(NSHTTPURLResponse*)response statusCode] != 200)
    {
        NSLog(@"Couldn't send the crash report '%@'. Please send it to %@ if possible.", crashReportPath, _email ? _email : @"the developer");
        if (error) NSLog(@"%@", error);
    }
    else
        NSLog(@"Crash report %@ sent successfully.", [crashReportPath lastPathComponent]);
}

+ (BOOL)rememberSettingIsSet {
    return [[[[NSUserDefaults standardUserDefaults] dictionaryRepresentation] allKeys] containsObject:@"MBCRRememberChoice"];
}

+ (BOOL)rememberedSetting {
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"MBCRRememberChoice"];
}

+ (BOOL)askToSendCrashReport {
    if ([MBCrashReporter rememberSettingIsSet])
        return [MBCrashReporter rememberedSetting];
    
    NSString* appName = [[NSRunningApplication currentApplication] localizedName];

    NSString* messageText = @"Send crash report to the developer ?";
    NSString* informativeText = [NSString stringWithFormat:@"It seems %@ crashed the last time it ran.\nIt is recommended that you send the (anonymous) crash report so that the developer can identify the issue and fix it as soon as possible.", appName];
    
    NSAlert* alert = [NSAlert alertWithMessageText:messageText defaultButton:nil alternateButton:@"Cancel" otherButton:nil informativeTextWithFormat:informativeText, nil];
    
    [alert setShowsSuppressionButton:YES];
    [[alert suppressionButton] setTitle:@"Remember my choice"];
    
    BOOL alertResult = ([alert runModal] == NSAlertDefaultReturn);
    
    if ([[alert suppressionButton] state] == NSOnState)
    {
        [[NSUserDefaults standardUserDefaults] setBool:alertResult forKey:@"MBCRRememberChoice"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    return alertResult;
}

+ (NSData*)uploadFile:(NSString*)path toURL:(NSString*)url returningResponse:(NSURLResponse**)response error:(NSError**)error {
    NSData* fileData = [[NSData alloc] initWithContentsOfFile:path];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:url]];
    [request setHTTPMethod:@"POST"];
    
    NSString *boundary = @"0xKhTmLbOuNdArY";
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@",boundary];
    [request addValue:contentType forHTTPHeaderField: @"Content-Type"];
    
    NSMutableData *body = [NSMutableData data];
    [body appendData:[[NSString stringWithFormat:@"--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"file\"; filename=\"%@\"\r\n", [path lastPathComponent]] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[@"Content-Type: application/octet-stream\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:fileData];
    [body appendData:[[NSString stringWithFormat:@"r\n--%@--\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];

    [request setHTTPBody:body];
    
    return [NSURLConnection sendSynchronousRequest:request returningResponse:response error:error];
}

+ (NSWindow*)reportWindow {
    NSWindow* window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 230, 60) styleMask:NSTitledWindowMask backing:NSBackingStoreBuffered defer:NO];
    [window center];
    [window setTitle:@"Crash Reporter"];
    NSTextField* label = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 20, 210, 20)];
    [label setAlignment:NSCenterTextAlignment];
    [label setStringValue:@"Sending crash report..."];
    [label setBezeled:NO];
    [label setDrawsBackground:NO];
    [label setEditable:NO];
    [label setSelectable:NO];
    [[window contentView] addSubview:label];
    NSProgressIndicator* progressIndicator = [[NSProgressIndicator alloc] initWithFrame:NSMakeRect(180, 22, 18, 18)];
    [progressIndicator setIndeterminate:YES];
    [progressIndicator setStyle:NSProgressIndicatorSpinningStyle];
    [progressIndicator startAnimation:nil];
    [[window contentView] addSubview:progressIndicator];
    [window makeKeyAndOrderFront:nil];
    
    return window;
}

@end
