//
//  AGSStreamLayerOptions.m
//  StreamLayer
//
//  Created by Nicholas Furness on 7/17/13.
//  Copyright (c) 2013 ESRI. All rights reserved.
//

#import "AGSStreamLayerOptions.h"

@implementation AGSStreamLayerOptions
+(AGSStreamLayerOptions *)streamLayerOptionsWithURL:(NSString *)url
                                layerDefinitionJSON:(NSDictionary *)layerDefinitionJSON
                                         purgeCount:(NSUInteger)purgeCount
                                       trackIdField:(NSString *)trackIdField
{
    return [[AGSStreamLayerOptions alloc] initWithURL:url layerDefinitionJSON:layerDefinitionJSON purgeCount:purgeCount trackIdField:trackIdField];
}

-(id)initWithURL:(NSString *)url layerDefinitionJSON:(NSDictionary *)layerDefinitionJSON
      purgeCount:(NSUInteger)purgeCount
    trackIdField:(NSString *)trackIdField
{
    self = [super init];
    if (self)
    {
        _url = url;
        _layerDefinitionJSON = layerDefinitionJSON;
        _purgeCount = purgeCount;
        _trackIdField = trackIdField;
    }
    return self;
}
@end
