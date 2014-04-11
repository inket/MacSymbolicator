//
//  DropZone.h
//  MacSymbolicator
//
//  Created by inket on 7/9/13.
//  Copyright (c) 2013 inket. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol MBDropZoneDelegate;

@interface MBDropZone : NSView {
    BOOL _isHoveringFile;
}

@property (weak) id<MBDropZoneDelegate> delegate;
@property (strong, nonatomic) NSImage* icon;
@property (strong, nonatomic) NSString* fileType;
@property (strong, nonatomic) NSString* text;
@property (strong, nonatomic) NSString* detailText;

@property (strong, nonatomic) NSString* file;

@end

@protocol MBDropZoneDelegate <NSObject>
- (void)dropZone:(MBDropZone*)dropZone receivedFile:(NSString*)file;
@end
