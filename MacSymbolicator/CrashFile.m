//
//  CrashFile.m
//  MacSymbolicator
//
//  Created by inket on 23/12/13.
//  Copyright (c) 2013 inket. All rights reserved.
//

#import "CrashFile.h"

@implementation CrashFile

+ (instancetype)crashWithFile:(NSString*)file {
    return [[CrashFile alloc] initWithFile:file];
}

- (instancetype)initWithFile:(NSString*)file {
    self = [super init];
    
    if (self)
    {
        NSError* error = nil;
        NSString* content = [[NSString alloc] initWithContentsOfFile:file encoding:NSUTF8StringEncoding error:&error];
        
        if (error || [[content stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:@""])
        {
            NSLog(@"%@", error);
            return nil;
        }
        
        self.fileName = [file lastPathComponent];
        self.processName = [[[[content scan:@"/^Process:\\s+(.+?)\\[/i"] firstObject] firstObject] strip];
        self.bundleIdentifier = [[[[content scan:@"/^Identifier:\\s+(.+?)$/i"] firstObject] firstObject] strip];
        self.responsible = [[[[content scan:@"/^Responsible:\\s+(.+?)\\[/i"] firstObject] firstObject] strip];
        self.version = [[[[content scan:@"/^Version:\\s+(.+?)\\(/i"] firstObject] firstObject] strip];
        self.buildVersion = [[[[content scan:@"/^Version:.+\\((.*?)\\)/i"] firstObject] firstObject] strip];
        self.uuid = [[[[content scan:@"/Binary Images:.*?<(.*?)>/mi"] firstObject] firstObject] strip];
    }
    
    return self;
}

@end
