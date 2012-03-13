//
//  SendToMac.m
//  SendToMac
//
//  Created by Maarten Billemont on 13/03/12.
//  Copyright (c) 2012 Lyndir. All rights reserved.
//

#import "SendToMac.h"

#import <SystemConfiguration/SystemConfiguration.h>
#import <netinet/in.h>
#import <sys/socket.h>
#include <arpa/inet.h>

@implementation SendToMac
@synthesize timeout, netServiceBrowser, messageQueues;

- (id)initWithDelegate:(id<NSNetServiceBrowserDelegate>)delegate {

    if (!(self = [super init]))
        return nil;
    
    self.timeout = 10;
    self.messageQueues = [NSMutableDictionary dictionaryWithCapacity:1];

    self.netServiceBrowser = [NSNetServiceBrowser new];
    self.netServiceBrowser.delegate = delegate;

    return self;
}

- (void)start {

    [self.netServiceBrowser searchForServicesOfType:@"_sendtomac._tcp." inDomain:@""];
}

- (void)stop {

    [self.netServiceBrowser stop];
}

- (void)send:(NSString *)string toMac:(NSNetService *)service {
    
    NSMutableArray *messageQueue = [self.messageQueues objectForKey:service];
    if (!messageQueue)
        [self.messageQueues setObject:messageQueue = [NSMutableArray arrayWithCapacity:3] forKey:service];
    [messageQueue addObject:string];

    service.delegate = self;
    [service resolveWithTimeout:self.timeout];
}

- (void)netServiceDidResolveAddress:(NSNetService *)sender {

    struct sockaddr *senderAddress = NULL;
    for (NSData *address in sender.addresses) {
        struct sockaddr *socketAddress = (struct sockaddr *)address.bytes;
        char *addressName = inet_ntoa((((struct sockaddr_in *)socketAddress)->sin_addr));
        
        SCNetworkReachabilityRef target = SCNetworkReachabilityCreateWithAddress(NULL, socketAddress);
        SCNetworkReachabilityFlags flags;
        if (!SCNetworkReachabilityGetFlags(target, &flags)) {
            err(@"Couldn't determine reachability for address: %s", addressName);
            continue;
        }
        
        if (!(flags & kSCNetworkReachabilityFlagsReachable)) {
            err(@"Not reachable: %s", addressName);
            continue;
        }
        
        senderAddress = socketAddress;
        break;
    }
    if (senderAddress == NULL) {
        dbg(@"Couldn't determine a reachable address for: %@", sender);
        return;
    }

    NSSocketNativeHandle socketHandle;
    if (0 > (socketHandle = socket(senderAddress->sa_family, SOCK_STREAM, 0))) {
        err(@"Couldn't create socket: %@", errstr());
        return;
    }
    if (0 > connect(socketHandle, senderAddress, senderAddress->sa_len)) {
        err(@"Couldn't connect socket: %@", errstr());
        close(socketHandle);
        return;
    }
    if (0 > close(socketHandle)) {
        err(@"Couldn't close socket: %@", errstr());
        return;
    }

    for (NSString *messange in [self.messageQueues objectForKey:sender]) {
        
    }
}

- (void)netService:(NSNetService *)sender didNotResolve:(NSDictionary *)errorDict {

    err(@"%@%@", NSStringFromSelector(_cmd), errorDict);
}


@end
