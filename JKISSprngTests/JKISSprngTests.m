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
    
    BOOL result = [r setSeedX:0 SeedY:1];
    XCTAssertEqual(result, YES, @"setSeed didn't fail");
    
    XCTAssertEqual([r rollD:20], 20, @"critical hit");
    XCTAssertEqual((uint32_t)[r randomNumber], (uint32_t)2846819338, @"random number");
    NSString *s = [NSString stringWithFormat:@"%.2f", [r randomFloat]];
    XCTAssertEqualObjects([s description], @"0.14", @"random float");
    
    NSArray *menagerie = @[@"cat", @"dog", @"cuttlefish"];
    XCTAssertEqualObjects([r randomArrayMember:menagerie], @"dog", @"random array member");

    result = [r twizzleSeeds:NULL];
    XCTAssertEqual(result, YES, @"seed twizzle didn't fail");
    
    // randomFloat must span 0.0 to 1.0 inclusive, not 0.0 <= x < 1.0
    [r setSeedX:0 SeedY:61220];
    s = [NSString stringWithFormat:@"%.3f", [r randomFloat]];
    XCTAssertEqualObjects([s description], @"0.000", @"zero");
    
    [r setSeedX:0 SeedY:3876];
    s = [NSString stringWithFormat:@"%.3f", [r randomFloat]];
    XCTAssertEqualObjects([s description], @"1.000", @"one");
    
    [r setSeedX:0 SeedY:4];
    NSSet *mySet = [NSSet setWithArray:menagerie];
    XCTAssertEqualObjects([r randomSetMember:mySet], @"dog", @"set member");
}

@end
