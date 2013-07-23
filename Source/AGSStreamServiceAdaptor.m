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
@property (nonatomic, strong) NSURL *connectionURL;
@end

@implementation AGSStreamServiceAdaptor
-(id)initWithURL:(NSString *)url
{
    self = [super init];
    if (self)
    {
        self.connectionURL = [NSURL URLWithString:url];
        _isConnected = NO;
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
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(streamServiceDidConnect:)])
    {
        [self.delegate streamServiceDidConnect:self];
    }
}

-(void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error
{
    NSLog(@"WebSocket error: %@", error);
    _isConnected = NO;
    if (self.delegate && [self.delegate respondsToSelector:@selector(streamServiceDidFail:withError:)])
    {
        [self.delegate streamServiceDidFail:self withError:error];
    }
}

-(void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean
{
    NSLog(@"WebSocket Closed: [%d,%@] %@", code, reason, wasClean?@"Clean":@"Not Clean");
    _isConnected = NO;
    if (self.delegate && [self.delegate respondsToSelector:@selector(streamServiceDidDisconnect:withReason:)])
    {
        [self.delegate streamServiceDidDisconnect:self withReason:reason];
    }
}

-(void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message
{
    if (self.delegate &&
        ([self.delegate respondsToSelector:@selector(onStreamServiceMessageCreateFeatures:)] ||
         [self.delegate respondsToSelector:@selector(onStreamServiceMessageUpdateFeatures:)] ||
         [self.delegate respondsToSelector:@selector(onStreamServiceMessageDeleteFeatures:)]))
    {
        NSError *error = nil;
        id messageObject = [NSJSONSerialization JSONObjectWithData:[(NSString *)message dataUsingEncoding:NSUTF8StringEncoding]
                                                           options:NSJSONReadingAllowFragments
                                                             error:&error];
        NSArray *outData = nil;
        BOOL isCreate = NO, isUpdate = NO, isDelete = NO;
        if ([messageObject isKindOfClass:[NSDictionary class]])
        {
            NSDictionary *operationDictionary = messageObject;
            NSString *type = operationDictionary[@"type"];
            id features = operationDictionary[@"feature"];
            if ([features isKindOfClass:[NSArray class]])
            {
                outData = features;
            }
            else
            {
                outData = @[features];
            }
            
            if ([type isEqualToString:@"create"])
            {
                isCreate = YES;
            }
            else if ([type isEqualToString:@"update"])
            {
                isUpdate = YES;
            }
            else if ([type isEqualToString:@"delete"])
            {
                isDelete = YES;
            }
            else
            {
                @throw [NSException exceptionWithName:@"Invalid Parameter!"
                                               reason:@"Stream type must be 'create', 'update', or 'delete'!"
                                             userInfo:nil];
            }
        }
        else if ([messageObject isKindOfClass:[NSArray class]])
        {
            outData = messageObject;
            isCreate = YES;
        }
        else
        {
            outData = @[messageObject];
            isCreate = YES;
        }
        
        if (([self.delegate respondsToSelector:@selector(onStreamServiceMessageCreateFeatures:)] && isCreate) ||
            ([self.delegate respondsToSelector:@selector(onStreamServiceMessageUpdateFeatures:)] && isUpdate) ||
            ([self.delegate respondsToSelector:@selector(onStreamServiceMessageDeleteFeatures:)] && isDelete))
        {
            NSMutableArray *outputGraphics = [NSMutableArray arrayWithCapacity:outData.count];
            for (NSDictionary *rawGraphic in outData) {
                AGSGraphic *g = [[AGSGraphic alloc] initWithJSON:rawGraphic];
                [outputGraphics addObject:g];
            }
            if (isCreate) {
                [self.delegate onStreamServiceMessageCreateFeatures:outputGraphics];
            }
            else if (isUpdate) {
                [self.delegate onStreamServiceMessageUpdateFeatures:outputGraphics];
            }
            else {
                [self.delegate onStreamServiceMessageDeleteFeatures:outputGraphics];
            }
        }
    }
}
@end
