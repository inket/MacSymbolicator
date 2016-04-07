//
//  DSYMFile.m
//  MacSymbolicator
//
//  Created by inket on 23/12/13.
//  Copyright (c) 2013 inket. All rights reserved.
//

#import "DSYMFile.h"
#import "NSString+RubyConvenience.h"
#import "NSString+ShellExecution.h"

@implementation DSYMFile

+ (instancetype)dsymWithFile:(NSString*)file {
    return [[DSYMFile alloc] initWithFile:file];
}

- (instancetype)initWithFile:(NSString*)file {
    self = [super init];
    
    if (self) {
        NSString* dwarfDumpOutput = [[NSString stringWithFormat:@"dwarfdump --uuid '%@'", file] runAsCommand];
        NSString* foundUUID = [[[[dwarfDumpOutput strip] scan:@"/UUID: (.*) \\(/mi"] firstObject] firstObject];
        
        self.fileName = [file lastPathComponent];
        self.uuid = (foundUUID && [foundUUID isKindOfClass:[NSString class]]) ? foundUUID : nil;
    }
    
    return self;
}

@end
