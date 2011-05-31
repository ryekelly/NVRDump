//
//  NVRDumpAppDelegate.h
//  NVRDump
//
//  Created by Ryan Kelly on 5/2/11.
//  Copyright 2011. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NVRDumpAppDelegate : NSObject <NSApplicationDelegate> {
@private
    NSWindow *window;
    IBOutlet NSTextField * addressField;
    IBOutlet NSTextField * dateField;
    IBOutlet NSTextField * outputField;
}

@property (assign) IBOutlet NSWindow *window;

@end
