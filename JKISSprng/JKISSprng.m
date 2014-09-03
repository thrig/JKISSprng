//
//  JKISSprng.m
//  JKISSprng
//
//  Copyright (c) 2014 Jeremy Mates. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining
// a copy of this software and associated documentation files (the
// "Software"), to deal in the Software without restriction, including
// without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to
// permit persons to whom the Software is furnished to do so, subject to
// the following conditions:
//
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
// LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
// OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
// WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#import "JKISSprng.h"

@interface JKISSprng ()

@property (nonatomic) uint32_t seedX;
@property (nonatomic) uint32_t seedY;
@property (nonatomic) uint32_t seedZ;
@property (nonatomic) uint32_t seedC;

@end

@implementation JKISSprng

// JKISS RNG borrowed from public domain code in "Good Practice in (Pseudo)
// Random Number Generation for Bioinformatics Applications" by David Jones
// (Last revision May 7th 2010).
- (unsigned int)randomNumber
{
    uint64_t t;
    
    self.seedX = 314527869 * self.seedX + 1234567;
    self.seedY ^= self.seedY << 5;
    self.seedY ^= self.seedY >> 7;
    self.seedY ^= self.seedY << 22;
    t = 4294584393ULL * self.seedZ + self.seedC;
    self.seedC = t >> 32;
    self.seedZ = (uint32_t)t;
    
    return self.seedX + self.seedY + self.seedZ;
}

// returns value between 0.0 and 1.0 inclusive
- (double)randomFloat
{
    return [self randomNumber] / 4294967295.0;
}

// for small values where max << INT_MAX to avoid potential modulo bias
- (int)rollD:(int)max
{
    if (max <= 0)
        return 0;
    return [self randomNumber] % max + 1;
}

// arc4random(3) might be another way to set these
- (void)setSeedX:(uint32_t)x
           SeedY:(uint32_t)y
           SeedZ:(uint32_t)z
           SeedC:(uint32_t)c
{
    self.seedX = x;
    self.seedY = y;
    self.seedZ = z;
    self.seedC = c;
}

- (BOOL)twizzleSeeds:(NSError **)anError
{
    FILE *fp = fopen("/dev/random", "r");
    
    if (!fp) {
        // Alternatives include raise(3) or to otherwise crash, or to
        // fall back to arc4random(3) (which then in turn might then
        // go try to get data from /dev/random...).
        if (anError != NULL) {
            NSError *underlyingError = [[NSError alloc] initWithDomain:NSPOSIXErrorDomain
                                                                  code:errno userInfo:nil];
            NSDictionary *errorDictionary = @{ NSLocalizedDescriptionKey:NSLocalizedString(@"Could not fopen(3)", @"/dev/random"), NSUnderlyingErrorKey:underlyingError, NSFilePathErrorKey:@"/dev/random" };
            *anError = [[NSError alloc] initWithDomain:NSPOSIXErrorDomain
                                                  code:errno userInfo:errorDictionary];
        }
        return NO;
    }
    
    self.seedX = self.seedY = self.seedZ = self.seedC = 0;
    
    uint8_t c;
    for (int i=0; i<sizeof(self.seedX); i++) {
        c = fgetc(fp);
        self.seedX |= (c << (8 * i));
    }
    
    while (self.seedY == 0) {
        for (int i=0; i<sizeof(self.seedY); i++) {
            c = fgetc(fp);
            self.seedY |= (c << (8 * i));
        }
    }
    
    for (int i=0; i<sizeof(self.seedZ); i++) {
        c = fgetc(fp);
        self.seedZ |= (c << (8 * i));
    }
    
    for (int i=0; i<sizeof(self.seedC); i++) {
        c = fgetc(fp);
        self.seedC |= (c << (8 * i));
    }
    // offset c to avoid z=c=0
    self.seedC %= 698769068 + 1;
    
    fclose(fp);
    
    return YES;
}

@end