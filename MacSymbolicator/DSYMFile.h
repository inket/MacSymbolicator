//
//  DSYMFile.h
//  MacSymbolicator
//
//  Created by inket on 23/12/13.
//  Copyright (c) 2013 inket. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSString+RubyConvenience.h"
#import "NSString+ShellExecution.h"

@interface DSYMFile : NSObject

@property (strong) NSString* fileName;
@property (strong) NSString* uuid;

+ (instancetype)dsymWithFile:(NSString*)file;

@end
