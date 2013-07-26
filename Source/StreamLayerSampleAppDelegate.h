//
//  EQSAppDelegate.h
//  Basemaps
//
//  Created by Nicholas Furness on 11/29/12.
//  Copyright (c) 2012 ESRI. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface StreamLayerSampleAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic, readonly) NSDate *lauchDate;
@property (assign, nonatomic, readonly) NSTimeInterval aliveTime;

@end
