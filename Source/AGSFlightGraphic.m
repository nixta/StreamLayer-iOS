//
//  AGSFlightGraphic.m
//  StreamLayer
//
//  Created by Nicholas Furness on 7/12/13.
//  Copyright (c) 2013 ESRI. All rights reserved.
//

#import "AGSFlightGraphic.h"

#define kFlightNumberKey @"FltId"
#define kAltitudeKey @"AltitudeFeet"
#define kHeadingKey @"Heading"

@interface AGSFlightGraphic ()
@property (nonatomic, assign) BOOL splitOverWrapAround;
@property (nonatomic, assign) double wrapAroundCorrectionOffset;

@property (nonatomic, strong) AGSGeometry *rawGeometry;
@property (nonatomic, strong) AGSMutablePolyline *rawTrail;
@property (nonatomic, strong) AGSMutableMultipoint *rawTrack;
@property (nonatomic, strong) AGSSpatialReference *targetSR;
@property (nonatomic, strong) AGSSpatialReference *workingSR;

@property (nonatomic, strong) AGSSimpleMarkerSymbol *currentPositionSymbol;
@property (nonatomic, strong) AGSSimpleLineSymbol *trailSymbol;
@property (nonatomic, strong) AGSSimpleMarkerSymbol *trackSymbol;
@property (nonatomic, strong) AGSSimpleMarkerSymbol *currentPositionSymbolFaded;
@property (nonatomic, strong) AGSSimpleLineSymbol *trailSymbolFaded;
@property (nonatomic, strong) AGSSimpleMarkerSymbol *trackSymbolFaded;

@property (nonatomic, assign) double srWidth;

@property (nonatomic, strong) NSDate *lastUpdateTime;
@end

@implementation AGSFlightGraphic
@synthesize isFaded = _isFaded;

#pragma mark - Factory Methods
+(AGSFlightGraphic *)flightGraphicFromGraphic:(AGSGraphic *)rawGraphic
{
    return [[AGSFlightGraphic alloc] initWithRawGraphic:rawGraphic forSpatialReference:nil];
}

+(AGSFlightGraphic *)flightGraphicFromGraphic:(AGSGraphic *)rawGraphic forSpatialReference:(AGSSpatialReference *)sr
{
    return [[AGSFlightGraphic alloc] initWithRawGraphic:rawGraphic forSpatialReference:sr];
}

+(AGSFlightGraphic *)flightGraphicFromFlights:(NSMutableDictionary *)flights
                        consideringRawGraphic:(AGSGraphic *)rawGraphic
{
    return [AGSFlightGraphic flightGraphicFromFlights:flights
                                consideringRawGraphic:rawGraphic
                                  forSpatialReference:nil];
}

+(AGSFlightGraphic *)flightGraphicFromFlights:(NSMutableDictionary *)flights
                        consideringRawGraphic:(AGSGraphic *)rawGraphic
                          forSpatialReference:(AGSSpatialReference *)spatialReference
{
    NSString *flightIdToFind = [rawGraphic attributeAsStringForKey:kFlightNumberKey];
    AGSFlightGraphic *existingGraphic = [flights objectForKey:flightIdToFind];
    
    if (!existingGraphic)
    {
        existingGraphic = [AGSFlightGraphic flightGraphicFromGraphic:rawGraphic forSpatialReference:spatialReference];
        [flights setObject:existingGraphic forKey:existingGraphic.flightNumber];
    }
    else
    {
        [existingGraphic updateWithLatestPositionGraphic:rawGraphic];
    }
    
    return existingGraphic;
}


#pragma mark - Readonly Properties

-(NSString *)flightNumber
{
    return [self attributeAsStringForKey:kFlightNumberKey];
}

-(double)altitude
{
    return [self attributeAsDoubleForKey:kAltitudeKey exists:nil];
}

-(double)heading
{
    return [self attributeAsDoubleForKey:kHeadingKey exists:nil];
}

-(BOOL)isFaded
{
    return _isFaded;
}

-(void)setIsFaded:(BOOL)isFaded
{
    if (_isFaded != isFaded)
    {
        _isFaded = isFaded;
        if (isFaded)
        {
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                NSLog(@"Fading in NSOperationQueue %@", self.flightNumber);
                self.symbol = self.currentPositionSymbolFaded;
                self.trail.symbol = self.trailSymbolFaded;
                self.track.symbol = self.trackSymbolFaded;
            }];
        }
        else
        {
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                NSLog(@"Un-Fading in NSOperationQueue %@", self.flightNumber);
                self.symbol = self.currentPositionSymbol;
                self.trail.symbol = self.trailSymbol;
                self.track.symbol = self.trackSymbol;
            }];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
        });
    }
}

#pragma mark - Create and update
-(id)initWithRawGraphic:(AGSGraphic *)rawGraphic forSpatialReference:(AGSSpatialReference *)sr
{
    self = [super init];
    if (self)
    {
        _isFaded = NO;
        self.lastUpdateTime = [NSDate date];
        self.srWidth = 180;
        if (sr)
        {
            self.targetSR = sr;
        }
        else
        {
            self.targetSR = rawGraphic.geometry.spatialReference;
        }
        
        // For flight data we can work in WGS84
        self.workingSR = [AGSSpatialReference wgs84SpatialReference];
        
        AGSGeometryEngine *ge = [AGSGeometryEngine defaultGeometryEngine];

        [self setAllAttributes:[rawGraphic.allAttributes copy]];
        self.rawGeometry = [ge projectGeometry:rawGraphic.geometry toSpatialReference:self.workingSR];
        self.geometry = [ge projectGeometry:rawGraphic.geometry toSpatialReference:self.targetSR];
        self.currentPositionSymbol =
            [AGSSimpleMarkerSymbol simpleMarkerSymbolWithColor:[UIColor colorWithRed:0.2
                                                                               green:0.67
                                                                                blue:0.94
                                                                               alpha:0.9]];
        self.currentPositionSymbol.size = CGSizeMake(4, 4);
        self.currentPositionSymbol.outline = nil;
        self.symbol = self.currentPositionSymbol;

        self.rawTrail = [[AGSMutablePolyline alloc] initWithSpatialReference:self.workingSR];
        [self.rawTrail addPathToPolyline];
        [self.rawTrail addPointToPath:(AGSPoint *)self.rawGeometry];
        self.trailSymbol =
            [AGSSimpleLineSymbol simpleLineSymbolWithColor:[UIColor colorWithRed:59/255
                                                                           green:163/255
                                                                            blue:208/255
                                                                           alpha:0.6]];
        self.trail = [AGSGraphic graphicWithGeometry:[ge projectGeometry:self.rawTrail toSpatialReference:self.targetSR]
                                              symbol:self.trailSymbol
                                          attributes:[rawGraphic.allAttributes copy]
                                infoTemplateDelegate:nil];

        self.rawTrack = [[AGSMutableMultipoint alloc] initWithSpatialReference:self.workingSR];
        [self.rawTrack addPoint:(AGSPoint *)self.rawGeometry];
        self.trackSymbol =
            [AGSSimpleMarkerSymbol simpleMarkerSymbolWithColor:[UIColor colorWithRed:240/255
                                                                               green:240/255
                                                                                blue:240/255
                                                                               alpha:0.5]];
        self.trackSymbol.size = CGSizeMake(1, 1);
        self.trackSymbol.outline = nil;
        self.track = [AGSGraphic graphicWithGeometry:[ge projectGeometry:self.rawTrack toSpatialReference:self.targetSR]
                                              symbol:self.trackSymbol
                                          attributes:[rawGraphic.allAttributes copy]
                                infoTemplateDelegate:nil];

        self.currentPositionSymbolFaded = [self.currentPositionSymbol copy];
        self.currentPositionSymbolFaded.color = [[UIColor redColor] colorWithAlphaComponent:0.4];
        self.trailSymbolFaded = [self.trailSymbol copy];
        self.trailSymbolFaded.color = [[UIColor orangeColor] colorWithAlphaComponent:0.3];
        self.trackSymbolFaded = [self.trackSymbol copy];
        self.trackSymbolFaded.color = [[UIColor yellowColor] colorWithAlphaComponent:0.3];
    }
    return self;
}

-(void)updateWithLatestPositionGraphic:(AGSGraphic *)latestPositionUpdate
{
    // Create one copy of this latest location.
    AGSGeometryEngine *ge = [AGSGeometryEngine defaultGeometryEngine];
    AGSPoint *latestPoint = (AGSPoint *)[ge projectGeometry:latestPositionUpdate.geometry toSpatialReference:self.workingSR];
    
    AGSPoint *previousPoint = [self.rawTrack pointAtIndex:self.rawTrack.numPoints-1];
    AGSPoint *thisPoint = latestPoint ;
    
    // For right now, we're assuming all points come in as WGS84 (lat/lon)
    if (fabs(thisPoint.x - previousPoint.x) >= self.srWidth)
    {
        double testOffset = self.srWidth * ((thisPoint.x > 0)?-2:2);
//        NSLog(@"Possible wraparound needed. TestOffset = %f", testOffset);
//        NSLog(@"From:\n    %@\nTo: %@", previousPoint, thisPoint);
        AGSPoint *testPoint = [AGSPoint pointWithX:thisPoint.x + testOffset
                                                 y:thisPoint.y
                                  spatialReference:thisPoint.spatialReference];
        if (fabs(testPoint.x - previousPoint.x) < self.srWidth)
        {
            NSLog(@"Corrected %@\n  To point %@", thisPoint, testPoint);
            // Finish this line path at the "trick" point, and start a new path
            // across the other side of the map where the data is…
            [self.rawTrail addPointToPath:testPoint];
            [self.rawTrail addPathToPolyline];
            
            latestPoint = thisPoint;
        }
    }
    
    // Extend the trail.
    [self.rawTrail addPointToPath:latestPoint];
    self.trail.geometry = [ge projectGeometry:self.rawTrail toSpatialReference:self.targetSR];

    // Add to the track.
    [self.rawTrack addPoint:latestPoint];
    self.track.geometry = [ge projectGeometry:self.rawTrack toSpatialReference:self.targetSR];
    
    // And show the latest point
    self.rawGeometry = latestPoint;
    self.geometry = [ge projectGeometry:self.rawGeometry toSpatialReference:self.targetSR];
    
    self.lastUpdateTime = [NSDate date];
}
@end
