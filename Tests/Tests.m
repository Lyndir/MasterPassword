//
//  Tests.m
//  Tests
//
//  Created by Maarten Billemont on 04/07/12.
//  Copyright (c) 2012 Lyndir. All rights reserved.
//

#import "Tests.h"

@implementation Tests

- (void)setUp
{
    dbg(@"======================= TEST SET-UP ======================");
    [PearlLogger get].printLevel = PearlLogLevelTrace;

    [super setUp];
    
    // Set-up code here.
}

- (void)tearDown
{
    dbg(@"===================== TEST TEAR-DOWN =====================");
    // Tear-down code here.
    
    [super tearDown];
}

- (void)testAlgorithm
{
    NSString *masterPassword = @"test-mp";
    NSString *username = @"test-user";
    NSString *siteName = @"test-site";
    MPElementType siteType = MPElementTypeGeneratedLong;
    uint32_t siteCounter = 42;
    
    NSString *sitePassword = MPCalculateContent( siteType, siteName, keyForPassword( masterPassword, username ), siteCounter );
    
    inf( @"master password: %@, username: %@\nsite name: %@, site type: %@, site counter: %d\n    => site password: %@",
               masterPassword, username, siteName, NSStringFromMPElementType(siteType), siteCounter, sitePassword );
}

@end
