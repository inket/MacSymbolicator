//
//  NSRegularExpression+RubyConvenience.h
//  MacSymbolicator
//
//  Created by inket on 23/12/13.
//  Copyright (c) 2013 inket. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSRegularExpression (RubyConvenience)

+ (NSRegularExpression*)regularExpressionWithRubyRegex:(NSString*)reg error:(NSError**)error;

@end