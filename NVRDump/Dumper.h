//
//  Dumper.h
//  NVRDump
//
//  Created by Ryan Kelly on 5/2/11.
//  Copyright 2011. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FrameBuffer.h"

@interface Dumper : NSObject <NSStreamDelegate,NSTableViewDataSource,NSTableViewDelegate> {
    IBOutlet NSTextField * addressField;
    IBOutlet NSTextField * dateField;
    IBOutlet NSTextField * outputField;
    IBOutlet NSTableView * fileList;
    IBOutlet NSButton * findFilesButton;    
    IBOutlet NSButton * getFilesButton;    
    IBOutlet NSButton * outputFolderButton;    
    
    IBOutlet NSProgressIndicator * fileProgress;
    IBOutlet NSProgressIndicator * listProgress;
    
    NSInputStream * iStream;
    NSOutputStream * oStream;
    FILE *outFile;
    NSString * outFilePath;
    
    NSMutableArray * allFiles;
    
    bool firstRead, packetWritten, foundAtom;
    NSMutableData * dataBuffer;
    FrameBuffer * frameBuf;
    uint8_t fileListPacket[500];
    uint8_t fileQueryPacket[500];
    int mode;
    uint32_t numFrames;
    long bytesRead;
    
    int whichFile;
}

- (IBAction) findFiles:(id) sender;
- (void)stream:(NSStream *)theStream handleEvent:(NSStreamEvent)streamEvent;
- (IBAction) retrieveFiles:(id) sender;
- (void) retrieveFile;

- (void) handleFileListInput:(NSStreamEvent)streamEvent;
- (void) handleFileListOutput:(NSStreamEvent)streamEvent;
- (void) handleFileTransferInput:(NSStreamEvent)streamEvent;
- (void) handleFileTransferOutput:(NSStreamEvent)streamEvent;

- (void) enableAll;
- (void) disableAll;

@property (nonatomic, retain) NSTextField * addressField;
@property (nonatomic, retain) NSTextField * dateField;
@property (nonatomic, retain) NSTextField * outputField;
@property (nonatomic, retain) NSTableView * fileList;
@property (nonatomic, retain) NSButton * findFilesButton;
@property (nonatomic, retain) NSButton * getFilesButton;
@property (nonatomic, retain) NSButton * outputFolderButton;

@property (nonatomic, retain) NSMutableArray * allFiles;

@property (nonatomic, retain)  NSProgressIndicator * fileProgress;
@property (nonatomic, retain)  NSProgressIndicator * listProgress;

@end
