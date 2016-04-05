//
//  MBCrashReporter.h
//
//  Created by Mahdi Bchetnia on 23/7/13.
//  Copyright (c) 2013-2014 Mahdi Bchetnia. Licensed under GNU GPL v3.0. See LICENSE for details.
//  Attributes are appreciated.
//

@interface MBCrashReporter : NSObject {
    __strong NSString* _newCrashReport;
}

@property (strong) NSString* uploadURL;
@property (strong) NSString* email;

- (instancetype)initWithUploadURL:(NSString*)uploadURL andDeveloperEmail:(NSString*)email;
- (BOOL)hasNewCrashReport;
- (void)sendCrashReport;
+ (BOOL)askToSendCrashReport;

@end
