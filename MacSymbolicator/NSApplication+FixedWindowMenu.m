//
//  NSApplication+FixedWindowMenu.m
//  MacSymbolicator
//
//  Created by inket on 24/12/13.
//  Copyright (c) 2013 inket. All rights reserved.
//

#import "NSApplication+FixedWindowMenu.h"
#import <objc/runtime.h>

@implementation NSApplication (FixedWindowMenu)

+ (void)load {
    Method new = class_getInstanceMethod([NSApplication class], @selector(new_removeWindowsItem:));
    Method old = class_getInstanceMethod([NSApplication class], @selector(removeWindowsItem:));
    method_exchangeImplementations(new, old);
}

- (void)new_removeWindowsItem:(NSWindow *)aWindow {
    id appDelegate = [NSApp delegate];
    if (aWindow != [appDelegate window]) {
        [self new_removeWindowsItem:aWindow];
    }
}

@end
