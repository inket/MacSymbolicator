//
//  NSString+RubyConvenience.m
//  MacSymbolicator
//
//  Created by inket on 23/12/13.
//  Copyright (c) 2013 inket. All rights reserved.
//

#import "NSString+RubyConvenience.h"
#import "NSRegularExpression+RubyConvenience.h"

@implementation NSString (RubyConvenience)

- (NSArray*)scan:(NSString*)regexString {
    NSError* error = nil;
    NSRegularExpression* regex = [NSRegularExpression regularExpressionWithRubyRegex:regexString error:&error];
    if (error) {
        NSLog(@"%@", error);
        
        return nil;
    }
    
    NSMutableArray* results = [NSMutableArray array];
    NSArray* matches = [regex matchesInString:self options:0 range:NSMakeRange(0, self.length)];
    
    [matches enumerateObjectsUsingBlock:^(NSTextCheckingResult* match, NSUInteger idx, BOOL * _Nonnull stop) {
        
        NSMutableArray* aMatch = [NSMutableArray array];
        
        @try {
            if (match.range.location != NSNotFound) {
                if ([match numberOfRanges] == 1)
                {
                    [aMatch addObject:[self substringWithRange:match.range]];
                }
                
                for (int i = 1; i < [match numberOfRanges]; ++i) {
                    [aMatch addObject:[self substringWithRange:[match rangeAtIndex:i]]];
                }
            }
        }
        @catch (NSException *exception) {
            NSLog(@"%@", exception);
        }
        
        [results addObject:aMatch];
    }];
    
    return results;
}

- (NSString*)strip {
    return [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

@end
