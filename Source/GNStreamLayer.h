//
//  GNStreamLayer.h
//  StreamLayer
//
//  Created by Nicholas Furness on 7/11/13.
//  Copyright (c) 2013 ESRI. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <ArcGIS/ArcGIS.h>

@class GNStreamLayer;

@protocol GNSteamLayerDelegate <NSObject>
@optional
-(void)streamLayerGotUpdate:(NSArray *)update;

-(void)streamLayerDidConnect:(GNStreamLayer *)streamLayer;
-(void)streamLayerDidFail:(GNStreamLayer *)streamLayer withError:(NSError *)error;

-(void)streamLayerDidDisconnect:(GNStreamLayer *)streamLayer withReason:(NSString *)reason;
@end

@interface GNStreamLayer : AGSGraphicsLayer
@property (nonatomic, weak) id<GNSteamLayerDelegate> streamDelegate;
@property (nonatomic, assign) BOOL isConnected;

-(id)initWithURL:(NSString *)url;
-(id)initWithURL:(NSString *)url purgeCount:(NSUInteger)purgeCount;

-(void)connect;
-(void)disconnect;
@end
