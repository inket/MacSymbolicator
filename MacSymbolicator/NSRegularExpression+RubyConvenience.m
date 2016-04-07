//
//  NSRegularExpression+RubyConvenience.m
//  MacSymbolicator
//
//  Created by inket on 23/12/13.
//  Copyright (c) 2013 inket. All rights reserved.
//

#import "NSRegularExpression+RubyConvenience.h"
#import "NSString+RubyConvenience.h"

@implementation NSRegularExpression (RubyConvenience)

+ (NSRegularExpression*)regularExpressionWithRubyRegex:(NSString*)reg error:(NSError**)error {
    if (!reg || [[reg strip] isEqualToString:@""]) {
        return nil;
    }
    
    NSString* params = @"";
    
    NSMutableArray* components = [[reg componentsSeparatedByString:@"/"] mutableCopy];
    if ([components count] < 3) {
        return nil;
    }
    
    if (![reg hasSuffix:@"/"]) {
        params = [components lastObject];
    }
    
    [components removeObjectAtIndex:0];
    [components removeLastObject];
    reg = [components componentsJoinedByString:@"/"];
    
    NSRegularExpressionOptions options = 0;
    
    if ([params rangeOfString:@"i"].location != NSNotFound) {
        options |= NSRegularExpressionCaseInsensitive;
    }
    
    if ([params rangeOfString:@"m"].location == NSNotFound) {
        options |= NSRegularExpressionAnchorsMatchLines;
    } else {
        options |= NSRegularExpressionDotMatchesLineSeparators;
    }
    
    return [NSRegularExpression regularExpressionWithPattern:reg options:options error:error];
}

@end
