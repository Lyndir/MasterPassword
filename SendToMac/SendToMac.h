//
//  SendToMac.h
//  SendToMac
//
//  Created by Maarten Billemont on 13/03/12.
//  Copyright (c) 2012 Lyndir. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SendToMac : NSObject <NSNetServiceDelegate>

@property (assign) NSTimeInterval               timeout;
@property (strong) NSNetServiceBrowser          *netServiceBrowser;
@property (strong) NSMutableDictionary          *messageQueues;

@end
