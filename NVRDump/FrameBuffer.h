//
//  FrameBuffer.h
//  NVRDump
//
//  Created by Ryan Kelly on 5/3/11.
//  Copyright 2011. All rights reserved.
//

#import <Foundation/Foundation.h>

// Custom circular buffer.  The constant updates to NSMutableData were too memory intensive, so this was a natural solution. 
// The functions have few checks for correct usage (e.g. that you are writing data that actually is within the buffer), so buyer beware.  

@interface FrameBuffer : NSObject {
    uint8_t * buf;

    unsigned int bufSize;
    unsigned int pos;
    unsigned int dataLen;
}

- (id)initWithBufferSize: (unsigned int)capacity;
- (unsigned int) getBufferSize;
- (unsigned int) length;
- (uint8_t) getByte:(unsigned int)position;
- (void) appendBytes:(uint8_t *) bytes withLength: (unsigned int) length;
- (void) cutToPosition:(unsigned int)position;
- (void) clearAll;
- (unsigned int) get32Bit:(unsigned int) position;
- (void) writeDataToFile:(FILE *)file fromPos:(unsigned int)position withLength:(unsigned int) length;
- (bool) matchesBytes:(const uint8_t *) seq atPosition:(unsigned int)position withLength:(unsigned int) length;

@end
