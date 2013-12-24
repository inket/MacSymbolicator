//
//  NSString+RubyConvenience.h
//  MacSymbolicator
//
//  Created by inket on 23/12/13.
//  Copyright (c) 2013 inket. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSRegularExpression+RubyConvenience.h"

@interface NSString (RubyConvenience)

- (NSArray*)scan:(NSString*)regexString;
- (NSString*)strip;

@end
