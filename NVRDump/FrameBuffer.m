//
//  FrameBuffer.m
//  NVRDump
//
//  Created by Ryan Kelly on 5/3/11.
//  Copyright 2011. All rights reserved.
//

#import "FrameBuffer.h"

@implementation FrameBuffer

-(id)init
{
    if ((self = [super init]))
    {
        [self initWithBufferSize:1024];
    }
    return self;
}

-(id)initWithBufferSize: (unsigned int)capacity
{
    if ((self = [super init]))
    {
        bufSize = capacity;
        
        buf = (uint8_t *)malloc(sizeof(uint8_t) * capacity);
        pos = 0;
        dataLen = 0;
    }
    return self;
}

// The current capacity of the buffer
- (unsigned int) getBufferSize {
    return bufSize;
}

// The length of the data in the buffer
- (unsigned int) length {
    return dataLen;
}

// Returns a single byte
- (uint8_t) getByte:(unsigned int)position {
    return buf[(pos+position) % bufSize];
}

// Add bytes onto the end of the buffer
- (void) appendBytes:(uint8_t *) bytes withLength: (unsigned int) length {
    if (length + dataLen > bufSize) {
        unsigned int newBufSize = ((length + dataLen) * 3) / 2;
        uint8_t * oldBuf = buf;
        buf = (uint8_t *) malloc(sizeof(uint8_t) * newBufSize);
        for (int i = 0; i < dataLen; i++) {
            buf[i] = oldBuf[(pos + i) % bufSize];
        }
        free(oldBuf);
        
        pos = 0;
        bufSize = newBufSize;
    }

    for (int i = 0; i < length; i++) {
        buf[(pos + dataLen + i) % bufSize] = bytes[i];
    }
    dataLen += length;
}

// Remove bytes from the beginning of the buffer
- (void) cutToPosition:(unsigned int)position {
    if (position <= dataLen) {
        dataLen -= position;
        pos = (pos + position) % bufSize;        
    }
}

// Reset the buffer
- (void) clearAll {
    pos = 0;
    dataLen = 0;
}

// Get the 32 bit number given by the 4 bytes starting at this position
- (unsigned int) get32Bit:(unsigned int) position {
    unsigned int byte4 = 0;
    for (int i = 3; i >= 0; i--) {
        byte4 = byte4*256 + [self getByte:position+i];
    }
    return byte4;
}

// Dump out the data to an open file, starting at position and for length bytes
- (void) writeDataToFile:(FILE *)file fromPos:(unsigned int)position withLength:(unsigned int) length {
    position = (pos + position) % bufSize;
    if (position + length > bufSize) {
        fwrite(buf+position, 1, bufSize-position,file);
        fwrite(buf, 1, length-(bufSize-position), file);
    }
    else {
        fwrite(buf+position, 1, length, file);
    }
}

// Returns true if the bytes in seq are exactly the buffer bytes at "position"
- (bool) matchesBytes:(const uint8_t *) seq atPosition:(unsigned int)position withLength:(unsigned int) length {
    for (int i = 0; i < length; i++) {
        if (buf[(i+position+pos)%bufSize] != seq[i]) {
            return FALSE;
        }
    }
    return TRUE;
}

@end
