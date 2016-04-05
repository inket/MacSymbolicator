//
//  DropZone.m
//  MacSymbolicator
//
//  Created by inket on 7/9/13.
//  Copyright (c) 2013 inket. All rights reserved.
//

#import "MBDropZone.h"

@implementation MBDropZone

- (instancetype)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
	{
        // Initialization code here.
    }
    
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    // Color Declarations
    NSColor* color = [NSColor colorWithCalibratedRed:0.7 green:0.7 blue:0.7 alpha:1];
    NSColor* color2 = [NSColor colorWithCalibratedRed:0.6 green:0.6 blue:0.6 alpha:1];
    NSColor* color3 = [NSColor colorWithCalibratedRed:0.4 green:0.4 blue:0.4 alpha:1];
    NSColor* color4 = [NSColor colorWithCalibratedRed:0 green:0 blue:0 alpha:0.025];
    NSColor* color5 = [NSColor colorWithCalibratedRed:0 green:0 blue:0 alpha:0];

    // Background
    NSBezierPath* background = [NSBezierPath bezierPathWithRect:dirtyRect];
    _isHoveringFile ? [color4 setFill] : [color5 setFill];
    [background fill];
    
    // Padding
	CGFloat borderOffset = 20.0;
    dirtyRect = NSMakeRect(dirtyRect.origin.x + borderOffset,
						   dirtyRect.origin.y + borderOffset,
						   dirtyRect.size.width - borderOffset * 2,
						   dirtyRect.size.height - borderOffset * 2);

    // Rounded Rectangle Drawing
    if (!_file || _isHoveringFile)
    {
        NSBezierPath* roundedRectanglePath = [NSBezierPath bezierPathWithRoundedRect:dirtyRect
																			 xRadius:8
																			 yRadius:8];
        _isHoveringFile ? [color3 setStroke] : [color setStroke];
        [roundedRectanglePath setLineWidth:2];
        CGFloat roundedRectanglePattern[] = {6, 6, 6, 6};
        [roundedRectanglePath setLineDash:roundedRectanglePattern count:4 phase:0];
        [roundedRectanglePath stroke];
    }

    if (_text)
    {
        NSRect textRect = NSMakeRect(dirtyRect.origin.x, 75, dirtyRect.size.width, 25);
        
        NSMutableParagraphStyle* textStyle = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];
        [textStyle setAlignment:NSCenterTextAlignment];
        
        NSDictionary* textFontAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                            [NSFont fontWithName:@"Helvetica Neue" size:16], NSFontAttributeName,
                                            color2, NSForegroundColorAttributeName,
                                            textStyle, NSParagraphStyleAttributeName, nil];
        
        NSDictionary* smallerTextFontAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                            [NSFont fontWithName:@"Helvetica Neue" size:13], NSFontAttributeName,
                                            color2, NSForegroundColorAttributeName,
                                            textStyle, NSParagraphStyleAttributeName, nil];
        
        if ([_text sizeWithAttributes:textFontAttributes].width > dirtyRect.size.width)
            [_text drawInRect:NSOffsetRect(textRect, 0, 1) withAttributes:smallerTextFontAttributes];
        else
            [_text drawInRect:NSOffsetRect(textRect, 0, 1) withAttributes:textFontAttributes];
    }
    
    if (_detailText)
    {
        NSRect textRect = NSMakeRect(dirtyRect.origin.x, 30, dirtyRect.size.width, 20);
        
        NSMutableParagraphStyle* textStyle = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];
        [textStyle setAlignment:NSCenterTextAlignment];
        
        NSDictionary* textFontAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                            [NSFont fontWithName:@"Helvetica Neue" size:12], NSFontAttributeName,
                                            color2, NSForegroundColorAttributeName,
                                            textStyle, NSParagraphStyleAttributeName, nil];
        
        [_detailText drawInRect:NSOffsetRect(textRect, 0, 1) withAttributes:textFontAttributes];
    }

    if (_fileType)
    {
        NSRect textRect2 = NSMakeRect(dirtyRect.origin.x, 50, dirtyRect.size.width, 30);
        
        NSMutableParagraphStyle* textStyle = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];
        [textStyle setAlignment:NSCenterTextAlignment];
        
        NSDictionary *textFontAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSFont fontWithName:@"Helvetica Neue Medium" size:18], NSFontAttributeName,
                              color3, NSForegroundColorAttributeName,
                              textStyle, NSParagraphStyleAttributeName, nil];
        [_fileType drawInRect:NSOffsetRect(textRect2, 0, 1) withAttributes:textFontAttributes];
    }

    
    if (_icon)
    {
		CGSize iconSize = CGSizeMake(64.0, 64.0);
        [_icon drawInRect:NSMakeRect(dirtyRect.size.width * 0.5 - iconSize.width * 0.1, /*Shadow*/
									 dirtyRect.size.width - iconSize.height * 2,
									 iconSize.width, iconSize.height)];
    }
}

- (void)setIcon:(NSImage *)icon
{
    _icon = icon;
    [self display];
}

- (void)setText:(NSString *)text
{
    _text = text;
    [self display];
}

- (void)setDetailText:(NSString *)detailText
{
    _detailText = detailText;
    [self display];
}

- (void)setFileType:(NSString *)fileType
{
    NSString* ft = [fileType lowercaseString];
    _fileType = [NSString stringWithFormat:@"%@%@", [ft hasPrefix:@"." ] ? @"" : @".", ft];
    _icon = [[NSWorkspace sharedWorkspace] iconForFileType:_fileType];
    [self registerForDraggedTypes:@[NSFilenamesPboardType]];
    
    [self display];
}

- (void)setFile:(NSString *)file
{
	if (file.length && ![file isEqualToString:_file])
	{
		_file = file;
		
		[self setText:[[file lastPathComponent] stringByDeletingPathExtension]];
	}
}

- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender
{
    NSArray* draggedFiles = [[sender draggingPasteboard] propertyListForType:NSFilenamesPboardType];
	
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF ENDSWITH %@", _fileType];
	NSArray *filteredDraggedFiles = [draggedFiles filteredArrayUsingPredicate:predicate];

	_isHoveringFile = filteredDraggedFiles.count > 0;
	[self display];
	
	return filteredDraggedFiles.count > 0 ? NSDragOperationCopy : NSDragOperationNone;
}

- (void)draggingExited:(id<NSDraggingInfo>)sender
{
    _isHoveringFile = NO;
    [self display];
}

- (BOOL)prepareForDragOperation:(id<NSDraggingInfo>)sender
{
    return YES;
}

- (BOOL)performDragOperation:(id<NSDraggingInfo>)sender
{
	NSArray* draggedFiles = [[sender draggingPasteboard] propertyListForType:NSFilenamesPboardType];
	
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF ENDSWITH %@", _fileType];
	NSArray *filteredDraggedFiles = [draggedFiles filteredArrayUsingPredicate:predicate];
	[self setFile:filteredDraggedFiles.firstObject];
    
    [self draggingExited:nil];
    [_delegate dropZone:self receivedFile:_file];
    
    return YES;
}

@end
