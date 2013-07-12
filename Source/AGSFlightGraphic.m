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

@implementation AGSFlightGraphic
#pragma mark - Factory Methods
+(AGSFlightGraphic *)flightGraphicFromGraphic:(AGSGraphic *)rawGraphic
{
    return [[AGSFlightGraphic alloc] initWithRawGraphic:rawGraphic];
}

+(AGSFlightGraphic *)flightGraphicFromFlights:(NSMutableDictionary *)flights
                        consideringRawGraphic:(AGSGraphic *)rawGraphic
{
    NSString *flightIdToFind = [rawGraphic attributeAsStringForKey:kFlightNumberKey];
    AGSFlightGraphic *existingGraphic = [flights objectForKey:flightIdToFind];
    
    if (!existingGraphic)
    {
        existingGraphic = [AGSFlightGraphic flightGraphicFromGraphic:rawGraphic];
        [flights setObject:existingGraphic forKey:existingGraphic.flightNumber];
    }
    else
    {
        NSLog(@"Found existing graphic. Updating...");
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

#pragma mark - Create and update
-(id)initWithRawGraphic:(AGSGraphic *)rawGraphic
{
    self = [super init];
    if (self)
    {
        [self setAllAttributes:[rawGraphic.allAttributes copy]];
        self.geometry = [rawGraphic.geometry copy];
        AGSSimpleMarkerSymbol *currentPositionSymbol =
            [AGSSimpleMarkerSymbol simpleMarkerSymbolWithColor:[UIColor colorWithRed:1
                                                                               green:1
                                                                                blue:1
                                                                               alpha:0.8]];
        currentPositionSymbol.size = CGSizeMake(4, 4);
        currentPositionSymbol.outline = nil;
        self.symbol = currentPositionSymbol;

        AGSMutablePolyline *trailLine = [[AGSMutablePolyline alloc] initWithSpatialReference:self.geometry.spatialReference];
        [trailLine addPathToPolyline];
        [trailLine addPointToPath:(AGSPoint *)self.geometry];
        AGSSimpleLineSymbol *trailSymbol =
            [AGSSimpleLineSymbol simpleLineSymbolWithColor:[UIColor colorWithRed:59/255
                                                                           green:163/255
                                                                            blue:208/255
                                                                           alpha:0.6]];
        self.trail = [AGSGraphic graphicWithGeometry:trailLine
                                              symbol:trailSymbol
                                          attributes:[rawGraphic.allAttributes copy]
                                infoTemplateDelegate:nil];

        AGSMutableMultipoint *trackPoints = [[AGSMutableMultipoint alloc] initWithSpatialReference:self.geometry.spatialReference];
        [trackPoints addPoint:(AGSPoint *)self.geometry];
        AGSSimpleMarkerSymbol *trackSymbol =
            [AGSSimpleMarkerSymbol simpleMarkerSymbolWithColor:[UIColor colorWithRed:240/255
                                                                               green:240/255
                                                                                blue:240/255
                                                                               alpha:0.5]];
        trackSymbol.size = CGSizeMake(1, 1);
        trackSymbol.outline = nil;
        self.track = [AGSGraphic graphicWithGeometry:trackPoints
                                              symbol:trackSymbol
                                          attributes:[rawGraphic.allAttributes copy]
                                infoTemplateDelegate:nil];
}
    return self;
}

-(void)updateWithLatestPositionGraphic:(AGSGraphic *)latestPositionUpdate
{
    // Create one copy of this latest location.
    AGSPoint *latestPoint = [latestPositionUpdate.geometry copy];
    
    // Use it to extend the trail.
//    if (!self.trail)
//    {
//        AGSMutablePolyline *trailLine = [[AGSMutablePolyline alloc] initWithSpatialReference:self.geometry.spatialReference];
//        [trailLine addPathToPolyline];
//        [trailLine addPointToPath:(AGSPoint *)self.geometry];
//        [(AGSMutablePolyline *)self.trail.geometry addPointToPath:latestPoint];
//    }
//    else
//    {
        [(AGSMutablePolyline *)self.trail.geometry addPointToPath:latestPoint];
        self.trail.geometry = self.trail.geometry;
//    }
    
    // And use it to extend the track
//    if (!self.track)
//    {
//    }
//    else
//    {
        [(AGSMutableMultipoint *)self.track.geometry addPoint:latestPoint];
        self.track.geometry = self.track.geometry;
//    }
    
    // And use it to show the latest point
    self.geometry = latestPoint;
}
@end
