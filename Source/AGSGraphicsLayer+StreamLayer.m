//
//  AGSGraphicsLayer+StreamLayer.m
//  StreamLayer
//
//  Created by Nicholas Furness on 7/12/13.
//  Copyright (c) 2013 ESRI. All rights reserved.
//

#import "AGSGraphicsLayer+StreamLayer.h"
#import <objc/runtime.h>

#define kManageKey @"AGSGraphicsLayer_StreamLayer_ShouldManageFeaturesWhenStreaming"
#define kPurgeCountKey @"AGSGraphicsLayer_StreamLayer_StreamingPurgeCount"
#define kDoNotProjectKey @"AGSGraphicsLayer_StreamLayer_DoNotProjectStreamingDataToLayer"
#define kStreamingAdaptor @"AGSGraphicsLayer_StreamLayer_StreamingAdaptorObject"
#define kStreamingLayerDelegate @"AGSGraphicsLayer_StreamLayer_StreamingLayerDelegate"

@interface AGSGraphicsLayer (StreamLayer_internal) <AGSStreamServiceDelegate>

@end

@implementation AGSGraphicsLayer (StreamLayer)
#pragma mark - Properties
-(BOOL)shouldManageFeaturesWhenStreaming
{
    NSNumber *b = objc_getAssociatedObject(self, kManageKey);
    return b?[b boolValue]:NO;
}

-(void)setShouldManageFeaturesWhenStreaming:(BOOL)shouldManageFeaturesWhenStreaming
{
    objc_setAssociatedObject(self, kManageKey, [NSNumber numberWithBool:shouldManageFeaturesWhenStreaming], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

-(BOOL)doNotProjectStreamDataToLayer
{
    NSNumber *b = objc_getAssociatedObject(self, kDoNotProjectKey);
    return b?[b boolValue]:NO;
}

-(void)setDoNotProjectStreamDataToLayer:(BOOL)doNotProjectStreamDataToLayer
{
    objc_setAssociatedObject(self, kDoNotProjectKey, [NSNumber numberWithBool:doNotProjectStreamDataToLayer], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

-(NSUInteger)purgeCountForStreaming
{
    NSNumber *p = objc_getAssociatedObject(self, kPurgeCountKey);
    return p?[p unsignedIntegerValue]:0;
}

-(void)setPurgeCountForStreaming:(NSUInteger)purgeCountForStreaming
{
    objc_setAssociatedObject(self, kPurgeCountKey, [NSNumber numberWithUnsignedInteger:purgeCountForStreaming], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

-(void)setStreamingAdaptor:(AGSStreamServiceAdaptor *)streamingAdaptor
{
    objc_setAssociatedObject(self, kStreamingAdaptor, streamingAdaptor, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

-(AGSStreamServiceAdaptor *)streamingAdaptor
{
    return objc_getAssociatedObject(self, kStreamingAdaptor);
}

-(id<AGSStreamServiceDelegate>)streamServiceDelegate
{
    return objc_getAssociatedObject(self, kStreamingLayerDelegate);
}

-(void)setStreamServiceDelegate:(id<AGSStreamServiceDelegate>)streamServiceDelegate
{
    objc_setAssociatedObject(self, kStreamingLayerDelegate, streamServiceDelegate, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

-(BOOL)isConnected
{
    return self.streamingAdaptor?self.streamingAdaptor.isConnected:NO;
}

#pragma mark - Class Level Factory Methods
+(AGSGraphicsLayer *)graphicsLayerWithStreamingURL:(NSString *)url
{
    return [AGSGraphicsLayer graphicsLayerWithStreamingURL:url purgeCount: 0];
}

+(AGSGraphicsLayer *)graphicsLayerWithStreamingURL:(NSString *)url purgeCount:(NSUInteger)purgeCount
{
    AGSGraphicsLayer *newLayer = [[AGSGraphicsLayer alloc] initWithSpatialReference:[AGSSpatialReference wgs84SpatialReference]];
    newLayer.streamingAdaptor = [[AGSStreamServiceAdaptor alloc] initWithURL:url];
    newLayer.streamingAdaptor.streamServiceDelegate = newLayer;
    return newLayer;
}

#pragma mark - Streaming
-(void)streamServiceDidConnect:(AGSStreamServiceAdaptor *)serviceAdaptor
{
    if (self.streamServiceDelegate && [self.streamServiceDelegate respondsToSelector:@selector(streamServiceDidConnect:)])
    {
        [self.streamServiceDelegate streamServiceDidConnect:serviceAdaptor];
    }
}

-(void)streamServiceDidDisconnect:(AGSStreamServiceAdaptor *)serviceAdaptor withReason:(NSString *)reason
{
    if (self.streamServiceDelegate && [self.streamServiceDelegate respondsToSelector:@selector(streamServiceDidDisconnect:withReason:)])
    {
        [self.streamServiceDelegate streamServiceDidDisconnect:serviceAdaptor withReason:reason];
    }
}

-(void)streamServiceDidFail:(AGSStreamServiceAdaptor *)serviceAdaptor withError:(NSError *)error
{
    if (self.streamServiceDelegate && [self.streamServiceDelegate respondsToSelector:@selector(streamServiceDidFail:withError:)])
    {
        [self.streamServiceDelegate streamServiceDidFail:serviceAdaptor withError:error];
    }
}

-(void)onStreamServiceMessageCreateFeatures:(NSArray *)features
{
    if (!self.doNotProjectStreamDataToLayer)
    {
        for (AGSGraphic *g in features) {
            g.geometry = [[AGSGeometryEngine defaultGeometryEngine] projectGeometry:g.geometry
                                                                 toSpatialReference:self.mapView.spatialReference];
        }
    }

    if (self.shouldManageFeaturesWhenStreaming)
    {
        [self addGraphics:features];
        [self _purge];
    }
    
    if (self.streamServiceDelegate && [self.streamServiceDelegate respondsToSelector:@selector(onStreamServiceMessageCreateFeatures:)])
    {
        [self.streamServiceDelegate onStreamServiceMessageCreateFeatures:features];
    }
}

-(void)connect
{
    [self.streamingAdaptor connect];
}

-(void)disconnect
{
    [self.streamingAdaptor disconnect];
    if (self.shouldManageFeaturesWhenStreaming)
    {
        [self removeAllGraphics];
    }
}


-(void)_purge
{
    if (self.purgeCountForStreaming > 0 && self.graphicsCount > self.purgeCountForStreaming)
    {
        NSUInteger numberToPurge = self.graphicsCount - self.purgeCountForStreaming;
        NSMutableArray *graphicsToPurge = [NSMutableArray arrayWithCapacity:numberToPurge];
        for (NSInteger i = 0; i < numberToPurge ; i++) {
            [graphicsToPurge addObject:self.graphics[i]];
        }
        [self removeGraphics:graphicsToPurge];
    }
}
@end
