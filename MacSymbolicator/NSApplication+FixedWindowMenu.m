//
//  NSApplication+FixedWindowMenu.m
//  MacSymbolicator
//
//  Created by inket on 24/12/13.
//  Copyright (c) 2013 inket. All rights reserved.
//

#import "NSApplication+FixedWindowMenu.h"

@implementation NSApplication (FixedWindowMenu)

- (void)new_removeWindowsItem:(NSWindow *)aWindow {
    if (aWindow != [[NSApp delegate] window])
        [self new_removeWindowsItem:aWindow];
}

@end