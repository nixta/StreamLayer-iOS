//
//  AGSGraphicsLayer+StreamLayer.h
//  StreamLayer
//
//  Created by Nicholas Furness on 7/12/13.
//  Copyright (c) 2013 ESRI. All rights reserved.
//

#import <ArcGIS/ArcGIS.h>
#import "AGSStreamServiceAdaptor.h"

@interface AGSGraphicsLayer (StreamLayer) <AGSStreamServiceDelegate>
@property (nonatomic, assign) BOOL shouldManageFeaturesWhenStreaming;
@property (nonatomic, assign) BOOL doNotProjectStreamDataToLayer;
@property (nonatomic, assign) NSUInteger purgeCountForStreaming;
@property (nonatomic, strong) id<AGSStreamServiceDelegate> streamServiceDelegate;

@property (nonatomic, readonly) BOOL isConnected;

@property (nonatomic, strong) AGSStreamServiceAdaptor *streamingAdaptor;

+(AGSGraphicsLayer *)graphicsLayerWithStreamingURL:(NSString *)url;
+(AGSGraphicsLayer *)graphicsLayerWithStreamingURL:(NSString *)url purgeCount:(NSUInteger)purgeCount;

-(void)connect;
-(void)disconnect;
@end
