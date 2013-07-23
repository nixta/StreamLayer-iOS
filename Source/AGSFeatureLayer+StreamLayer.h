//
//  AGSFeatureLayer+StreamLayer.h
//  StreamLayer
//
//  Created by Nicholas Furness on 7/17/13.
//  Copyright (c) 2013 ESRI. All rights reserved.
//

#import <ArcGIS/ArcGIS.h>
#import "AGSStreamServiceAdaptor.h"
#import "AGSStreamLayerOptions.h"

@interface AGSFeatureLayer (StreamLayer) <AGSStreamServiceDelegate>
#pragma mark - Construction
+(AGSFeatureLayer *)streamingFeatureLayerWithOptions:(AGSStreamLayerOptions *)options;
+(AGSFeatureLayer *)streamingFeatureLayerWithUrl:(NSString *)url;

#pragma mark - Properties
@property (nonatomic, strong, readonly) AGSStreamLayerOptions *streamingOptions;

@property (nonatomic, assign) BOOL shouldManageFeaturesWhenStreaming;
@property (nonatomic, assign) BOOL doNotProjectStreamDataToLayer;
@property (nonatomic, assign) NSUInteger purgeCountForStreaming;
@property (nonatomic, strong) id<AGSStreamServiceDelegate> streamServiceDelegate;

@property (nonatomic, readonly) BOOL isConnected;

@property (nonatomic, strong) AGSStreamServiceAdaptor *streamingAdaptor;

#pragma mark - Methods
-(void)connect;
-(void)disconnect;
@end
