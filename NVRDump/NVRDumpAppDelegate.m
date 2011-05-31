//
//  NVRDumpAppDelegate.m
//  NVRDump
//
//  Created by Ryan Kelly on 5/2/11.
//  Copyright 2011. All rights reserved.
//

#import "NVRDumpAppDelegate.h"

@implementation NVRDumpAppDelegate

@synthesize window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    NSString * pathString = [defaults stringForKey:@"pathString"];
    NSString * dateString = [defaults stringForKey:@"dateString"];
    NSString * hostString = [defaults stringForKey:@"hostString"];
    
    if (pathString != nil) {
        outputField.stringValue = pathString;        
    }
    if (dateString != nil) {
        dateField.stringValue = dateString;        
    }
    if (hostString != nil) {
        addressField.stringValue = hostString;        
    }
    // Insert code here to initialize your application
}

- (void) applicationWillTerminate:(NSNotification *)application {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:outputField.stringValue forKey:@"pathString"];
    [defaults setObject:dateField.stringValue forKey:@"dateString"];
    [defaults setObject:addressField.stringValue forKey:@"hostString"];
    [defaults synchronize];     
}

@end
