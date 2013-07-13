//
//  AGSFlightGraphic.h
//  StreamLayer
//
//  Created by Nicholas Furness on 7/12/13.
//  Copyright (c) 2013 ESRI. All rights reserved.
//

#import <ArcGIS/ArcGIS.h>

@interface AGSFlightGraphic : AGSGraphic
@property (nonatomic, strong) AGSGraphic *trail;
@property (nonatomic, strong) AGSGraphic *track;

@property (nonatomic, strong) NSString *flightNumber;
@property (nonatomic, readonly) double altitude;
@property (nonatomic, readonly) double heading;
@property (nonatomic, strong, readonly) NSDate *lastUpdateTime;

//+(AGSFlightGraphic *)flightGraphicFromGraphic:(AGSGraphic *)rawGraphic;
+(AGSFlightGraphic *)flightGraphicFromFlights:(NSDictionary *)flights
                        consideringRawGraphic:(AGSGraphic *)rawGraphic;

-(void)updateWithLatestPositionGraphic:(AGSGraphic *)latestPositionUpdate;
@end
