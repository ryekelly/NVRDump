//
//  NVRDumpAppDelegate.h
//  NVRDump
//
//  Created by Ryan Kelly on 5/2/11.
//  Copyright 2011 Carnegie Mellon University. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NVRDumpAppDelegate : NSObject <NSApplicationDelegate> {
@private
    NSWindow *window;
}

@property (assign) IBOutlet NSWindow *window;

@end
