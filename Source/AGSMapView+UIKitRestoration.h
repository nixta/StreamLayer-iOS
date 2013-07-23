//
//  AGSMapView+UIKitRestoration.h
//
//  Created by Nicholas Furness on 7/18/13.
//  Copyright (c) 2013 ESRI. All rights reserved.
//

#import <ArcGIS/ArcGIS.h>

@interface AGSMapViewBase (UIKitRestoration)
@property (nonatomic, readonly) BOOL hasRestorationInfo;
-(BOOL)restoreMapViewVisibleArea;
@end
