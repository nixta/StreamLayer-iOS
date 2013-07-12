#import "StreamLayerSampleViewController.h"
#import <ArcGIS/ArcGIS.h>
#import "AGSGraphicsLayer+StreamLayer.h"
#import "AGSFlightGraphic.h"

@interface StreamLayerSampleViewController () <AGSMapViewLayerDelegate, AGSStreamServiceDelegate>
@property (weak, nonatomic) IBOutlet AGSMapView *mapView;
@property (weak, nonatomic) IBOutlet UIButton *toggleConnectionButton;
@property (nonatomic, strong) AGSGraphicsLayer *streamLayer;
@property (nonatomic, assign) BOOL shouldBeStreaming;

@property (nonatomic, strong) NSMutableDictionary *flights;
@end

@implementation StreamLayerSampleViewController
//#define kBasemapURL @"http://services.arcgisonline.com/ArcGIS/rest/services/World_Topo_Map/MapServer"
//#define kBasemapURL @"http://sampleserver6.arcgisonline.com/arcgis/rest/services/WorldTimeZones/MapServer/2"
#define kBasemapURL @"http://services.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer"
#define kStreamURL @"ws://ec2-107-21-212-168.compute-1.amazonaws.com:8080/asdiflight"

#define kConnectText @"Stream Flight Paths"
#define kDisconnectText @"Disconnect Stream Layer"

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self.toggleConnectionButton setTitle:kConnectText forState:UIControlStateNormal];
    self.shouldBeStreaming = NO;
    self.flights = [NSMutableDictionary dictionary];
    
    [self.mapView enableWrapAround];

    NSURL *basemapURL = [NSURL URLWithString:kBasemapURL];
    AGSTiledMapServiceLayer *basemapLayer = [AGSTiledMapServiceLayer tiledMapServiceLayerWithURL:basemapURL];
    
    [self.mapView addMapLayer:basemapLayer];
    
    self.streamLayer = [AGSGraphicsLayer graphicsLayerWithStreamingURL:kStreamURL purgeCount:5000];
    self.streamLayer.shouldManageFeaturesWhenStreaming = NO;
    self.streamLayer.streamServiceDelegate = self;
    
    [self.mapView addMapLayer:self.streamLayer];

    self.mapView.layerDelegate = self;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resignActive:) name:@"ResignActive" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(becomeActive:) name:@"BecomeActive" object:nil];
}

-(void)onStreamServiceMessage:(NSArray *)update
{
    // The Update is an array of AGSGraphics objects. Note that if AGSGraphicsLayer.shouldManageFeaturesWhenStreaming == YES
    // then the graphics will already have been added to the Graphics Layer and any non-zero purge value will have been
    // honoured.
    for (AGSGraphic *flightUpdateGraphic in update)
    {
        AGSFlightGraphic *f = [AGSFlightGraphic flightGraphicFromFlights:self.flights
                                                   consideringRawGraphic:flightUpdateGraphic];
        if (![self.streamLayer.graphics containsObject:f])
        {
            [self.streamLayer addGraphic:f.trail];
            [self.streamLayer addGraphic:f.track];
            [self.streamLayer addGraphic:f];
        }
    }
}

-(BOOL)prefersStatusBarHidden
{
    return YES;
}

-(void)resignActive:(NSNotification *)n
{
    [self.streamLayer disconnect];
}

-(void)becomeActive:(NSNotification *)n
{
    if (self.shouldBeStreaming)
    {
        [self.streamLayer connect];
    }
}

-(void)mapViewDidLoad:(AGSMapView *)mapView
{
	AGSEnvelope *initExtent = [AGSEnvelope envelopeWithXmin:-16966135.58841464
													   ymin:2551913.339721252
													   xmax:-4376555.304442507
													   ymax:8529100.339721255
										   spatialReference:[AGSSpatialReference spatialReferenceWithWKID:102100]];
	[self.mapView zoomToEnvelope:initExtent animated:YES];
}

- (IBAction)toggleConnection:(id)sender {
    if (self.streamLayer.isConnected)
    {
        [self.streamLayer disconnect];
        self.shouldBeStreaming = NO;
    }
    else
    {
        [self.streamLayer connect];
        self.shouldBeStreaming = YES;
    }
}

-(void)streamServiceDidConnect:(AGSStreamServiceAdaptor *)streamLayer
{
    [self.toggleConnectionButton setTitle:kDisconnectText forState:UIControlStateNormal];
}

-(void)streamServiceDidDisconnect:(AGSStreamServiceAdaptor *)streamLayer withReason:(NSString *)reason
{
    [self.toggleConnectionButton setTitle:kConnectText forState:UIControlStateNormal];
    if (!self.shouldBeStreaming)
    {
        [self.streamLayer removeAllGraphics];
    }
}

-(void)streamServiceDidFailToConnect:(AGSStreamServiceAdaptor *)streamLayer withError:(NSError *)error
{
    NSLog(@"Failed to connect: %@", error);
    [self.toggleConnectionButton setTitle:kConnectText forState:UIControlStateNormal];
    self.shouldBeStreaming = NO;
}

- (void)viewDidUnload {
//    [self.streamLayer disconnect];
    [self setToggleConnectionButton:nil];
    [super viewDidUnload];
}
@end
