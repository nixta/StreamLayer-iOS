





#import "StreamLayerSampleViewController.h"
#import <ArcGIS/ArcGIS.h>

@interface StreamLayerSampleViewController ()
@property (weak, nonatomic) IBOutlet AGSMapView *mapView;
@end

@implementation StreamLayerSampleViewController
#define kBasemapURL @"http://services.arcgisonline.com/ArcGIS/rest/services/World_Topo_Map/MapServer"

- (void)viewDidLoad
{
    [super viewDidLoad];

    NSURL *basemapURL = [NSURL URLWithString:kBasemapURL];
    AGSTiledMapServiceLayer *basemapLayer = [AGSTiledMapServiceLayer tiledMapServiceLayerWithURL:basemapURL];
    [self.mapView addMapLayer:basemapLayer];

	AGSEnvelope *initExtent = [AGSEnvelope envelopeWithXmin:-14142000
													   ymin:653000
													   xmax:-7880000
													   ymax:9654000
										   spatialReference:[AGSSpatialReference spatialReferenceWithWKID:102100]];
	[self.mapView zoomToEnvelope:initExtent animated:YES];
}
@end
