//
//  GNStreamLayer.h
//  StreamLayer
//
//  Created by Nicholas Furness on 7/11/13.
//  Copyright (c) 2013 ESRI. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <ArcGIS/ArcGIS.h>

@interface GNStreamLayer : AGSGraphicsLayer
-(void)connect:(NSURL *)connectionURL;
-(void)disconnect;
@end
