//
//  NSApplication+FixedWindowMenu.m
//  MacSymbolicator
//
//  Created by inket on 24/12/13.
//  Copyright (c) 2013 inket. All rights reserved.
//

#import "NSApplication+FixedWindowMenu.h"

@implementation NSApplication (FixedWindowMenu)

- (void)removeWindowsItem:(NSWindow *)aWindow {
    if (aWindow != [[NSApp delegate] window])
    {
        for (NSMenuItem* item in [[self windowsMenu] itemArray]) {
            if ([item target] == aWindow) [[self windowsMenu] removeItem:item];
        }
    }
}

@end