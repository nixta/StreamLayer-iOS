#import "StreamLayerSampleViewController.h"
#import <ArcGIS/ArcGIS.h>
#import "AGSStreamServiceAdaptor.h"
#import "AGSFlightGraphic.h"

#import "StreamLayerSampleAppDelegate.h"

#import "AGSFeatureLayer+StreamLayer.h"
#import "AGSMapView+UIKitRestoration.h"

#define kBasemapURL @"http://services.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer"
#define kStreamURL @"ws://ec2-107-21-212-168.compute-1.amazonaws.com:8080/asdiflight"

#define kConnectText @"Stream Flight Paths"
#define kConnectingText @"Connecting…"
#define kDisconnectText @"Disconnect Stream"

@interface StreamLayerSampleViewController () <AGSMapViewLayerDelegate, AGSStreamServiceDelegate, AGSMapViewTouchDelegate>
@property (weak, nonatomic) IBOutlet AGSMapView *mapView;

@property (weak, nonatomic) IBOutlet UIButton *toggleConnectionButton;
@property (weak, nonatomic) IBOutlet UIView *trackingView;
@property (weak, nonatomic) IBOutlet UILabel *trackingLabel;

@property (weak, nonatomic) IBOutlet UIView *statusView;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;

@property (nonatomic, strong) AGSGraphicsLayer *streamLayer;
//@property (nonatomic, strong) AGSStreamServiceAdaptor *stream;
//@property (nonatomic, assign) BOOL shouldBeStreaming;
//
//@property (nonatomic, assign) BOOL extentRestored;
//
//@property (nonatomic, strong) NSMutableDictionary *flights;
//
//@property (nonatomic, assign) NSUInteger pointsLoaded;
@end

@implementation StreamLayerSampleViewController
- (void)viewDidLoad
{
    [super viewDidLoad];

//    [self setButtonText:kConnectText];
//    self.shouldBeStreaming = NO;
//    self.flights = [NSMutableDictionary dictionary];

//    [self.mapView enableWrapAround];
    

    NSURL *basemapURL = [NSURL URLWithString:kBasemapURL];
    AGSTiledMapServiceLayer *basemapLayer = [AGSTiledMapServiceLayer tiledMapServiceLayerWithURL:basemapURL];
    
    [self.mapView addMapLayer:basemapLayer];
    
//    self.stream = [[AGSStreamServiceAdaptor alloc] initWithURL:kStreamURL];
//    self.stream.delegate = self;
    
//    self.streamLayer = [[AGSGraphicsLayer alloc] initWithFullEnvelope:nil
//                                                        renderingMode:AGSGraphicsLayerRenderingModeDynamic];

    self.streamLayer = [AGSGraphicsLayer graphicsLayer];

    [self.mapView addMapLayer:self.streamLayer];

    self.mapView.layerDelegate = self;
//    self.mapView.touchDelegate = self;
//    self.mapView.allowRotationByPinching = YES;
}

//-(void)onStreamServiceMessageCreateFeatures:(NSArray *)features
//{
//    dispatch_async(dispatch_get_main_queue(), ^{
//        self.pointsLoaded += features.count;
////        // The Update is an array of AGSGraphics objects. Note that if AGSGraphicsLayer.shouldManageFeaturesWhenStreaming == YES
////        // then the graphics will already have been added to the Graphics Layer and any non-zero purge value will have been
////        // honoured.
////        for (AGSGraphic *flightUpdateGraphic in features)
////        {
////            // Note, we configured the StreamLayer not to project geometries from the raw
////            // stream before presenting them to us back up in viewDidLoad...
////            AGSFlightGraphic *f = [AGSFlightGraphic flightGraphicFromFlights:self.flights
////                                                       consideringRawGraphic:flightUpdateGraphic
////                                                         forSpatialReference:self.mapView.spatialReference];
////            if (!f.layer && ([f.flightNumber isEqualToString:@"UAL769"] ||
////                             [f.flightNumber isEqualToString:@"UAL753"]))
////            {
////                DDLogVerbose(@"Adding flight %@ at %@", f.flightNumber, [NSDate date]);
//////                [self.streamLayer addGraphic:f.trail];
//////                [self.streamLayer addGraphic:f.track];
//////                [self.streamLayer addGraphic:f];
////            }
////        }
//        
//        NSUInteger recentlyUpdatedFlights = 0;
//        NSTimeInterval recencyThreshold = 40; // seconds
//        NSTimeInterval discardThreshold = 60;
//        NSUInteger discardedFlights = 0;
//        NSDate *now = [NSDate date];
//        NSDate *flightTime = nil;
//        NSUInteger maxTimeStamp = 0;
////        for (AGSFlightGraphic *f in self.flights.allValues)
////        {
////            NSTimeInterval timeSinceUpdate = [now timeIntervalSinceDate:f.lastUpdateTime];
////            if (timeSinceUpdate < recencyThreshold)
////            {
////                recentlyUpdatedFlights++;
////                f.isFaded = NO;
////            }
////            else if (timeSinceUpdate >= discardThreshold)
////            {
////                DDLogVerbose(@"Discarding flight %@ which was last updated %f seconds ago", f.flightNumber, timeSinceUpdate);
////                [self.flights removeObjectForKey:f.flightNumber];
////                [self.streamLayer removeGraphics:f.allGraphics];
////                discardedFlights++;
////            }
////            else if (!f.isFaded)
////            {
////                f.isFaded = YES;
////                DDLogVerbose(@"Fading flight %@ which was last updated %f seconds ago", f.flightNumber, timeSinceUpdate);
////            }
////            NSNumber *msgTime = [f attributeForKey:@"msgtime"];
////            if (msgTime)
////            {
////                if (msgTime.longLongValue/1000 > maxTimeStamp) maxTimeStamp = msgTime.longLongValue/1000;
////            }
////        }
//        
//        flightTime = [NSDate dateWithTimeIntervalSince1970:maxTimeStamp];
//        NSDateFormatter *df = [[NSDateFormatter alloc] init];
//        [df setDateFormat:@"yyyy-MM-dd HH:mm:ss zzz"];
//        [df setTimeZone:[NSTimeZone systemTimeZone]];
//        
//        self.trackingLabel.text = [NSString stringWithFormat:@"Tracking %d of %d flights (%d)", recentlyUpdatedFlights, self.flights.count, self.pointsLoaded];
//        self.statusLabel.text = [NSString stringWithFormat:@"(%d) [%d/%d] (%d) %@ [%ds]",
//                                 discardedFlights, recentlyUpdatedFlights,
//                                 self.flights.count, self.streamLayer.graphicsCount,
//                                 [df stringFromDate:flightTime],
//                                 (int)round(((StreamLayerSampleAppDelegate *)[UIApplication sharedApplication].delegate).aliveTime)];
//        
//    });
//}
//
//-(BOOL)prefersStatusBarHidden
//{
//    return YES;
//}
//
//-(void)viewWillDisappear:(BOOL)animated
//{
//    [self.stream disconnect];
//}
//
//-(void)viewDidAppear:(BOOL)animated
//{
//    if (self.shouldBeStreaming)
//    {
//        [self.stream connect];
//    }
//}
//
//-(void)resignActive:(NSNotification *)n
//{
//    [self.stream disconnect];
//}
//
//-(void)becomeActive:(NSNotification *)n
//{
//    if (self.shouldBeStreaming)
//    {
//        [self.stream connect];
//    }
//}

-(void)mapViewDidLoad:(AGSMapView *)mapView
{
//    if (![self.mapView restoreMapViewVisibleArea])
//    {
        AGSEnvelope *initExtent = [AGSEnvelope envelopeWithXmin:-16966135.58841464
                                                           ymin:2551913.339721252
                                                           xmax:-4376555.304442507
                                                           ymax:8529100.339721255
                                               spatialReference:[AGSSpatialReference spatialReferenceWithWKID:102100]];
        [self.mapView zoomToEnvelope:initExtent animated:YES];
//    }
    DDLogVerbose(@"Map View Loaded!!!");
}

//- (IBAction)toggleConnection:(id)sender {
//    if (self.stream.isConnected)
//    {
//        [self.stream disconnect];
//        self.shouldBeStreaming = NO;
//        [self.flights removeAllObjects];
//        [self.streamLayer removeAllGraphics];
//    }
//    else
//    {
//        [self setButtonText:kConnectText];
//        [self.stream connect];
//        self.shouldBeStreaming = YES;
//        self.pointsLoaded = 0;
//    }
//}
//
//-(void)setButtonText:(NSString *)buttonTextKey
//{
//    
//    [UIView animateWithDuration:0.2 animations:^{
//        [self.toggleConnectionButton setTitle:NSLocalizedString(buttonTextKey, nil)
//                                     forState:UIControlStateNormal];
//    }];
//    
//    if ([buttonTextKey isEqualToString:kConnectText])
//    {
//        [UIView animateWithDuration:0.2 animations:^{
//            self.trackingView.alpha = 0;
//        } completion:^(BOOL finished) {
//            self.trackingView.hidden = YES;
//        }];
//    }
//    else
//    {
//        self.trackingView.hidden = NO;
//        [UIView animateWithDuration:0.2
//                         animations:^{
//                             self.trackingView.alpha = 1;
//                         }];
//    }
//}
//
//-(void)streamServiceDidConnect:(AGSStreamServiceAdaptor *)streamLayer
//{
//    [self setButtonText:kDisconnectText];
//}
//
//-(void)streamServiceDidDisconnect:(AGSStreamServiceAdaptor *)streamLayer withReason:(NSString *)reason
//{
//    [self setButtonText:kConnectText];
//    if (!self.shouldBeStreaming)
//    {
//        [self.streamLayer removeAllGraphics];
//    }
//}
//
//-(void)streamServiceDidFailToConnect:(AGSStreamServiceAdaptor *)streamLayer withError:(NSError *)error
//{
//    DDLogError(@"Failed to connect: %@", error);
//    [self setButtonText:kConnectText];
//    self.shouldBeStreaming = NO;
//}
//
//- (void)viewDidUnload {
//    [self setToggleConnectionButton:nil];
//    [super viewDidUnload];
//}
//
//-(void)didReceiveMemoryWarning
//{
//    [super didReceiveMemoryWarning];
//    DDLogWarn(@"Stream View Controller Received Memory Warning!");
//}
@end
