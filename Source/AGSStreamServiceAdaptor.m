//
//  GNStreamLayer.m
//  StreamLayer
//
//  Created by Nicholas Furness on 7/11/13.
//  Copyright (c) 2013 ESRI. All rights reserved.
//

#import "AGSStreamServiceAdaptor.h"
#import "SRWebSocket.h"

@interface AGSStreamServiceAdaptor () <SRWebSocketDelegate>
@property (nonatomic, strong) SRWebSocket *socket;
@property (nonatomic, assign) NSUInteger purgeCount;
@property (nonatomic, strong) NSURL *connectionURL;
@end

#define kPurgeCountKey @"purgeCount"

@implementation AGSStreamServiceAdaptor
-(id)initWithURL:(NSString *)url
{
    return [self initWithURL:url purgeCount:0];
}

-(id)initWithURL:(NSString *)url purgeCount:(NSUInteger)purgeCount;
{
    self = [super init];
    if (self)
    {
        self.connectionURL = [NSURL URLWithString:url];
        _isConnected = NO;
        self.purgeCount = purgeCount;
    }
    return self;
}

-(void)connect
{
    if (self.isConnected)
    {
        NSLog(@"Already connected!");
        [self disconnect];
    }

    if (!self.socket)
    {
        NSURLRequest *socketRQ = [NSURLRequest requestWithURL:self.connectionURL];
        self.socket = [[SRWebSocket alloc] initWithURLRequest:socketRQ];
        self.socket.delegate = self;
    }
    _isConnected = NO;
    [self.socket open];
}

-(void)disconnect
{
    if (self.socket)
    {
        [self.socket close];
        self.socket = nil;
        _isConnected = NO;
    }
}

-(void)webSocketDidOpen:(SRWebSocket *)webSocket
{
    _isConnected = YES;
    
    if (self.streamServiceDelegate && [self.streamServiceDelegate respondsToSelector:@selector(streamServiceDidConnect:)])
    {
        [self.streamServiceDelegate streamServiceDidConnect:self];
    }
}

-(void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error
{
    NSLog(@"WebSocket error: %@", error);
    _isConnected = NO;
    if (self.streamServiceDelegate && [self.streamServiceDelegate respondsToSelector:@selector(streamServiceDidFail:withError:)])
    {
        [self.streamServiceDelegate streamServiceDidFail:self withError:error];
    }
}

-(void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean
{
    NSLog(@"WebSocket Closed: [%d,%@] %@", code, reason, wasClean?@"Clean":@"Not Clean");
    _isConnected = NO;
    if (self.streamServiceDelegate && [self.streamServiceDelegate respondsToSelector:@selector(streamServiceDidDisconnect:withReason:)])
    {
        [self.streamServiceDelegate streamServiceDidDisconnect:self withReason:reason];
    }
}

-(void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message
{
    if (self.streamServiceDelegate && [self.streamServiceDelegate respondsToSelector:@selector(onStreamServiceMessage:)])
    {
        NSError *error = nil;
        id messageObject = [NSJSONSerialization JSONObjectWithData:[(NSString *)message dataUsingEncoding:NSUTF8StringEncoding]
                                                           options:NSJSONReadingAllowFragments
                                                             error:&error];
        NSArray *streamData = nil;
        if ([messageObject isKindOfClass:[NSArray class]])
        {
            streamData = (NSArray *)messageObject;
        }
        else
        {
            streamData = @[messageObject];
        }
        
        NSMutableArray *graphics = [NSMutableArray arrayWithCapacity:streamData.count];
        for (NSDictionary *rawGraphic in streamData) {
            AGSGraphic *g = [[AGSGraphic alloc] initWithJSON:rawGraphic];
            [graphics addObject:g];
        }
    
        [self.streamServiceDelegate onStreamServiceMessage:graphics];
    }
}
@end
