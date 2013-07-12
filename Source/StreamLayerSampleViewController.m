





#import "StreamLayerSampleViewController.h"
#import <ArcGIS/ArcGIS.h>
#import "GNStreamLayer.h"

@interface StreamLayerSampleViewController () <AGSMapViewLayerDelegate, GNSteamLayerDelegate>
@property (weak, nonatomic) IBOutlet AGSMapView *mapView;
@property (weak, nonatomic) IBOutlet UIButton *toggleConnectionButton;
@property (nonatomic, strong) GNStreamLayer *streamLayer;
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

    NSURL *basemapURL = [NSURL URLWithString:kBasemapURL];
    AGSTiledMapServiceLayer *basemapLayer = [AGSTiledMapServiceLayer tiledMapServiceLayerWithURL:basemapURL];
    
    [self.mapView addMapLayer:basemapLayer];

    self.streamLayer = [[GNStreamLayer alloc] initWithURL:kStreamURL purgeCount:5000];
    self.streamLayer.streamDelegate = self;
    
    AGSSimpleMarkerSymbol *s = [AGSSimpleMarkerSymbol simpleMarkerSymbolWithColor:[UIColor orangeColor]];
    s.size = CGSizeMake(2, 2);
    s.outline = nil;
    AGSSimpleRenderer *r = [AGSSimpleRenderer simpleRendererWithSymbol:s];
    self.streamLayer.renderer = r;
    
    [self.mapView addMapLayer:self.streamLayer];

    self.mapView.layerDelegate = self;
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
    }
    else
    {
        [self.streamLayer connect];
    }
}

-(void)streamLayerDidConnect:(GNStreamLayer *)streamLayer
{
    [self.toggleConnectionButton setTitle:kDisconnectText forState:UIControlStateNormal];
}

-(void)streamLayerDidDisconnect:(GNStreamLayer *)streamLayer withReason:(NSString *)reason
{
    [self.toggleConnectionButton setTitle:kConnectText forState:UIControlStateNormal];
    [self.streamLayer removeAllGraphics];
}

-(void)streamLayerDidFailToConnect:(GNStreamLayer *)streamLayer withError:(NSError *)error
{
    NSLog(@"Failed to connect: %@", error);
    [self.toggleConnectionButton setTitle:kConnectText forState:UIControlStateNormal];
}

- (void)viewDidUnload {
    [self.streamLayer disconnect];
    [self setToggleConnectionButton:nil];
    [super viewDidUnload];
}
@end