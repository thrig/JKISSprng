//
//  JKISSprngTests.m
//  JKISSprngTests
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

#import <XCTest/XCTest.h>
#import "JKISSprng.h"

@interface JKISSprngTests : XCTestCase

@end

@implementation JKISSprngTests

- (void)testJKISS
{
    JKISSprng *r = [JKISSprng new];
    [r setSeedX:1 SeedY:1 SeedZ:2 SeedC:0];
    XCTAssertEqual((uint32_t)[r randomNumber], (uint32_t)453408695, @"random number");
    NSString *s = [NSString stringWithFormat:@"%.2f", [r randomFloat]];
    XCTAssertEqualObjects([s description], @"0.53", @"random float");
    XCTAssertEqual([r rollD:20], 20, @"critical hit");
    
    // TODO testing that randomFloat can generate 0.00 and 1.00 values
    // might be handy, though would require an appropriate seed search.
}

@end
