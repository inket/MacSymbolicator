//
//  NSString+ShellExecution.m
//  HAPU
//
//  Created by inket on 25/9/13.
//  Copyright (c) 2013 inket. All rights reserved.
//

#import "NSString+ShellExecution.h"

@implementation NSString (ShellExecution)

- (NSString*)runAsCommand
{
    NSPipe* pipe = [NSPipe pipe];
    
    NSTask* task = [[NSTask alloc] init];
    [task setLaunchPath: @"/bin/sh"];
    [task setArguments:@[@"-c", [NSString stringWithFormat:@"%@", self]]];
    [task setStandardOutput:pipe];
    
    NSFileHandle* file = [pipe fileHandleForReading];
    [task launch];
    
    return [[NSString alloc] initWithData:[file readDataToEndOfFile] encoding:NSUTF8StringEncoding];
}

@end
