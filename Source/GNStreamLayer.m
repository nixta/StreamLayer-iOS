//
//  GNStreamLayer.m
//  StreamLayer
//
//  Created by Nicholas Furness on 7/11/13.
//  Copyright (c) 2013 ESRI. All rights reserved.
//

#import "GNStreamLayer.h"
#import "SRWebSocket.h"

@interface GNStreamLayer () <SRWebSocketDelegate>
@property (nonatomic, strong) SRWebSocket *socket;
@property (nonatomic, assign) NSUInteger purgeCount;
@property (nonatomic, strong) NSURL *connectionURL;
@end

#define kPurgeCountKey @"purgeCount"

@implementation GNStreamLayer
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
        self.isConnected = NO;
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
    self.isConnected = NO;
    [self.socket open];
}

-(void)disconnect
{
    if (self.socket)
    {
        [self.socket close];
        self.socket = nil;
        self.isConnected = NO;
    }
}

-(void)webSocketDidOpen:(SRWebSocket *)webSocket
{
    NSLog(@"WebSocket Opened OK");
    self.isConnected = YES;
    
    if (self.streamDelegate && [self.streamDelegate respondsToSelector:@selector(streamLayerDidConnect:)])
    {
        [self.streamDelegate streamLayerDidConnect:self];
    }
}

-(void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error
{
    NSLog(@"WebSocket error: %@", error);
    self.isConnected = NO;
    if (self.streamDelegate && [self.streamDelegate respondsToSelector:@selector(streamLayerDidFail:withError:)])
    {
        [self.streamDelegate streamLayerDidFail:self withError:error];
    }
}

-(void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean
{
    NSLog(@"WebSocket Closed: [%d,%@] %@", code, reason, wasClean?@"Clean":@"Not Clean");
    self.isConnected = NO;
    if (self.streamDelegate && [self.streamDelegate respondsToSelector:@selector(streamLayerDidDisconnect:withReason:)])
    {
        [self.streamDelegate streamLayerDidDisconnect:self withReason:reason];
    }
}

-(void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message
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
        g.geometry = [[AGSGeometryEngine defaultGeometryEngine] projectGeometry:g.geometry
                                                             toSpatialReference:self.mapView.spatialReference];
        [graphics addObject:g];
    }
    
    [self addGraphics:graphics];
    [self _purge];
    
    if (self.streamDelegate && [self.streamDelegate respondsToSelector:@selector(streamLayerGotUpdate:)])
    {
        [self.streamDelegate streamLayerGotUpdate:graphics];
    }
}

-(void)_purge
{
    if (self.purgeCount > 0 && self.graphicsCount > self.purgeCount)
    {
        NSUInteger numberToPurge = self.graphicsCount - self.purgeCount;
        NSMutableArray *graphicsToPurge = [NSMutableArray arrayWithCapacity:numberToPurge];
        for (NSInteger i = 0; i < numberToPurge ; i++) {
            [graphicsToPurge addObject:self.graphics[i]];
        }
        [self removeGraphics:graphicsToPurge];
    }
}
@end
