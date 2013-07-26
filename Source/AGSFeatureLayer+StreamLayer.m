//
//  AGSFeatureLayer+StreamLayer.m
//  StreamLayer
//
//  Created by Nicholas Furness on 7/17/13.
//  Copyright (c) 2013 ESRI. All rights reserved.
//

#import "AGSFeatureLayer+StreamLayer.h"
#import <objc/runtime.h>

#define kManageKey @"AGSGraphicsLayer_StreamLayer_ShouldManageFeaturesWhenStreaming"
#define kPurgeCountKey @"AGSGraphicsLayer_StreamLayer_StreamingPurgeCount"
#define kDoNotProjectKey @"AGSGraphicsLayer_StreamLayer_DoNotProjectStreamingDataToLayer"
#define kStreamingAdaptor @"AGSGraphicsLayer_StreamLayer_StreamingAdaptorObject"
#define kStreamingLayerDelegate @"AGSGraphicsLayer_StreamLayer_StreamingLayerDelegate"
#define kStreamLayerOptions @"AGSFeatureLayer_StreamLayer_StreamingLayerOptions"

@interface AGSFeatureLayer (StreamLayer_int) <AGSStreamServiceDelegate>
@property (nonatomic, strong) AGSStreamLayerOptions *streamingOptions;
@end

@implementation AGSFeatureLayer (StreamLayer)
#pragma mark - Class Level Factory Methods
+(AGSFeatureLayer *)streamingFeatureLayerWithOptions:(AGSStreamLayerOptions *)options
{
    return [[AGSFeatureLayer alloc] initWithStreamLayerOptions:options];
}

+(AGSFeatureLayer *)streamingFeatureLayerWithUrl:(NSString *)url
{
    return [AGSFeatureLayer streamingFeatureLayerWithOptions:[AGSStreamLayerOptions streamLayerOptionsWithURL:url
                                                                                          layerDefinitionJSON:nil
                                                                                                   purgeCount:0
                                                                                                 trackIdField:nil]];
}

#pragma mark - Init Methods
-(id)initWithStreamLayerOptions:(AGSStreamLayerOptions *)options
{
    NSDictionary *ld = options.layerDefinitionJSON;
    if (!ld)
    {
        ld = @{@"geometryType": @"esriGeometryPoint",
               @"objectIdField": @"ObjectId",
               @"fields": @[@{@"name": @"ObjectId",
                              @"type": @"esriFieldTypeOID",
                              @"alias": @"ObjectId"}]};
    }
    
    self = [self initWithLayerDefinitionJSON:ld
                              featureSetJSON:@{@"features": @[],
                                               @"geometryType": ld[@"geometryType"]}];
    if (self)
    {
        self.streamingOptions = options;
        self.streamingAdaptor = [[AGSStreamServiceAdaptor alloc] initWithURL:options.url];
        self.streamingAdaptor.delegate = self;
        
        self.shouldManageFeaturesWhenStreaming = YES;
        self.doNotProjectStreamDataToLayer = NO;
    }
    return self;
}

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

-(AGSStreamLayerOptions *)streamingOptions
{
    return objc_getAssociatedObject(self, kStreamLayerOptions);
}

-(void)setStreamingOptions:(AGSStreamLayerOptions *)streamingOptions
{
    objc_setAssociatedObject(self, kStreamLayerOptions, streamingOptions, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

-(BOOL)isConnected
{
    return self.streamingAdaptor?self.streamingAdaptor.isConnected:NO;
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

-(void)onStreamServiceMessageUpdateFeatures:(NSArray *)features
{
    NSMutableArray *outFeatures = [NSMutableArray arrayWithCapacity:features.count];
    
    for (AGSGraphic *g in features)
    {
        if (self.shouldManageFeaturesWhenStreaming)
        {
            // If we're managing the features, they're going to be in the right spatial reference.
            g.geometry = [[AGSGeometryEngine defaultGeometryEngine] projectGeometry:g.geometry
                                                                 toSpatialReference:self.spatialReference];
            // Try to find the existing feature
            int objectId = [self objectIdForFeature:g];
            AGSGraphic *existingGraphic = [self lookupFeatureWithObjectId:objectId];
            if (existingGraphic)
            {
                // Found one. Update the attributes and geometry
                existingGraphic.geometry = g.geometry;
                NSMutableDictionary *updatedAttributes = [existingGraphic.allAttributes mutableCopy];
                [updatedAttributes addEntriesFromDictionary:g.allAttributes];
                [existingGraphic setAllAttributes:updatedAttributes];
            }
            else
            {
                // An update for a features that doesn't exist. Could have been purged.
                // Just add it again.
                DDLogInfo(@"Adding from Update");
                [self addGraphic:g];
                existingGraphic = g;
            }
            [outFeatures addObject:existingGraphic];
        }
        else
        {
            // The features are just being passed through without us managing them on the feature layer
            if (!self.doNotProjectStreamDataToLayer)
            {
                g.geometry = [[AGSGeometryEngine defaultGeometryEngine] projectGeometry:g.geometry
                                                                     toSpatialReference:self.spatialReference];
            }
            [outFeatures addObject:g];
        }
    }
    
    if (self.shouldManageFeaturesWhenStreaming)
    {
        [self _purge];
    }
    
    if (self.streamServiceDelegate && [self.streamServiceDelegate respondsToSelector:@selector(onStreamServiceMessageUpdateFeatures:)])
    {
        [self.streamServiceDelegate onStreamServiceMessageUpdateFeatures:features];
    }
}

-(void)onStreamServiceMessageDeleteFeatures:(NSArray *)features
{
    if (self.shouldManageFeaturesWhenStreaming)
    {
        NSMutableArray *graphicsToRemove = [NSMutableArray arrayWithCapacity:features.count];
        for (AGSGraphic *g in features)
        {
            int objectId = [self objectIdForFeature:g];
            AGSGraphic *existingGraphic = [self lookupFeatureWithObjectId:objectId];
            if (existingGraphic)
            {
                [graphicsToRemove addObject:existingGraphic];
            }
        }
        [self removeGraphics:graphicsToRemove];
    }
    
    if (self.streamServiceDelegate && [self.streamServiceDelegate respondsToSelector:@selector(onStreamServiceMessageDeleteFeatures:)])
    {
        [self.streamServiceDelegate onStreamServiceMessageDeleteFeatures:features];
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
