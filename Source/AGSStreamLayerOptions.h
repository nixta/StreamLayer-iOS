//
//  AGSStreamLayerOptions.h
//  StreamLayer
//
//  Created by Nicholas Furness on 7/17/13.
//  Copyright (c) 2013 ESRI. All rights reserved.
//

#import <ArcGIS/ArcGIS.h>
#import <Foundation/Foundation.h>

@interface AGSStreamLayerOptions : NSObject
@property (nonatomic, strong, readonly) NSString *url;
@property (nonatomic, strong, readonly) NSDictionary *layerDefinitionJSON;
@property (nonatomic, assign, readonly) NSUInteger purgeCount;
@property (nonatomic, strong, readonly) NSString *trackIdField;

+(AGSStreamLayerOptions *)streamLayerOptionsWithURL:(NSString *)url
                                layerDefinitionJSON:(NSDictionary *)layerDefinitionJSON
                                         purgeCount:(NSUInteger)purgeCount
                                       trackIdField:(NSString *)trackIdField;
@end
