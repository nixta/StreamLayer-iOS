//
//  GNStreamLayer.h
//  StreamLayer
//
//  Created by Nicholas Furness on 7/11/13.
//  Copyright (c) 2013 ESRI. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <ArcGIS/ArcGIS.h>

@class AGSStreamServiceAdaptor;

@protocol AGSStreamServiceDelegate <NSObject>
@optional
-(void)onStreamServiceMessage:(NSArray *)update;

-(void)streamServiceDidConnect:(AGSStreamServiceAdaptor *)serviceAdaptor;
-(void)streamServiceDidFail:(AGSStreamServiceAdaptor *)serviceAdaptor withError:(NSError *)error;

-(void)streamServiceDidDisconnect:(AGSStreamServiceAdaptor *)serviceAdaptor withReason:(NSString *)reason;
@end


@interface AGSStreamServiceAdaptor : AGSGraphicsLayer
@property (nonatomic, weak) id<AGSStreamServiceDelegate> delegate;
@property (nonatomic, readonly) BOOL isConnected;

-(id)initWithURL:(NSString *)url;
-(id)initWithURL:(NSString *)url purgeCount:(NSUInteger)purgeCount;

-(void)connect;
-(void)disconnect;
@end
