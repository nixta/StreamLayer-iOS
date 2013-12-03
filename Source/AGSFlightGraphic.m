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

#define kResetTrackTrailSeconds 60

@interface AGSFlightGraphic ()
@property (nonatomic, assign) BOOL splitOverWrapAround;
@property (nonatomic, assign) double wrapAroundCorrectionOffset;

@property (nonatomic, strong) AGSGeometry *rawGeometry;
@property (nonatomic, strong) AGSMutablePolyline *rawTrail;
@property (nonatomic, strong) AGSMutableMultipoint *rawTrack;
@property (nonatomic, strong) AGSSpatialReference *targetSR;
@property (nonatomic, strong) AGSSpatialReference *workingSR;

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
        dispatch_async(dispatch_get_main_queue(), ^{
            [existingGraphic updateWithLatestPositionGraphic:rawGraphic];
        });
    }
    
    return existingGraphic;
}


+(AGSSimpleMarkerSymbol *)currentPositionSymbol
{
    static AGSSimpleMarkerSymbol *s = nil;
    if (!s)
    {
        s = [AGSSimpleMarkerSymbol simpleMarkerSymbolWithColor:[UIColor colorWithRed:0.2
                                                                               green:0.67
                                                                                blue:0.94
                                                                               alpha:0.9]];
        s.size = CGSizeMake(4, 4);
        s.outline = nil;
    }
    return s;
}

+(AGSSimpleMarkerSymbol *)trackSymbol
{
    static AGSSimpleMarkerSymbol *s = nil;
    if (!s)
    {
        s = [AGSSimpleMarkerSymbol simpleMarkerSymbolWithColor:[UIColor colorWithRed:0.94
                                                                               green:0.94
                                                                                blue:0.94
                                                                               alpha:0.5]];
        s.size = CGSizeMake(1, 1);
        s.outline = nil;
    }
    return s;
}

+(AGSSimpleLineSymbol *)trailSymbol
{
    static AGSSimpleLineSymbol *s = nil;
    if (!s)
    {
        s = [AGSSimpleLineSymbol simpleLineSymbolWithColor:[UIColor colorWithRed:0.23
                                                                           green:0.7
                                                                            blue:0.9
                                                                           alpha:0.6]];
    }
    return s;
}

+(AGSSimpleMarkerSymbol *)currentPositionSymbolFaded
{
    static AGSSimpleMarkerSymbol *s = nil;
    if (!s)
    {
        s = [[AGSFlightGraphic currentPositionSymbol] copy];
        s.color = [[UIColor redColor] colorWithAlphaComponent:0.4];
    }
    return s;
}

+(AGSSimpleMarkerSymbol *)trackSymbolFaded
{
    static AGSSimpleMarkerSymbol *s = nil;
    if (!s)
    {
        s = [[AGSFlightGraphic trackSymbol] copy];
        s.color = [[UIColor orangeColor] colorWithAlphaComponent:0.3];
    }
    return s;
}

+(AGSSimpleLineSymbol *)trailSymbolFaded
{
    static AGSSimpleLineSymbol *s = nil;
    if (!s)
    {
        s = [[AGSFlightGraphic trailSymbol] copy];
        s.color = [[UIColor yellowColor] colorWithAlphaComponent:0.3];
    }
    return s;
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

-(NSArray *)allGraphics
{
    return @[self, self.trail, self.track];
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
            self.symbol = [AGSFlightGraphic currentPositionSymbolFaded];
            self.trail.symbol = [AGSFlightGraphic trailSymbolFaded];
            self.track.symbol = [AGSFlightGraphic trackSymbolFaded];
        }
        else
        {
            self.symbol = [AGSFlightGraphic currentPositionSymbol];
            self.trail.symbol = [AGSFlightGraphic trailSymbol];
            self.track.symbol = [AGSFlightGraphic trackSymbol];
        }
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
        self.resetTrackInterval = kResetTrackTrailSeconds;
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

        [self setAttributes:[rawGraphic allAttributes]];
        self.rawGeometry = [ge projectGeometry:rawGraphic.geometry toSpatialReference:self.workingSR];
        self.geometry = [ge projectGeometry:rawGraphic.geometry toSpatialReference:self.targetSR];
        self.symbol = [AGSFlightGraphic currentPositionSymbol];

        [self startTrail];
        self.trail = [AGSGraphic graphicWithGeometry:[ge projectGeometry:self.rawTrail toSpatialReference:self.targetSR]
                                              symbol:[AGSFlightGraphic trailSymbol]
                                          attributes:[rawGraphic allAttributes]];

        [self startTrack];
        self.track = [AGSGraphic graphicWithGeometry:[ge projectGeometry:self.rawTrack toSpatialReference:self.targetSR]
                                              symbol:[AGSFlightGraphic trackSymbol]
                                          attributes:[rawGraphic allAttributes]];

    }
    return self;
}

-(void)startTrail
{
    self.rawTrail = [[AGSMutablePolyline alloc] initWithSpatialReference:self.workingSR];
    [self.rawTrail addPathToPolyline];
    [self.rawTrail addPointToPath:(AGSPoint *)self.rawGeometry];
}

-(void)startTrack
{
    self.rawTrack = [[AGSMutableMultipoint alloc] initWithSpatialReference:self.workingSR];
    [self.rawTrack addPoint:(AGSPoint *)self.rawGeometry];
}

-(void)updateWithLatestPositionGraphic:(AGSGraphic *)latestPositionUpdate
{
    // Create a working copy of this latest location in WGS84
    AGSGeometryEngine *ge = [AGSGeometryEngine defaultGeometryEngine];
    AGSPoint *latestPoint = (AGSPoint *)[ge projectGeometry:latestPositionUpdate.geometry
                                         toSpatialReference:self.workingSR];
    
    if (abs([self.lastUpdateTime timeIntervalSinceNow]) >= self.resetTrackInterval)
    {
        // We hadn't heard from this flight for a while, so we'll 
        DDLogInfo(@"Restarting flight %@", self.flightNumber);
        [self startTrack];
        [self startTrail];
    }
    else
    {
        AGSPoint *previousPoint = [self.rawTrack pointAtIndex:self.rawTrack.numPoints-1];
        AGSPoint *thisPoint = latestPoint;
        
        // We do our work in WGS84 (lat/lon)
        if (fabs(thisPoint.x - previousPoint.x) >= self.srWidth)
        {
            double testOffset = self.srWidth * ((thisPoint.x > 0)?-2:2);
            DDLogVerbose(@"Possible wraparound needed. TestOffset = %f", testOffset);
            DDLogVerbose(@"From:\n    %@\nTo: %@", previousPoint, thisPoint);
            AGSPoint *testPoint = [AGSPoint pointWithX:thisPoint.x + testOffset
                                                     y:thisPoint.y
                                      spatialReference:thisPoint.spatialReference];
            if (fabs(testPoint.x - previousPoint.x) < self.srWidth)
            {
                DDLogVerbose(@"Corrected %@\n  To point %@", thisPoint, testPoint);
                // Finish this line path at the "trick" point, and start a new path
                // across the other side of the map where the data is…
                [self.rawTrail addPointToPath:testPoint];
                [self.rawTrail addPathToPolyline];
                
                latestPoint = thisPoint;
            }
        }

        // Extend the trail and track
        [self.rawTrail addPointToPath:latestPoint];
        [self.rawTrack addPoint:latestPoint];
    }

    self.rawGeometry = latestPoint;

    self.geometry = [ge projectGeometry:self.rawGeometry toSpatialReference:self.targetSR];
    self.trail.geometry = [ge projectGeometry:self.rawTrail toSpatialReference:self.targetSR];
    self.track.geometry = [ge projectGeometry:self.rawTrack toSpatialReference:self.targetSR];

    self.lastUpdateTime = [NSDate date];
}

-(void)dealloc
{
    self.rawTrack = nil;
    self.rawTrail = nil;
    self.rawGeometry = nil;
    self.targetSR = nil;
    self.workingSR = nil;
    self.lastUpdateTime = nil;
}
@end
