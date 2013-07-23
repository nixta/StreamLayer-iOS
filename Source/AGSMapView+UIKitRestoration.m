//
//  AGSMapView+UIKitRestoration.m
//
//  Created by Nicholas Furness on 7/18/13.
//  Copyright (c) 2013 ESRI. All rights reserved.
//

#import "AGSMapView+UIKitRestoration.h"
#import <objc/runtime.h>

#define kExtentRestoredKey @"AGSMapView_UIKitRestorationCategory_ExtentRestored_Key"
#define kEncoderRotationAngleKey @"MapRotation"
#define kEncoderCenterPointKey @"CenterPoint"
#define kEncoderMapScaleKey @"MapScale"

#define kCenterPointKey @"AGSMapView_UIKitRestorationCategory_CenterPoint_Key"
#define kScaleKey @"AGSMapView_UIKitRestorationCategory_Scale_Key"
#define kRotationKey @"AGSMapView_UIKitRestorationCategory_Rotation_Key"

@interface AGSMapViewBase (UIKitRestoration_Internal) <AGSMapViewLayerDelegate>
@end

@implementation AGSMapViewBase (UIKitRestoration)
-(BOOL)visibleAreaRestored
{
    NSNumber *b = objc_getAssociatedObject(self, kExtentRestoredKey);
    return b?[b boolValue]:NO;
}

-(void)setVisibleAreaRestored:(BOOL)visibleAreaRestored
{
    objc_setAssociatedObject(self, kExtentRestoredKey, [NSNumber numberWithBool:visibleAreaRestored], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

-(void)encodeRestorableStateWithCoder:(NSCoder *)coder
{
    [super encodeRestorableStateWithCoder:coder];
    
    AGSPoint *centerPt = (AGSPoint *)[[AGSGeometryEngine defaultGeometryEngine] normalizeCentralMeridianOfGeometry:self.visibleAreaEnvelope.center];
    double scale = self.mapScale;
    double rotationAngle = self.rotationAngle;
    
//    NSLog(@"Storing scale %f angle %f around %@", scale, rotationAngle, centerPt);

    [coder encodeObject:[centerPt encodeToJSON] forKey:kEncoderCenterPointKey];
    [coder encodeDouble:rotationAngle forKey:kEncoderRotationAngleKey];
    [coder encodeDouble:scale forKey:kEncoderMapScaleKey];
}

-(BOOL)hasRestorationInfo
{
    if ([objc_getAssociatedObject(self, kCenterPointKey) isKindOfClass:[AGSPoint class]] &&
        [objc_getAssociatedObject(self, kScaleKey) isKindOfClass:[NSNumber class]] &&
        [objc_getAssociatedObject(self, kRotationKey) isKindOfClass:[NSNumber class]])
    {
        return YES;
    }
    return NO;
}

-(BOOL)restoreMapViewVisibleArea
{
    if (self.hasRestorationInfo)
    {
        AGSPoint *centerPt = objc_getAssociatedObject(self, kCenterPointKey);
        double scale = ((NSNumber *)objc_getAssociatedObject(self, kScaleKey)).doubleValue;
        double rotationAngle = ((NSNumber *)objc_getAssociatedObject(self, kRotationKey)).doubleValue;
        
//        NSLog(@"Setting Map to scale %f angle %f around %@", scale, rotationAngle, centerPt);
        
        [self zoomToScale:scale animated:NO];
        [self centerAtPoint:centerPt animated:NO];
        [self setRotationAngle:rotationAngle animated:NO];

        return YES;
    }
    return NO;
}

-(void)decodeRestorableStateWithCoder:(NSCoder *)coder
{
//    NSLog(@"Restoring...");
    [super decodeRestorableStateWithCoder:coder];

    // Clear any old stored info
    objc_setAssociatedObject(self, kCenterPointKey, nil, OBJC_ASSOCIATION_ASSIGN);
    objc_setAssociatedObject(self, kScaleKey, nil, OBJC_ASSOCIATION_ASSIGN);
    objc_setAssociatedObject(self, kRotationKey, nil, OBJC_ASSOCIATION_ASSIGN);

    if ([coder containsValueForKey:kEncoderCenterPointKey] &&
        [coder containsValueForKey:kEncoderRotationAngleKey] &&
        [coder containsValueForKey:kEncoderMapScaleKey])
    {
        @try {
//            NSLog(@"Trying Restore...");
            AGSPoint *centerPt = [[AGSPoint alloc] initWithJSON:[coder decodeObjectForKey:kEncoderCenterPointKey]];
            double scale = [coder decodeDoubleForKey:kEncoderMapScaleKey];
            double rotationAngle = [coder decodeDoubleForKey:kEncoderRotationAngleKey];
            
//            NSLog(@"Restoring scale %f angle %f around %@", scale, rotationAngle, centerPt);
            
            objc_setAssociatedObject(self, kCenterPointKey, centerPt, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            objc_setAssociatedObject(self, kScaleKey, [NSNumber numberWithDouble:scale], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            objc_setAssociatedObject(self, kRotationKey, [NSNumber numberWithDouble:rotationAngle], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
//            NSLog(@"Stored data for restore. hasRestorationInfo = %@", self.hasRestorationInfo?@"YES":@"NO");
        }
        @catch (NSException *exception) {
            NSLog(@"Could not retrieve stored info: %@", coder);
            NSLog(@"Exception raised: %@", exception);
        }
    }
}
@end