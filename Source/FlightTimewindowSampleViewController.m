//
//  FlightTimewindowSampleViewController.m
//  StreamLayer
//
//  Created by Nicholas Furness on 7/17/13.
//  Copyright (c) 2013 ESRI. All rights reserved.
//

#import "FlightTimewindowSampleViewController.h"
#import "AGSFeatureLayer+StreamLayer.h"
#import <ArcGIS/ArcGIS.h>

#import "AGSMapView+UIKitRestoration.h"

//#define kBasemapURL @"http://services.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer"
// For easier screenshot issue demo
#define kBasemapURL @"http://services.arcgisonline.com/ArcGIS/rest/services/World_Topo_Map/MapServer"
#define kStreamURLTimeFlight @"ws://ec2-107-21-212-168.compute-1.amazonaws.com:8080/flights"

#define kConnectText @"Connect Time-aware Stream"
#define kConnectingText @"Connecting…"
#define kDisconnectText @"Disconnect Stream"

@interface FlightTimewindowSampleViewController ()
    <AGSMapViewLayerDelegate, AGSStreamServiceDelegate, AGSMapViewTouchDelegate>
@property (weak, nonatomic) IBOutlet AGSMapView *mapView;
@property (weak, nonatomic) IBOutlet UIButton *toggleConnectionButton;

@property (nonatomic, strong) AGSFeatureLayer *streamingFeatureLayer;
@property (nonatomic, assign) BOOL shouldBeStreaming;
@end

@implementation FlightTimewindowSampleViewController
- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    [self setButtonText:kConnectText];
    self.shouldBeStreaming = NO;

    NSURL *basemapURL = [NSURL URLWithString:kBasemapURL];
    AGSTiledMapServiceLayer *basemapLayer = [AGSTiledMapServiceLayer tiledMapServiceLayerWithURL:basemapURL];
    
    [self.mapView addMapLayer:basemapLayer];
    
    self.mapView.layerDelegate = self;
    self.mapView.touchDelegate = self;
    [self.mapView enableWrapAround];
    
    NSString *jsonPath = [[NSBundle mainBundle] pathForResource:@"layerDefinition" ofType:@"json"];
    NSData *jsonData = [NSData dataWithContentsOfFile:jsonPath];
    NSError *error = nil;
    id data = [NSJSONSerialization JSONObjectWithData:jsonData
                                              options:NSJSONReadingAllowFragments
                                                error:&error];
    if (!error)
    {
        AGSStreamLayerOptions *streamOptions = [AGSStreamLayerOptions streamLayerOptionsWithURL:kStreamURLTimeFlight
                                                                            layerDefinitionJSON:data
                                                                                     purgeCount:0
                                                                                   trackIdField:@"flight_id"];
        self.streamingFeatureLayer = [AGSFeatureLayer streamingFeatureLayerWithOptions:streamOptions];

        AGSSimpleMarkerSymbol *pointSymbol = [AGSSimpleMarkerSymbol simpleMarkerSymbolWithColor:[UIColor colorWithRed:0.02
                                                                                                                green:0.44
                                                                                                                 blue:0.69
                                                                                                                alpha:1]];
        pointSymbol.outline = nil;
        self.streamingFeatureLayer.renderer = [AGSSimpleRenderer simpleRendererWithSymbol:pointSymbol];
        self.streamingFeatureLayer.streamServiceDelegate = self;

        [self.mapView addMapLayer:self.streamingFeatureLayer];
        NSLog(@"%@ with %@", self.streamingFeatureLayer, self.streamingFeatureLayer.timeInfo);
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resignActive:) name:@"ResignActive" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(becomeActive:) name:@"BecomeActive" object:nil];
}

-(BOOL)prefersStatusBarHidden
{
    return YES;
}

-(void)viewWillDisappear:(BOOL)animated
{
    [self.streamingFeatureLayer disconnect];
}

-(void)viewDidAppear:(BOOL)animated
{
    if (self.shouldBeStreaming)
    {
        [self.streamingFeatureLayer connect];
    }
}

-(void)resignActive:(NSNotification *)n
{
    [self.streamingFeatureLayer disconnect];
}

-(void)becomeActive:(NSNotification *)n
{
    if (self.shouldBeStreaming)
    {
        [self.streamingFeatureLayer connect];
    }
}

-(void)mapViewDidLoad:(AGSMapView *)mapView
{
    if (![self.mapView restoreMapViewVisibleArea])
    {
        AGSEnvelope *initExtent = [AGSEnvelope envelopeWithXmin:-16966135.58841464
                                                           ymin:2551913.339721252
                                                           xmax:-4376555.304442507
                                                           ymax:8529100.339721255
                                               spatialReference:[AGSSpatialReference spatialReferenceWithWKID:102100]];
        [self.mapView zoomToEnvelope:initExtent animated:YES];
    }
}

- (IBAction)toggleConnection:(id)sender {
    if (self.streamingFeatureLayer.isConnected)
    {
        [self.streamingFeatureLayer disconnect];
        self.shouldBeStreaming = NO;
    }
    else
    {
        [self setButtonText:kConnectingText];
        [self.streamingFeatureLayer connect];
        self.shouldBeStreaming = YES;
    }
}

-(void)setButtonText:(NSString *)buttonTextKey
{
    [UIView animateWithDuration:0.2 animations:^{
        [self.toggleConnectionButton setTitle:NSLocalizedString(buttonTextKey, nil) forState:UIControlStateNormal];
    }];
}

-(void)streamServiceDidConnect:(AGSStreamServiceAdaptor *)streamLayer
{
    [self setButtonText:kDisconnectText];
}

-(void)streamServiceDidDisconnect:(AGSStreamServiceAdaptor *)streamLayer withReason:(NSString *)reason
{
    [self setButtonText:kConnectText];
    if (!self.shouldBeStreaming)
    {
        [self.streamingFeatureLayer removeAllGraphics];
    }
}

-(void)streamServiceDidFailToConnect:(AGSStreamServiceAdaptor *)streamLayer withError:(NSError *)error
{
    NSLog(@"Failed to connect: %@", error);
    [self setButtonText:kConnectText];
    self.shouldBeStreaming = NO;
}
@end
