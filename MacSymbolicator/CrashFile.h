//
//  CrashFile.h
//  MacSymbolicator
//
//  Created by inket on 23/12/13.
//  Copyright (c) 2013 inket. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSString+RubyConvenience.h"

@interface CrashFile : NSObject

@property (strong) NSString* fileName;
@property (strong) NSString* processName;
@property (strong) NSString* responsible;
@property (strong) NSString* bundleIdentifier;
@property (strong) NSString* version;
@property (strong) NSString* buildVersion;
@property (strong) NSString* uuid;

@property (strong) NSString* symbolicatedContent;

+ (instancetype)crashWithFile:(NSString*)file;

@end
