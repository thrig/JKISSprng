//
//  JKISSprng.m
//  JKISSprng - pseudo random number generator implementation for Objective-C
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

@property (nonatomic) uint64_t seedX;
@property (nonatomic) uint64_t seedY;
@property (nonatomic) uint32_t seedC1;
@property (nonatomic) uint32_t seedC2;
@property (nonatomic) uint32_t seedZ1;
@property (nonatomic) uint32_t seedZ2;

@end

@implementation JKISSprng

- (id)randomArrayMember:(NSArray *)theAssay
{
    if (theAssay == nil)
        return nil;
    NSUInteger count = [theAssay count];
    if (count == 0)
        return nil;
    return [theAssay objectAtIndex:[self randomNumber] % count];
}

// JLKISS64 RNG borrowed from public domain code in "Good Practice in (Pseudo)
// Random Number Generation for Bioinformatics Applications" by David Jones
// (Last revision May 7th 2010).
- (uint64_t)randomNumber
{
    uint64_t t;
    self.seedX = 1490024343005336237ULL * self.seedX + 123456789;
    self.seedY ^= self.seedY << 21;
    self.seedY ^= self.seedY >> 17;
    self.seedY ^= self.seedY << 30;
    t = 4294584393ULL * self.seedZ1 + self.seedC1;
    self.seedC1 = t >> 32;
    self.seedZ1 = (uint32_t)t;
    t = 4246477509ULL * self.seedZ2 + self.seedC2;
    self.seedC2 = t >> 32;
    self.seedZ2 = (uint32_t)t;
    return self.seedX + self.seedY + self.seedZ1 + ((uint64_t)self.seedZ2 << 32);
}

// Returns value between 0.0 and 1.0 inclusive (0.0<=n<=1.0); probably should
// be renamed "randomDouble". An alternative might be something like:
//  return ldexp((double) [self randomNumber], -64);
- (double)randomFloat
{
    return [self randomNumber] / 18446744073709551616.0;
}

- (id)randomSetMember:(NSSet *)theSet
{
    __weak JKISSprng *weakSelf = self;
    __block id theValue;
    __block unsigned long long i = 1;
    
    [theSet enumerateObjectsUsingBlock:^(id item, BOOL *stop) {
        JKISSprng *innerSelf = weakSelf;
        // A hopefully not botched copy of the algorithm from "The Art of
        // Computer Programming", Volume 2, Section 3.4.2 by Donald E. Knuth.
        if ([innerSelf randomNumber] <= UINT64_MAX / i++) {
            theValue = item;
        }
    }];
    
    return theValue;
}

// Returns value between 1 and max, inclusive; intended for small values, as
// numbers up near UINT64_MAX should increasingly exhibit modulo bias.
- (long)rollD:(long)max
{
    if (max <= 0)
        return 0;
    return [self randomNumber] % max + 1;
}

- (BOOL)setSeedX:(uint64_t)x
           SeedY:(uint64_t)y
{
    if (y == 0)
        return NO;
    
    self.seedX = x;
    self.seedY = y;
    
    self.seedC1 = 6543217;
    self.seedZ1 = 43219876;
    self.seedC2 = 1732654;
    self.seedZ2 = 21987643;
    
    return YES;
}

- (BOOL)twizzleSeeds:(NSError **)anError
{
    int fd = open("/dev/urandom", O_RDONLY);
    if (fd == -1) {
        // Alternatives include raise(3) or to otherwise crash, or to fall back
        // to arc4random(3) (which then in turn might then go try to get data
        // from /dev/urandom...)
        if (anError != NULL) {
            NSError *underlyingError = [[NSError alloc] initWithDomain:NSPOSIXErrorDomain
                                                                  code:errno userInfo:nil];
            NSDictionary *errorDictionary = @{ NSLocalizedDescriptionKey:NSLocalizedString(@"Could not open(2)", @"/dev/urandom"), NSUnderlyingErrorKey:underlyingError, NSFilePathErrorKey:@"/dev/urandom" };
            *anError = [[NSError alloc] initWithDomain:NSPOSIXErrorDomain
                                                  code:errno userInfo:errorDictionary];
        }
        return NO;
    }

    BOOL readResult = YES;
    uint64_t xyval;
    
    if (read(fd, &xyval, sizeof(xyval)) != sizeof(xyval)) {
        readResult = NO;
        goto READFAILED;
    } else {
        self.seedX = xyval;
    }

    // Granted, if the random device is feeding back only 0s, this would
    // loop forever; a sanity check would be to only loop N times, and
    // failing that return NO (plus log a wtf note somewhere).
    self.seedY = 0;
    while (self.seedY == 0) {
        if (read(fd, &xyval, sizeof(xyval)) != sizeof(xyval)) {
            readResult = NO;
            goto READFAILED;
        } else {
            self.seedY = xyval;
        }
    }

    // Could also randomize these, but would need to assert that !(c1=z1=0)
    // and likewise for the c2/z2; the entropy from X and Y should be enough,
    // unless multitudes of simulations cause a Birthday Paradox.
    self.seedC1 = 6543217;
    self.seedZ1 = 43219876;
    self.seedC2 = 1732654;
    self.seedZ2 = 21987643;
    
READFAILED:
    if (readResult == NO && anError != NULL) {
        NSError *underlyingError = [[NSError alloc] initWithDomain:NSPOSIXErrorDomain
                                                              code:errno userInfo:nil];
        NSDictionary *errorDictionary = @{ NSLocalizedDescriptionKey:NSLocalizedString(@"Incomplete read(2)", @"/dev/urandom"), NSUnderlyingErrorKey:underlyingError, NSFilePathErrorKey:@"/dev/urandom" };
        *anError = [[NSError alloc] initWithDomain:NSPOSIXErrorDomain
                                              code:errno userInfo:errorDictionary];
    }
    close(fd);
    
    return readResult;
}

@end
