//
//  MBCrashReporter.h
//
//  Created by inket on 23/7/13.
//  Copyright (c) 2013 inket. Licensed under GNU GPL v3.0. See LICENSE for details.
//  Attributes are appreciated.
//

#import <Foundation/Foundation.h>

@interface MBCrashReporter : NSObject {
    __strong NSString* _newCrashReport;
}

@property (strong) NSString* uploadURL;
@property (strong) NSString* email;

- (id)initWithUploadURL:(NSString*)uploadURL andDeveloperEmail:(NSString*)email;
- (BOOL)hasNewCrashReport;
- (void)sendCrashReport;
+ (BOOL)askToSendCrashReport;

@end
