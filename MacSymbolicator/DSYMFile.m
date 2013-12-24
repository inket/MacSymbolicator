//
//  DSYMFile.m
//  MacSymbolicator
//
//  Created by inket on 23/12/13.
//  Copyright (c) 2013 inket. All rights reserved.
//

#import "DSYMFile.h"

@implementation DSYMFile

+ (instancetype)dsymWithFile:(NSString*)file {
    return [[DSYMFile alloc] initWithFile:file];
}

- (instancetype)initWithFile:(NSString*)file {
    self = [super init];
    
    if (self)
    {
        NSString* attributes = [[NSString stringWithFormat:@"mdls -name com_apple_xcode_dsym_uuids -raw '%@'", file] runAsCommand];
        
        self.fileName = [file lastPathComponent];
        self.uuid = [[[[attributes scan:@"/\"(.*?)\"/i"] firstObject] firstObject] strip];
    }
    
    return self;
}

@end
