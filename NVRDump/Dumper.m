//
//  Dumper.m
//  NVRDump
//
//  Created by Ryan Kelly on 5/2/11.
//  Copyright 2011. All rights reserved.
//

#import "Dumper.h"

@implementation Dumper

@synthesize addressField;
@synthesize dateField;
@synthesize fileList;
@synthesize findFilesButton;    
@synthesize getFilesButton;    
@synthesize outputField;
@synthesize outputFolderButton;

@synthesize fileProgress;
@synthesize listProgress;

@synthesize allFiles;

- (void) enableAll {
    [addressField setEnabled:TRUE];
    [dateField setEnabled:TRUE];
    [fileList setEnabled:TRUE];
    [findFilesButton setEnabled:TRUE];    
    [getFilesButton setEnabled:TRUE];    
    [findFilesButton setEnabled:TRUE];
    [outputFolderButton setEnabled:TRUE];
}

- (void) disableAll {
    [addressField setEnabled:FALSE];
    [dateField setEnabled:FALSE];
    [fileList setEnabled:FALSE];
    [findFilesButton setEnabled:FALSE];    
    [getFilesButton setEnabled:FALSE];  
    [findFilesButton setEnabled:FALSE];
    [outputFolderButton setEnabled:FALSE];
}

// Open up a file dialog to pick the output directory
- (IBAction) setOutputDirectory:(id) sender {
    long result;
    NSArray *fileTypes = [NSArray arrayWithObjects:@"txt", @"rtf", @"doc", nil];
    NSOpenPanel *oPanel = [NSOpenPanel openPanel];
    
    [oPanel setAllowsMultipleSelection:NO];
    [oPanel setCanChooseDirectories:YES];
    [oPanel setTitle:@"Choose output folder"];
    [oPanel setMessage:@"Choose the folder that the files will be copied to."];
    result = [oPanel runModalForDirectory:NSHomeDirectory() file:nil types:fileTypes];
    if (result == NSOKButton) {
        NSArray *urls = [oPanel URLs];
        outputField.stringValue = [[urls objectAtIndex:0] path];
    }
}

// Sends the magic payload to get the file list for a certain day.  Fills up the NSArray with the filenames.
- (IBAction) findFiles:(id) sender {
    bool badDate = FALSE;
    NSString * dateString = [dateField stringValue];
    if ([dateString length] != 6) {
        badDate = TRUE;
    }
    else {
        int year = [[dateString substringToIndex:2] intValue];
        int month = [[dateString substringWithRange:NSMakeRange(2, 2)] intValue];
        int day = [[dateString substringFromIndex:4] intValue];
        
        if (month < 1 || month > 12 || day < 1 || day > 31 || year > 99 || year < 0) {
            badDate = TRUE;
        }
        else
        {
            // the bytes of the packet for the date in question
            fileListPacket[28] = year;
            fileListPacket[29] = month;
            fileListPacket[30] = day;
        }
    }
    
    // a few niceties
    if (badDate) {
        NSAlert * alert = [NSAlert alertWithMessageText:@"Date format should be YYMMDD" defaultButton:nil alternateButton:nil otherButton:nil informativeTextWithFormat:@""];
        [alert runModal];
        
        return;
    }
    
    NSString *urlStr = [addressField stringValue];
    NSHost *host = [NSHost hostWithName:urlStr];
    if (host == nil) {
        host = [NSHost hostWithAddress:urlStr];
    }
    
    if (host == nil) {
        NSAlert * alert = [NSAlert alertWithMessageText:@"Invalid host string" defaultButton:nil alternateButton:nil otherButton:nil informativeTextWithFormat:@""];
        [alert runModal];        
        return;
    }
    
    // If we made it this far, disable everything and set up the TCP connection    
    [self disableAll];
    [allFiles removeAllObjects];
    [fileList reloadData];
    [listProgress startAnimation:self];
    
    mode = 1;
    firstRead = true;
    packetWritten = false;
    bytesRead = 0;
    
    dataBuffer = [NSMutableData dataWithCapacity:1024];
    [dataBuffer retain];
    
    [NSStream getStreamsToHost:host port:9000 inputStream:&iStream
                  outputStream:&oStream];
    
    // iStream and oStream are instance variables
    
    [iStream retain];
    [oStream retain];
    [iStream setDelegate:self];
    [oStream setDelegate:self];
    [iStream scheduleInRunLoop:[NSRunLoop currentRunLoop]
                       forMode:NSDefaultRunLoopMode];
    [oStream scheduleInRunLoop:[NSRunLoop currentRunLoop]
                       forMode:NSDefaultRunLoopMode];
    [iStream open];
    [oStream open];    
}

// Sends the magic payload to get all the files in the NSArray list.  
- (IBAction) retrieveFiles:(id) sender {
    if ([allFiles count] == 0) {
        NSAlert * alert = [NSAlert alertWithMessageText:@"No files to get!" defaultButton:nil alternateButton:nil otherButton:nil informativeTextWithFormat:@""];
        [alert runModal];
        return;
    }
        
    BOOL isDirectory;
    if (![[NSFileManager defaultManager] fileExistsAtPath:[outputField stringValue] isDirectory:&isDirectory] || !isDirectory)
    {
        NSAlert * alert = [NSAlert alertWithMessageText:@"Set the output directory first." defaultButton:nil alternateButton:nil otherButton:nil informativeTextWithFormat:@""];
        [alert runModal];
        return;        
    }
    
    // Ok, start at the first file, and call the function retrieveFile, which will start the sequential downloads.
    [self disableAll];
    [fileProgress setMaxValue:[allFiles count]];
    [fileProgress setDoubleValue:0];
    whichFile = 0;
    [self retrieveFile];        
}

// Sets up the streams for the downloading of one file, indexed by 'whichFile' in the NSArray
- (void) retrieveFile {    
    // First, set up the TCP packet with the filename
    NSString *urlStr = [addressField stringValue];
    NSString * thisFile = [allFiles objectAtIndex:whichFile];
    const char * thisFileString = [thisFile UTF8String];
    int i;
    for (i = 0; i < [thisFile length]; i++) {
        fileQueryPacket[i+44] = thisFileString[i];
    }
    i+=44;
    while (i < 500) {
        fileQueryPacket[i++] = 0;
    }
    
    NSRange fileRange = [thisFile rangeOfString:@"/" options:NSBackwardsSearch];
    fileRange.location++;
    fileRange.length = [thisFile length] - fileRange.location - 4;
    NSString * justFileName = [thisFile substringWithRange:fileRange];
    
    // This will be our output file, in the output directory we gave above
    outFilePath = [NSString stringWithFormat:@"%@/%@.avi",[outputField stringValue],justFileName];        
    [outFilePath retain];
    
    mode = 2;
    foundAtom = false;
    bytesRead = 0;
    packetWritten = false;
    numFrames = 0;
    
    [frameBuf clearAll];
    
    // First, dump the standard AVI header that they use.  This file is in the resources directory.
    [[NSFileManager defaultManager] createFileAtPath:outFilePath contents:nil attributes:nil];
    NSFileHandle * outputFile = [NSFileHandle fileHandleForWritingAtPath:outFilePath];
    
    NSString * headerPath = [[NSBundle mainBundle] pathForResource:@"header" ofType:@"dat"];  
    NSData * allHeaderData = [[NSFileHandle fileHandleForReadingAtPath:headerPath] readDataToEndOfFile];
    [outputFile writeData:allHeaderData];
    [outputFile closeFile];
    
    // I don't want to use NSFileHandle - too much memory.  fopen will do.
    outFile = fopen([outFilePath cStringUsingEncoding:NSUTF8StringEncoding],"a");
    fseek(outFile, 0, SEEK_END);
    
    // Set up the streams, but don't cross them
    NSHost *host = [NSHost hostWithName:urlStr];
    if (host == nil) {
        host = [NSHost hostWithAddress:urlStr];
    }
    
    [NSStream getStreamsToHost:host port:9000 inputStream:&iStream
                  outputStream:&oStream];
    
    [iStream retain];
    [oStream retain];
    [iStream setDelegate:self];
    [oStream setDelegate:self];
    [iStream scheduleInRunLoop:[NSRunLoop currentRunLoop]
                       forMode:NSDefaultRunLoopMode];
    [oStream scheduleInRunLoop:[NSRunLoop currentRunLoop]
                       forMode:NSDefaultRunLoopMode];
    [iStream open];
    [oStream open];
}

// Main function for handling stream events - merely parcels out the work into 4 separate functions.
- (void)stream:(NSStream *)theStream handleEvent:(NSStreamEvent)streamEvent {
    if (mode == 1) {
        if (theStream == iStream) {
            [self handleFileListInput:streamEvent];
        }
        else {
            [self handleFileListOutput:streamEvent];            
        }
    }
    else if (mode == 2) {
        if (theStream == iStream) {
            [self handleFileTransferInput:streamEvent];                        
        }
        else {
            [self handleFileTransferOutput:streamEvent];            
        }
    }
}

// Handles the reading and organization of the file list 
- (void) handleFileListInput:(NSStreamEvent)streamEvent {
    switch (streamEvent) {
        case NSStreamEventHasBytesAvailable:
        {
            unsigned int maxLen = 1024;
                
            uint8_t buf[maxLen];
            long len = 0;
            len = [iStream read:buf maxLength:maxLen];
            bytesRead += len;    
                        
            if (firstRead) {
                [dataBuffer appendData:[NSData dataWithBytes:(buf+8) length:len-8]];
                firstRead = false;
            }
            else {
                [dataBuffer appendData:[NSData dataWithBytes:buf length:len]];
            }
            
            // These pieces are each 148 bytes long, but we just want the string part - it's null terminated.
            while ([dataBuffer length] >= 148) {
                const uint8_t * allBytes = [dataBuffer bytes];
                allBytes += 12;
                
                int i;
                for (i = 0; i <= 136; i++) {                            
                    if (allBytes[i] == 0) {
                        break;
                    }
                }
                
                if (i > 136) {
                    NSLog(@"We've got a big problem...");
                }
                    
                NSString * thisFile = [[NSString alloc] initWithBytes:allBytes length:i encoding:NSASCIIStringEncoding];
                [allFiles addObject:thisFile];
                [thisFile release];
                
                // Cut this filename from the buffer
                [dataBuffer replaceBytesInRange:NSMakeRange(0, 148) withBytes:nil length:0];
            }
                
            [fileList reloadData];
        
            break;
        }
        case NSStreamEventEndEncountered:
        {        
            // We got all the input, so clean it all up
            [oStream close];
            [oStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
            [oStream release];
            oStream = nil;
        
            [iStream close];
            [iStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
            [iStream release];
            iStream = nil;
        
            [dataBuffer release];
            
            [self enableAll];
            [listProgress stopAnimation:self];
            
            break;
        }
    }
}

// writes the file list packet to the socket
- (void) handleFileListOutput:(NSStreamEvent)streamEvent {
    switch(streamEvent) {
        case NSStreamEventHasSpaceAvailable:
            if (!packetWritten) {
                [oStream write:(const uint8_t *)fileListPacket maxLength:500];
                packetWritten = true;
            }
            break;
        default:
            break;
    }
}

// This handles the actual 264 file.  This processes the file as it is received, 
// and translates it into their version of a somewhat broken but playable AVI.
// I did not add the idx atoms because I don't need them.  To my knowledge this is 
// the only difference between the AVIs from the 264->AVI converter and these.
- (void) handleFileTransferInput:(NSStreamEvent)streamEvent {
    switch (streamEvent) {
        case NSStreamEventOpenCompleted:
        {    
            break;
        }
        case NSStreamEventHasBytesAvailable:
        {
            unsigned int maxLen = 1024;
            
            uint8_t buf[maxLen];
            long len = 0;
            len = [iStream read:buf maxLength:maxLen];

            bytesRead += len;

            // If we already found a dcH264 frame, then we should check if we have read the whole frame yet
            if (foundAtom) {
                [frameBuf appendBytes:buf withLength:(unsigned int)len];

                // this makes sure that we are not randomly cutting the dcH264 string in half and thus missing it
                if ([frameBuf length] > 8) {                    
                    unsigned int frameLen = [frameBuf get32Bit:8];
                    int increment;
                    
                    // no clue why this was necessary, but it was.  I know very little about the reasons for this stuff.
                    if ([frameBuf getByte:1] == 48) {
                        increment = 32;
                    }
                    else {
                        increment = 24;
                    }
  
                    // if we have the whole frame, write it to disk!
                    if ([frameBuf length] >= frameLen + increment) {
                        uint8_t chunkHeader[4] = {48, 48, 100, 99};
                        
                        fwrite(chunkHeader, 1, 4, outFile);
                        [frameBuf writeDataToFile:outFile fromPos:8 withLength:4];
                        [frameBuf writeDataToFile:outFile fromPos:increment withLength:frameLen];
                                                
                        if (frameLen % 2 == 1) {
                            uint8_t zero = 0;
                            fwrite(&zero, 1, 1, outFile);
                        }
                        
                        // store this so we can put it back in the AVI file later.
                        numFrames++;
                        
                        // onto the next frame, cut the old stuff
                        [frameBuf cutToPosition:frameLen+increment];
                        foundAtom = false;
                    }
                }
            }
            // otherwise, we need to search for the dcH264 string.  (We can skip the fix 0x10000 bytes. They are 0s)
            else if (bytesRead > 65536) {
                [frameBuf appendBytes:buf withLength:(unsigned int)len];                
                
                // This sequence of bytes seems to indicate the beginning of a frame
                uint8_t start264[6] = {100, 99, 72, 50, 54, 52};

                int i;
                for (i = 0; i < [frameBuf length]-8; i++) {
                    if ([frameBuf matchesBytes:start264 atPosition:i+2 withLength:6]) {
                        break;
                    }
                }
                
                // if the break was hit, we found what we're looking for ("dcH264")
                if (i < [frameBuf length] - 8) {
                    foundAtom = true;
                    
                    [frameBuf cutToPosition:i];
                }
            }
                        
            break;
        }
        case NSStreamEventEndEncountered:
        {
            // clean up the streams, and fix the AVI header, we're done.
            [oStream close];
            [oStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
            [oStream release];
            oStream = nil;
            
            [iStream close];
            [iStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
            [iStream release];
            iStream = nil;

            fclose(outFile);
            
            NSFileHandle * outputFile = [NSFileHandle fileHandleForWritingAtPath:outFilePath];
            [outputFile seekToEndOfFile];
            
            uint32_t totalFileLength = (uint32_t)[outputFile offsetInFile] - 8;

            // this is the total file length
            [outputFile seekToFileOffset:4];
            [outputFile writeData:[NSData dataWithBytes:((uint8_t *) &totalFileLength) length:4]];
            // this is the frame count
            [outputFile seekToFileOffset:48];
            [outputFile writeData:[NSData dataWithBytes:((uint8_t *) &numFrames) length:4]];
            // and this is the total movie length in bytes
            [outputFile seekToFileOffset:216];
            totalFileLength -= 212;
            [outputFile writeData:[NSData dataWithBytes:((uint8_t *) &totalFileLength) length:4]];
                        
            //other than these 3 things, i think the AVI header is fine as is.
            
            [outputFile closeFile];
            [outFilePath release];
            
            whichFile++;
            [fileProgress setDoubleValue:whichFile];
            // this is critical - if there are more files to get, start the next one, otherwise enable the buttons
            if (whichFile < [allFiles count]) {
                [self retrieveFile];
            }
            else {
                [self enableAll];
            }
                
            
            break;
        }
    }
}

// this sends the magic packet to initiate a file download
- (void) handleFileTransferOutput:(NSStreamEvent)streamEvent {
    switch(streamEvent) {
        case NSStreamEventOpenCompleted:
            break;
        case NSStreamEventHasSpaceAvailable:
            if (!packetWritten) {
                [oStream write:(const uint8_t *)fileQueryPacket maxLength:500];
                packetWritten = true;
            }
            break;
        case NSStreamEventEndEncountered:
            [oStream close];
            [oStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
            [oStream release];
            oStream = nil;
            break;
        default:
            break;
    }
}

// set up the two packets we'll need to send.  one for listing files and the other for getting them
-(id) init {
    if ((self = [super init]))
    {
        // getting the file lists % the date [28-30]
        fileListPacket[3] = 1;
        fileListPacket[7] = 9;
        fileListPacket[8] = 9;
        fileListPacket[19] = 40;
        fileListPacket[20] = 3;
        fileListPacket[24] = 255;
        fileListPacket[25] = 255;
        fileListPacket[34] = 23;
        fileListPacket[35] = 59;
        fileListPacket[36] = 59;
        
        // getting the actual files % the filename
        fileQueryPacket[3] = 1;
        fileQueryPacket[7] = 7;
        fileQueryPacket[8] = 74;
        fileQueryPacket[19] = 172;
        fileQueryPacket[23] = 1;
        
        self.allFiles = [NSMutableArray arrayWithCapacity:100];

        // start the circular buffer at a meg, although the frames are much smaller than that.
        frameBuf = [[FrameBuffer alloc] initWithBufferSize:(1024^2)];
    }
    
    return self;
}
                        
- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView {
    return [allFiles count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger) rowIndex {
    return [allFiles objectAtIndex:rowIndex];
}

@end
